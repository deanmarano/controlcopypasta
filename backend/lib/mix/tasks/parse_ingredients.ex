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

    {opts, _, _} = OptionParser.parse(args, strict: [limit: :integer, dry_run: :boolean])
    limit = Keyword.get(opts, :limit)
    dry_run = Keyword.get(opts, :dry_run, false)

    # Build lookup once (expensive)
    IO.puts("Building ingredient lookup...")
    lookup = Ingredients.build_ingredient_lookup()

    # Find recipes with unparsed ingredients
    query =
      from r in Recipe,
        where:
          fragment(
            "jsonb_array_length(?) > 0 AND EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem WHERE elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = '')",
            r.ingredients,
            r.ingredients
          ),
        select: [:id, :ingredients, :ingredients_parsed_at]

    query = if limit, do: Ecto.Query.limit(query, ^limit), else: query

    recipes = Repo.all(query)
    total = length(recipes)

    IO.puts(
      "Found #{total} recipes with unparsed ingredients#{if limit, do: " (limited to #{limit})", else: ""}"
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
