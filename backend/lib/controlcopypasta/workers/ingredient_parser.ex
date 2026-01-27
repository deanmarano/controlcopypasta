defmodule Controlcopypasta.Workers.IngredientParser do
  @moduledoc """
  Oban worker that parses ingredients in recipes and matches them to canonical ingredients.

  This is needed for scraped recipes that only have raw ingredient strings without
  canonical_id - the avoided ingredients filter requires canonical_id to work.

  ## Manual execution

      # Parse a single recipe
      %{"recipe_id" => "uuid-here"}
      |> Controlcopypasta.Workers.IngredientParser.new()
      |> Oban.insert()

      # Parse all recipes for a domain (in batches)
      %{"domain" => "cooking.nytimes.com"}
      |> Controlcopypasta.Workers.IngredientParser.new()
      |> Oban.insert()

      # Parse all unparsed recipes (in batches)
      %{}
      |> Controlcopypasta.Workers.IngredientParser.new()
      |> Oban.insert()
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 3

  require Logger

  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Ingredients.Parser

  @batch_size 50

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"recipe_id" => recipe_id}}) do
    case Repo.get(Recipe, recipe_id) do
      nil ->
        Logger.warning("Recipe not found: #{recipe_id}")
        :ok

      recipe ->
        parse_recipe_ingredients(recipe)
    end
  end

  def perform(%Oban.Job{args: %{"domain" => domain} = args}) do
    offset = Map.get(args, "offset", 0)
    parse_domain_batch(domain, offset)
  end

  def perform(%Oban.Job{args: args}) do
    offset = Map.get(args, "offset", 0)
    parse_all_batch(offset)
  end

  defp parse_recipe_ingredients(recipe) do
    ingredients = recipe.ingredients || []

    if needs_parsing?(ingredients) do
      parsed_ingredients = Enum.map(ingredients, &parse_ingredient/1)
      update_recipe_ingredients(recipe, parsed_ingredients)
    else
      Logger.debug("Recipe #{recipe.id} already has parsed ingredients")
      :ok
    end
  end

  defp needs_parsing?(ingredients) do
    Enum.any?(ingredients, fn ing ->
      # Check if ingredient is missing canonical_id or has low confidence
      is_map(ing) and (
        is_nil(ing["canonical_id"]) or
        ing["canonical_id"] == "" or
        (is_nil(ing["confidence"]) and is_nil(ing["canonical_name"]))
      )
    end)
  end

  defp parse_ingredient(ingredient) when is_map(ingredient) do
    # Get the original text - could be in "text", "original", or just be the raw string
    text = ingredient["text"] || ingredient["original"] || ingredient["raw_name"]

    if is_binary(text) and text != "" do
      parsed = Parser.parse(text)

      # Merge parsed data with original, preserving any existing fields
      ingredient
      |> Map.put("canonical_name", parsed.canonical_name)
      |> Map.put("canonical_id", parsed.canonical_id)
      |> Map.put("confidence", parsed.confidence)
      |> Map.put("quantity", %{
        "value" => parsed.quantity,
        "min" => parsed.quantity_min,
        "max" => parsed.quantity_max,
        "unit" => parsed.unit
      })
      |> Map.put("preparations", parsed.preparations)
      |> Map.put("form", parsed.form)
      |> maybe_put("original", text)
    else
      ingredient
    end
  end

  defp parse_ingredient(ingredient) when is_binary(ingredient) do
    # Plain string ingredient
    parsed = Parser.parse(ingredient)
    Parser.to_jsonb_map(parsed)
    |> Map.put("original", ingredient)
  end

  defp parse_ingredient(ingredient), do: ingredient

  defp maybe_put(map, key, value) do
    if Map.has_key?(map, key), do: map, else: Map.put(map, key, value)
  end

  defp update_recipe_ingredients(recipe, ingredients) do
    recipe
    |> Ecto.Changeset.change(ingredients: ingredients)
    |> Repo.update()
    |> case do
      {:ok, _} ->
        Logger.info("Parsed ingredients for recipe: #{recipe.id}")
        :ok

      {:error, changeset} ->
        Logger.error("Failed to update recipe #{recipe.id}: #{inspect(changeset.errors)}")
        {:error, "Failed to update recipe"}
    end
  end

  defp parse_domain_batch(domain, offset) do
    recipes = get_unparsed_recipes_for_domain(domain, offset)
    count = length(recipes)

    Logger.info("Parsing batch of #{count} recipes for #{domain} (offset: #{offset})")

    Enum.each(recipes, &parse_recipe_ingredients/1)

    # Schedule next batch if there are more
    if count == @batch_size do
      %{"domain" => domain, "offset" => offset + @batch_size}
      |> __MODULE__.new(schedule_in: 5)
      |> Oban.insert()
    end

    :ok
  end

  defp parse_all_batch(offset) do
    recipes = get_all_unparsed_recipes(offset)
    count = length(recipes)

    Logger.info("Parsing batch of #{count} recipes (offset: #{offset})")

    Enum.each(recipes, &parse_recipe_ingredients/1)

    # Schedule next batch if there are more
    if count == @batch_size do
      %{"offset" => offset + @batch_size}
      |> __MODULE__.new(schedule_in: 5)
      |> Oban.insert()
    end

    :ok
  end

  defp get_unparsed_recipes_for_domain(domain, offset) do
    Recipe
    |> where([r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
    |> where([r], fragment("EXISTS (
        SELECT 1 FROM jsonb_array_elements(?) AS elem
        WHERE elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = ''
      )", r.ingredients))
    |> order_by([r], r.inserted_at)
    |> offset(^offset)
    |> limit(@batch_size)
    |> Repo.all()
  end

  defp get_all_unparsed_recipes(offset) do
    Recipe
    |> where([r], fragment("EXISTS (
        SELECT 1 FROM jsonb_array_elements(?) AS elem
        WHERE elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = ''
      )", r.ingredients))
    |> order_by([r], r.inserted_at)
    |> offset(^offset)
    |> limit(@batch_size)
    |> Repo.all()
  end
end
