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

      # Force reparse ALL recipes (regenerate pre_steps, alternatives, etc.)
      %{"force" => true}
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
  def perform(%Oban.Job{args: %{"recipe_id" => recipe_id} = args}) do
    force = Map.get(args, "force", false)

    case Repo.get(Recipe, recipe_id) do
      nil ->
        Logger.warning("Recipe not found: #{recipe_id}")
        :ok

      recipe ->
        parse_recipe_ingredients(recipe, force)
    end
  end

  def perform(%Oban.Job{args: %{"domain" => domain} = args}) do
    offset = Map.get(args, "offset", 0)
    force = Map.get(args, "force", false)
    parse_domain_batch(domain, offset, force)
  end

  def perform(%Oban.Job{args: args}) do
    offset = Map.get(args, "offset", 0)
    force = Map.get(args, "force", false)
    parse_all_batch(offset, force)
  end

  defp parse_recipe_ingredients(recipe, force \\ false) do
    ingredients = recipe.ingredients || []

    if force or needs_parsing?(ingredients) do
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

      # Use to_jsonb_map to get all fields including pre_steps, alternatives, recipe_reference
      Parser.to_jsonb_map(parsed)
      |> Map.put("group", ingredient["group"])  # Preserve group if it exists
    else
      ingredient
    end
  end

  defp parse_ingredient(ingredient) when is_binary(ingredient) do
    # Plain string ingredient
    parsed = Parser.parse(ingredient)
    Parser.to_jsonb_map(parsed)
  end

  defp parse_ingredient(ingredient), do: ingredient

  defp update_recipe_ingredients(recipe, ingredients) do
    recipe
    |> Ecto.Changeset.change(ingredients: ingredients, ingredients_parsed_at: DateTime.utc_now())
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

  defp parse_domain_batch(domain, offset, force) do
    recipes = if force do
      get_all_recipes_for_domain(domain, offset)
    else
      get_unparsed_recipes_for_domain(domain, offset)
    end

    count = length(recipes)

    Logger.info("Parsing batch of #{count} recipes for #{domain} (offset: #{offset}, force: #{force})")

    Enum.each(recipes, &parse_recipe_ingredients(&1, force))

    # Schedule next batch if there are more
    if count == @batch_size do
      %{"domain" => domain, "offset" => offset + @batch_size, "force" => force}
      |> __MODULE__.new(schedule_in: 5)
      |> Oban.insert()
    end

    :ok
  end

  defp parse_all_batch(offset, force) do
    recipes = if force do
      get_all_recipes(offset)
    else
      get_all_unparsed_recipes(offset)
    end

    count = length(recipes)

    Logger.info("Parsing batch of #{count} recipes (offset: #{offset}, force: #{force})")

    Enum.each(recipes, &parse_recipe_ingredients(&1, force))

    # Schedule next batch if there are more
    if count == @batch_size do
      %{"offset" => offset + @batch_size, "force" => force}
      |> __MODULE__.new(schedule_in: 5)
      |> Oban.insert()
    end

    :ok
  end

  defp get_all_recipes_for_domain(domain, offset) do
    Recipe
    |> where([r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
    |> order_by([r], r.inserted_at)
    |> offset(^offset)
    |> limit(@batch_size)
    |> Repo.all()
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

  defp get_all_recipes(offset) do
    Recipe
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
