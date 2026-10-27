defmodule Mix.Tasks.ParseIngredients do
  @moduledoc """
  Parses all unparsed recipe ingredients using TokenParser.

  Iterates over recipes that have at least one ingredient without a canonical_id,
  runs TokenParser.parse() on each ingredient text, and updates the recipe's
  ingredients JSONB with the parsed data.

  ## Usage

      mix parse_ingredients           # Parse all unparsed recipes
      mix parse_ingredients --limit 100  # Parse up to 100 recipes
      mix parse_ingredients --dry-run    # Show what would be parsed without saving

  ## Re-parsing already-parsed recipes

  By default this task only visits recipes that still have an ingredient without
  a `canonical_id`. That skips recipes parsed by an older version of the parser
  which forced a low-confidence match onto every line instead of leaving nulls —
  those recipes look fully parsed but hold stale, often wrong, matches.

      # Re-parse everything parsed before a given date
      mix parse_ingredients --parsed-before 2026-03-01

      # Re-parse every recipe, regardless of current parse state
      mix parse_ingredients --force

  Re-parsing is idempotent: it rewrites the ingredients JSONB from the current
  parser and refreshes `ingredients_parsed_at`. Start with `--dry-run --limit`.
  """
  use Mix.Task

  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.TokenParser

  @shortdoc "Parse unparsed recipe ingredients"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          limit: :integer,
          dry_run: :boolean,
          force: :boolean,
          parsed_before: :string
        ]
      )

    limit = Keyword.get(opts, :limit)
    dry_run = Keyword.get(opts, :dry_run, false)
    force = Keyword.get(opts, :force, false)
    parsed_before = parse_date_opt(Keyword.get(opts, :parsed_before))

    # Build lookup once (expensive)
    IO.puts("Building ingredient lookup...")
    lookup = Ingredients.build_ingredient_lookup()

    query = build_query(force, parsed_before)
    query = if limit, do: Ecto.Query.limit(query, ^limit), else: query

    recipes = Repo.all(query)
    total = length(recipes)

    IO.puts(
      "Found #{total} #{describe_selection(force, parsed_before)}#{if limit, do: " (limited to #{limit})", else: ""}"
    )

    if dry_run do
      IO.puts("Dry run - no changes will be saved")
    end

    {success, failed} =
      recipes
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0}, fn {recipe, index}, {s, f} ->
        if rem(index, 500) == 0 or index == total do
          IO.puts("Progress: #{index}/#{total} (#{s} ok, #{f} failed)")
        end

        case parse_recipe_ingredients(recipe, lookup, dry_run) do
          :ok -> {s + 1, f}
          :error -> {s, f + 1}
        end
      end)

    IO.puts("\nDone! #{success} parsed, #{failed} failed")
  end

  # Recipes with at least one ingredient lacking a canonical_id (the default).
  defp build_query(false, nil) do
    from r in Recipe,
      where:
        fragment(
          "jsonb_array_length(?) > 0 AND EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem WHERE elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = '')",
          r.ingredients,
          r.ingredients
        ),
      select: [:id, :ingredients, :ingredients_parsed_at]
  end

  # Every recipe that has ingredients, whatever its current parse state.
  defp build_query(true, nil) do
    from r in Recipe,
      where: fragment("jsonb_array_length(?) > 0", r.ingredients),
      select: [:id, :ingredients, :ingredients_parsed_at]
  end

  # Recipes last parsed before a cutoff, including ones that look fully parsed.
  defp build_query(_force, %DateTime{} = cutoff) do
    from r in Recipe,
      where:
        fragment("jsonb_array_length(?) > 0", r.ingredients) and
          (is_nil(r.ingredients_parsed_at) or r.ingredients_parsed_at < ^cutoff),
      select: [:id, :ingredients, :ingredients_parsed_at]
  end

  defp describe_selection(_force, %DateTime{} = cutoff),
    do: "recipes parsed before #{DateTime.to_date(cutoff)} (or never parsed)"

  defp describe_selection(true, nil), do: "recipes with ingredients (full re-parse)"
  defp describe_selection(false, nil), do: "recipes with unparsed ingredients"

  defp parse_date_opt(nil), do: nil

  defp parse_date_opt(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} ->
        dt

      {:error, _} ->
        case Date.from_iso8601(value) do
          {:ok, date} ->
            DateTime.new!(date, ~T[00:00:00], "Etc/UTC")

          {:error, _} ->
            Mix.raise("--parsed-before expects an ISO8601 date, e.g. 2026-03-01, got: #{value}")
        end
    end
  end

  defp parse_recipe_ingredients(recipe, lookup, dry_run) do
    try do
      parsed_ingredients =
        Enum.map(recipe.ingredients, fn ingredient ->
          text = ingredient["text"]

          if is_nil(text) or text == "" do
            ingredient
          else
            parsed = TokenParser.parse(text, lookup: lookup)
            jsonb = TokenParser.to_jsonb_map(parsed)

            # Preserve the group field from the original ingredient
            group = ingredient["group"]
            if group, do: Map.put(jsonb, "group", group), else: jsonb
          end
        end)

      if dry_run do
        :ok
      else
        canonical_ids =
          parsed_ingredients
          |> Enum.map(& &1["canonical_id"])
          |> Enum.reject(&is_nil/1)
          |> Enum.reject(&(&1 == ""))
          |> Enum.uniq()

        all_parsed =
          length(parsed_ingredients) > 0 and
            Enum.all?(parsed_ingredients, fn ing ->
              (ing["canonical_id"] != nil and ing["canonical_id"] != "") or
                ing["skipped"] == true
            end)

        recipe
        |> Ecto.Changeset.change(%{
          ingredients: parsed_ingredients,
          ingredients_parsed_at: DateTime.utc_now() |> DateTime.truncate(:second),
          ingredient_canonical_ids: canonical_ids,
          all_ingredients_parsed: all_parsed
        })
        |> Repo.update()
        |> case do
          {:ok, _} -> :ok
          {:error, _} -> :error
        end
      end
    rescue
      e ->
        IO.puts("  Error parsing recipe #{recipe.id}: #{inspect(e)}")
        :error
    end
  end
end
