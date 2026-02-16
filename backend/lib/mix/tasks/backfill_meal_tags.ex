defmodule Mix.Tasks.BackfillMealTags do
  @moduledoc """
  Backfills meal type tags on existing recipes using JSON-LD metadata.

  For recipes with stored source_json_ld, extracts tags locally (no network).
  For older recipes without stored JSON-LD, re-fetches from source_url.

  Usage:
    mix backfill_meal_tags EMAIL              # Tag all recipes for user
    mix backfill_meal_tags EMAIL --limit 5    # Process first 5 recipes
    mix backfill_meal_tags EMAIL --dry-run    # Show what would be tagged
  """
  use Mix.Task

  import Ecto.Query
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Parser.{JsonLd, MealTypeMapper}

  @shortdoc "Backfill meal type tags on existing recipes from JSON-LD metadata"

  @user_agent "ControlCopyPasta/1.0 (Recipe Parser)"

  def run(args) do
    Application.ensure_all_started(:controlcopypasta)

    {opts, rest, _} =
      OptionParser.parse(args,
        switches: [limit: :integer, dry_run: :boolean]
      )

    email = List.first(rest)

    unless email do
      Mix.shell().error("Usage: mix backfill_meal_tags EMAIL [--limit N] [--dry-run]")
      System.halt(1)
    end

    user =
      case Accounts.get_user_by_email(email) do
        nil ->
          Mix.shell().error("User not found: #{email}")
          System.halt(1)

        user ->
          user
      end

    Mix.shell().info("Backfilling meal tags for user: #{user.email}")

    query =
      Recipe
      |> where([r], r.user_id == ^user.id)
      |> where([r], is_nil(r.archived_at))
      |> order_by([r], asc: r.inserted_at)
      |> preload(:tags)

    query = if opts[:limit], do: limit(query, ^opts[:limit]), else: query
    all_recipes = Repo.all(query)

    Mix.shell().info("Found #{length(all_recipes)} recipes to process\n")

    if opts[:dry_run] do
      Mix.shell().info("DRY RUN - No tags will be applied\n")
    end

    results =
      all_recipes
      |> Enum.with_index(1)
      |> Enum.map(fn {recipe, idx} ->
        Mix.shell().info("[#{idx}/#{length(all_recipes)}] #{recipe.title}")
        process_recipe(recipe, opts)
      end)

    print_summary(results, opts[:dry_run])
  end

  defp process_recipe(recipe, opts) do
    case extract_tags(recipe) do
      {:ok, [], _source} ->
        Mix.shell().info("  ~ No meal type tags found")
        {:skipped, recipe.title, :no_tags_found}

      {:ok, suggested_tags, source} ->
        existing_tag_names = Enum.map(recipe.tags, & &1.name) |> MapSet.new()
        new_tags = Enum.reject(suggested_tags, &MapSet.member?(existing_tag_names, &1))

        if new_tags == [] do
          Mix.shell().info("  ~ No new tags (already has: #{Enum.join(suggested_tags, ", ")})")
          {:skipped, recipe.title, :already_tagged}
        else
          if opts[:dry_run] do
            Mix.shell().info("  ? Would add: #{Enum.join(new_tags, ", ")} (from #{source})")
            {:dry_run, recipe.title, new_tags}
          else
            apply_tags(recipe, new_tags, source)
          end
        end

      {:error, reason} ->
        Mix.shell().info("  x Failed: #{inspect(reason)}")
        {:error, recipe.title, reason}
    end
  end

  defp extract_tags(recipe) do
    cond do
      # Prefer stored JSON-LD (no network needed)
      recipe.source_json_ld && map_size(recipe.source_json_ld) > 0 ->
        extract_from_json_ld(recipe.source_json_ld, :stored)

      # Fall back to re-fetching from source URL
      recipe.source_url && recipe.source_url != "" ->
        extract_from_url(recipe.source_url)

      true ->
        {:ok, [], :none}
    end
  end

  defp extract_from_json_ld(json_ld, source) do
    categories = get_string_or_list(json_ld, "recipeCategory")
    keywords = get_string_or_list(json_ld, "keywords")
    tags = MealTypeMapper.suggest_meal_tags(categories, keywords)
    {:ok, tags, source}
  end

  defp extract_from_url(url) do
    # Delay to be polite to servers
    Process.sleep(1_000)

    case Req.get(url, headers: [{"user-agent", @user_agent}], max_redirects: 5) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        case JsonLd.extract(body) do
          {:ok, _normalized, raw_json_ld} ->
            extract_from_json_ld(raw_json_ld, :refetched)

          {:error, reason} ->
            {:error, reason}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, "Fetch failed: #{inspect(exception)}"}
    end
  end

  # Duplicated from JsonLd since it's private there - handles JSON-LD string/list values
  defp get_string_or_list(map, key) do
    case Map.get(map, key) do
      nil ->
        []

      value when is_binary(value) ->
        value |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

      values when is_list(values) ->
        values
        |> Enum.flat_map(fn
          v when is_binary(v) ->
            v |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

          _ ->
            []
        end)

      _ ->
        []
    end
  end

  defp apply_tags(recipe, new_tags, source) do
    new_tag_records =
      Enum.reduce(new_tags, [], fn name, acc ->
        case Recipes.get_or_create_tag(name) do
          {:ok, tag} -> [tag | acc]
          _ -> acc
        end
      end)

    all_tags = Enum.uniq_by(recipe.tags ++ new_tag_records, & &1.id)

    case recipe
         |> Ecto.Changeset.change()
         |> Ecto.Changeset.put_assoc(:tags, all_tags)
         |> Repo.update() do
      {:ok, _} ->
        tag_names = Enum.map(new_tag_records, & &1.name) |> Enum.join(", ")
        Mix.shell().info("  + Added: #{tag_names} (from #{source})")
        {:tagged, recipe.title, new_tags}

      {:error, changeset} ->
        Mix.shell().info("  x Failed to save: #{inspect(changeset.errors)}")
        {:error, recipe.title, changeset.errors}
    end
  end

  defp print_summary(results, dry_run) do
    tagged = Enum.count(results, &match?({:tagged, _, _}, &1))
    skipped = Enum.count(results, &match?({:skipped, _, _}, &1))
    failed = Enum.count(results, &match?({:error, _, _}, &1))
    dry_run_count = Enum.count(results, &match?({:dry_run, _, _}, &1))

    Mix.shell().info("\n" <> String.duplicate("=", 50))
    Mix.shell().info("Backfill Summary")
    Mix.shell().info(String.duplicate("=", 50))

    if dry_run do
      Mix.shell().info("Would tag: #{dry_run_count}")
      Mix.shell().info("Skipped:   #{skipped}")
      Mix.shell().info("Failed:    #{failed}")
    else
      Mix.shell().info("Tagged:    #{tagged}")
      Mix.shell().info("Skipped:   #{skipped}")
      Mix.shell().info("Failed:    #{failed}")
    end

    if failed > 0 do
      Mix.shell().info("\nFailed recipes:")

      for {:error, title, reason} <- results do
        Mix.shell().info("  - #{title}: #{inspect(reason)}")
      end
    end
  end
end
