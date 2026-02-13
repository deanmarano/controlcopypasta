defmodule Controlcopypasta.Parser do
  @moduledoc """
  Recipe parser that extracts structured recipe data from URLs.

  Uses a hybrid approach:
  1. First tries JSON-LD (Schema.org Recipe format)
  2. Falls back to custom scrapers for specific sites
  3. Uses browser fetching for sites with bot detection (e.g., Food Network)

  To add support for a new site, create a scraper module implementing
  the Controlcopypasta.Parser.Scraper behaviour and register it.
  """

  alias Controlcopypasta.Parser.{JsonLd, Scraper}

  @user_agent "ControlCopyPasta/1.0 (Recipe Parser)"

  def parse_url(url) when is_binary(url) do
    with {:ok, html} <- fetch_html(url),
         {:ok, recipe_data} <- extract_recipe(html, url) do
      {:ok, recipe_data}
    end
  end

  defp fetch_html(url) do
    case Req.get(url, headers: [{"user-agent", @user_agent}], max_redirects: 5) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, "Failed to fetch URL: #{inspect(exception)}"}
    end
  end

  defp extract_recipe(html, url) do
    # Try JSON-LD first (preferred method)
    case JsonLd.extract(html) do
      {:ok, recipe_data} ->
        {:ok, add_source_info(recipe_data, url)}

      {:error, _} ->
        # Fall back to custom scrapers
        case Scraper.extract(html, url) do
          {:ok, recipe_data} ->
            {:ok, add_source_info(recipe_data, url)}

          {:error, _} ->
            {:error, "No recipe data found on page"}
        end
    end
  end

  defp add_source_info(recipe_data, url) do
    uri = URI.parse(url)

    recipe_data
    |> Map.put(:source_url, url)
    |> Map.put(:source_domain, uri.host)
  end
end
