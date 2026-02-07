defmodule Controlcopypasta.Scraper.ScrapeWorker do
  @moduledoc """
  Oban worker for processing URL scrape jobs.

  Fetches HTML from the URL, parses recipe data, creates a recipe
  owned by the domain account, and enqueues discovered links.
  """

  use Oban.Worker, queue: :scraper, max_attempts: 3

  require Logger

  alias Controlcopypasta.{Repo, Scraper, Recipes}
  alias Controlcopypasta.Accounts.User
  alias Controlcopypasta.Scraper.{ScrapeUrl, LinkExtractor}

  @impl Oban.Worker
  # Dispatcher mode: pick the next URL via round-robin and scrape it
  def perform(%Oban.Job{args: args}) when args == %{} or map_size(args) == 0 do
    case Scraper.next_url_round_robin() do
      {:ok, scrape_url} ->
        domain = scrape_url.domain

        if Scraper.rate_limit_exceeded?(domain) do
          Logger.info("Rate limit exceeded for #{domain}, snoozing dispatcher")
          {:snooze, 300}
        else
          do_scrape(scrape_url.url, scrape_url.id)
          schedule_next_dispatcher()
          :ok
        end

      {:empty, :all_rate_limited} ->
        Logger.info("All domains rate-limited, snoozing dispatcher for 5 minutes")
        {:snooze, 300}

      {:empty, :no_pending_urls} ->
        Logger.info("No pending URLs, dispatcher stopping")
        :ok
    end
  end

  # Legacy mode: backward compat for in-flight jobs with explicit URL
  def perform(%Oban.Job{args: %{"url" => url, "scrape_url_id" => scrape_url_id}}) do
    domain = extract_domain(url)

    if Scraper.rate_limit_exceeded?(domain) do
      Logger.info("Rate limit exceeded for #{domain}, snoozing job")
      {:snooze, 3600}
    else
      do_scrape(url, scrape_url_id)
    end
  end

  def perform(%Oban.Job{args: %{"url" => url}}) do
    Logger.warning("Scrape job missing scrape_url_id for URL: #{url}")
    {:error, "Missing scrape_url_id"}
  end

  defp do_scrape(url, scrape_url_id) do
    # Apply polite delay before fetching
    apply_polite_delay()

    with {:ok, scrape_url} <- get_scrape_url(scrape_url_id),
         {:ok, scrape_url} <- Scraper.mark_processing(scrape_url),
         {:ok, html} <- fetch_html(url) do
      # Always extract and enqueue links, even if page isn't a recipe
      enqueue_discovered_links(html, url, scrape_url.domain)

      # Try to parse as recipe
      case parse_and_save_recipe(html, url) do
        {:ok, recipe} ->
          Scraper.mark_completed(scrape_url, recipe.id)
          :ok

        {:error, "No recipe data found on page"} ->
          # Not a recipe page, but we still extracted links - mark as completed
          Scraper.mark_completed(scrape_url, nil)
          :ok

        {:error, reason} ->
          handle_failure(scrape_url_id, reason)
      end
    else
      {:error, :already_completed} ->
        Logger.info("URL already completed: #{url}")
        :ok

      {:error, :not_found} ->
        Logger.error("ScrapeUrl not found: #{scrape_url_id}")
        {:error, "ScrapeUrl not found"}

      {:error, reason} when is_binary(reason) ->
        handle_failure(scrape_url_id, reason)

      {:error, %Ecto.Changeset{} = changeset} ->
        error = format_changeset_error(changeset)
        handle_failure(scrape_url_id, error)

      error ->
        handle_failure(scrape_url_id, inspect(error))
    end
  end

  defp parse_and_save_recipe(html, url) do
    with {:ok, recipe_data} <- parse_recipe(html, url),
         {:ok, user} <- get_or_create_domain_user(recipe_data.source_domain),
         {:ok, recipe} <- create_recipe(recipe_data, user) do
      {:ok, recipe}
    end
  end

  defp get_scrape_url(scrape_url_id) do
    case Scraper.get_scrape_url(scrape_url_id) do
      nil ->
        {:error, :not_found}

      %ScrapeUrl{status: "completed"} ->
        {:error, :already_completed}

      scrape_url ->
        {:ok, scrape_url}
    end
  end

  defp fetch_html(url) do
    # Try Browser Pool first (for JS-heavy sites), fall back to simple HTTP
    if browser_pool_available?() do
      alias Controlcopypasta.Browser.Pool

      case Pool.fetch_html(url) do
        {:ok, html} -> {:ok, html}
        {:error, _} -> fetch_html_simple(url)
      end
    else
      fetch_html_simple(url)
    end
  end

  defp browser_pool_available? do
    # Check if Browser.Pool process is running
    case Process.whereis(Controlcopypasta.Browser.Pool) do
      nil -> false
      _pid -> true
    end
  end

  defp fetch_html_simple(url) do
    # Simple HTTP fetch using Req - works for sites with JSON-LD in static HTML
    case Req.get(url, follow_redirects: true, max_redirects: 5) do
      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        {:error, "Failed to fetch URL: #{inspect(reason)}"}
    end
  end

  defp parse_recipe(html, url) do
    alias Controlcopypasta.Parser.JsonLd

    # Try JSON-LD first
    case JsonLd.extract(html) do
      {:ok, recipe_data} ->
        {:ok, add_source_info(recipe_data, url)}

      {:error, _} ->
        # Fall back to scraper
        alias Controlcopypasta.Parser.Scraper, as: CustomScraper

        case CustomScraper.extract(html, url) do
          {:ok, recipe_data} ->
            {:ok, add_source_info(recipe_data, url)}

          {:error, _} ->
            {:error, "No recipe data found on page"}
        end
    end
  end

  defp add_source_info(recipe_data, url) do
    uri = URI.parse(url)
    domain = normalize_domain(uri.host)

    recipe_data
    |> Map.put(:source_url, url)
    |> Map.put(:source_domain, domain)
  end

  defp get_or_create_domain_user(domain) do
    # Normalize domain (remove www. prefix)
    normalized = domain |> String.replace(~r/^www\./, "")
    email = "recipes@#{normalized}"

    case Repo.get_by(User, email: email) do
      nil ->
        %User{}
        |> Ecto.Changeset.change(email: email)
        |> Repo.insert()

      user ->
        {:ok, user}
    end
  end

  defp create_recipe(recipe_data, user) do
    # Check if recipe already exists for this user/source_url
    case Recipes.get_recipe_by_source_url(user.id, recipe_data.source_url) do
      nil ->
        attrs = %{
          "title" => recipe_data[:title],
          "description" => recipe_data[:description],
          "source_url" => recipe_data[:source_url],
          "source_domain" => recipe_data[:source_domain],
          "image_url" => recipe_data[:image_url],
          "ingredients" => recipe_data[:ingredients] || [],
          "instructions" => recipe_data[:instructions] || [],
          "prep_time_minutes" => recipe_data[:prep_time_minutes],
          "cook_time_minutes" => recipe_data[:cook_time_minutes],
          "total_time_minutes" => recipe_data[:total_time_minutes],
          "servings" => recipe_data[:servings],
          "user_id" => user.id,
          # Nutrition from Schema.org JSON-LD
          "nutrition_serving_size" => recipe_data[:nutrition_serving_size],
          "nutrition_calories" => recipe_data[:nutrition_calories],
          "nutrition_protein_g" => recipe_data[:nutrition_protein_g],
          "nutrition_fat_g" => recipe_data[:nutrition_fat_g],
          "nutrition_saturated_fat_g" => recipe_data[:nutrition_saturated_fat_g],
          "nutrition_trans_fat_g" => recipe_data[:nutrition_trans_fat_g],
          "nutrition_carbohydrates_g" => recipe_data[:nutrition_carbohydrates_g],
          "nutrition_fiber_g" => recipe_data[:nutrition_fiber_g],
          "nutrition_sugar_g" => recipe_data[:nutrition_sugar_g],
          "nutrition_sodium_mg" => recipe_data[:nutrition_sodium_mg],
          "nutrition_cholesterol_mg" => recipe_data[:nutrition_cholesterol_mg]
        }

        Recipes.create_recipe(attrs)

      existing ->
        # Recipe already exists
        {:ok, existing}
    end
  end

  defp enqueue_discovered_links(html, source_url, domain) do
    links = LinkExtractor.extract_recipe_links(html, source_url)

    # Filter to same domain and not already queued
    links
    |> Enum.filter(fn link ->
      link_domain = URI.parse(link).host

      # Check domain matches (with or without www.)
      normalize_domain(link_domain) == normalize_domain(domain) &&
        !Scraper.url_queued?(link)
    end)
    |> Enum.take(50)
    |> Enum.each(fn link ->
      Scraper.enqueue_url(link, domain: domain)
    end)
  end

  defp normalize_domain(domain) when is_binary(domain) do
    domain
    |> String.downcase()
    |> String.replace(~r/^www\./, "")
  end

  defp normalize_domain(_), do: ""

  defp handle_failure(scrape_url_id, error) do
    Logger.error("Scrape failed for #{scrape_url_id}: #{error}")

    case Scraper.get_scrape_url(scrape_url_id) do
      nil -> :ok
      scrape_url -> Scraper.mark_failed(scrape_url, error)
    end

    {:error, error}
  end

  defp format_changeset_error(%Ecto.Changeset{errors: errors}) do
    errors
    |> Enum.map(fn {field, {msg, _opts}} -> "#{field}: #{msg}" end)
    |> Enum.join(", ")
  end

  defp apply_polite_delay do
    config = Application.get_env(:controlcopypasta, :scraping, [])
    min_delay = Keyword.get(config, :min_delay_ms, 3000)
    max_random = Keyword.get(config, :max_random_delay_ms, 5000)

    delay = min_delay + :rand.uniform(max_random)
    Process.sleep(delay)
  end

  defp schedule_next_dispatcher do
    %{}
    |> __MODULE__.new()
    |> Oban.insert()
  end

  defp extract_domain(url) do
    URI.parse(url).host || ""
  end
end
