defmodule Controlcopypasta.Similarity do
  @moduledoc """
  Calculates similarity between recipes based on their ingredients.

  Uses a weighted combination of:
  1. Ingredient overlap (Jaccard similarity on canonical ingredient names)
  2. Proportion similarity (cosine similarity on ingredient proportions)

  The final score is: 0.6 * overlap + 0.4 * proportion_similarity
  """

  alias Controlcopypasta.Similarity.{IngredientParser, IngredientNormalizer}
  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Recipe

  @overlap_weight 0.6
  @proportion_weight 0.4

  @type ingredient_vector :: %{String.t() => float()}
  @type similarity_result :: %{
          recipe: Recipe.t(),
          score: float(),
          overlap_score: float(),
          proportion_score: float(),
          shared_ingredients: [String.t()],
          unique_to_other: [String.t()]
        }

  @doc """
  Finds similar recipes for a given recipe.

  Options:
  - :limit - Maximum number of similar recipes to return (default: 5)
  - :min_score - Minimum similarity score threshold (default: 0.1)
  - :user_id - If provided, only search within this user's recipes
  """
  @spec find_similar(Recipe.t(), keyword()) :: [similarity_result()]
  def find_similar(%Recipe{} = recipe, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)
    min_score = Keyword.get(opts, :min_score, 0.1)
    user_id = Keyword.get(opts, :user_id)

    # Get the recipe's ingredient vector
    recipe_vector = build_ingredient_vector(recipe)
    recipe_ingredients = MapSet.new(Map.keys(recipe_vector))

    # Get candidate recipes
    candidates = get_candidate_recipes(recipe, user_id)

    # Calculate similarity for each candidate
    candidates
    |> Enum.map(fn candidate ->
      calculate_similarity(recipe, recipe_vector, recipe_ingredients, candidate)
    end)
    |> Enum.filter(fn result -> result.score >= min_score end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(limit)
  end

  @doc """
  Compares two recipes and returns detailed similarity information.
  Useful for the side-by-side diff view.
  """
  @spec compare(Recipe.t(), Recipe.t()) :: %{
          score: float(),
          overlap_score: float(),
          proportion_score: float(),
          shared_ingredients: [{String.t(), {float(), float()}}],
          only_in_first: [{String.t(), float()}],
          only_in_second: [{String.t(), float()}],
          first_vector: ingredient_vector(),
          second_vector: ingredient_vector()
        }
  def compare(%Recipe{} = recipe1, %Recipe{} = recipe2) do
    vector1 = build_ingredient_vector(recipe1)
    vector2 = build_ingredient_vector(recipe2)

    keys1 = MapSet.new(Map.keys(vector1))
    keys2 = MapSet.new(Map.keys(vector2))

    shared_keys = MapSet.intersection(keys1, keys2)
    only_in_first = MapSet.difference(keys1, keys2)
    only_in_second = MapSet.difference(keys2, keys1)

    overlap_score = jaccard_similarity(keys1, keys2)
    proportion_score = cosine_similarity(vector1, vector2)
    combined_score = @overlap_weight * overlap_score + @proportion_weight * proportion_score

    %{
      score: Float.round(combined_score, 3),
      overlap_score: Float.round(overlap_score, 3),
      proportion_score: Float.round(proportion_score, 3),
      shared_ingredients:
        shared_keys
        |> MapSet.to_list()
        |> Enum.map(fn key -> {key, {Map.get(vector1, key), Map.get(vector2, key)}} end)
        |> Enum.sort_by(fn {_, {p1, p2}} -> -(p1 + p2) / 2 end),
      only_in_first:
        only_in_first
        |> MapSet.to_list()
        |> Enum.map(fn key -> {key, Map.get(vector1, key)} end)
        |> Enum.sort_by(fn {_, p} -> -p end),
      only_in_second:
        only_in_second
        |> MapSet.to_list()
        |> Enum.map(fn key -> {key, Map.get(vector2, key)} end)
        |> Enum.sort_by(fn {_, p} -> -p end),
      first_vector: vector1,
      second_vector: vector2
    }
  end

  @doc """
  Builds an ingredient vector for a recipe.
  Keys are canonical ingredient names, values are relative proportions (summing to 1.0).
  """
  @spec build_ingredient_vector(Recipe.t()) :: ingredient_vector()
  def build_ingredient_vector(%Recipe{ingredients: ingredients}) when is_list(ingredients) do
    parsed =
      ingredients
      |> Enum.map(&IngredientParser.parse_ingredient_map/1)
      |> Enum.filter(fn %{name: name} -> name != "" end)

    # Normalize ingredient names and aggregate quantities
    aggregated =
      Enum.reduce(parsed, %{}, fn %{quantity: qty, name: name}, acc ->
        canonical = IngredientNormalizer.normalize(name)
        # Use quantity if available, otherwise count as 1
        quantity = qty || 1.0
        Map.update(acc, canonical, quantity, &(&1 + quantity))
      end)

    # Convert to proportions (relative to total)
    total = Enum.sum(Map.values(aggregated))

    if total > 0 do
      Map.new(aggregated, fn {k, v} -> {k, Float.round(v / total, 4)} end)
    else
      %{}
    end
  end

  def build_ingredient_vector(_), do: %{}

  # Private functions

  defp get_candidate_recipes(%Recipe{id: recipe_id}, user_id) when is_binary(user_id) do
    Recipes.list_recipes_for_user(user_id, %{"limit" => "1000"})
    |> Enum.filter(fn r -> r.id != recipe_id end)
  end

  defp get_candidate_recipes(%Recipe{id: recipe_id, user_id: user_id}, _) when is_binary(user_id) do
    Recipes.list_recipes_for_user(user_id, %{"limit" => "1000"})
    |> Enum.filter(fn r -> r.id != recipe_id end)
  end

  defp get_candidate_recipes(%Recipe{id: recipe_id}, _) do
    Recipes.list_recipes(%{"limit" => "1000"})
    |> Enum.filter(fn r -> r.id != recipe_id end)
  end

  defp calculate_similarity(
         _source_recipe,
         source_vector,
         source_ingredients,
         %Recipe{} = candidate
       ) do
    candidate_vector = build_ingredient_vector(candidate)
    candidate_ingredients = MapSet.new(Map.keys(candidate_vector))

    overlap_score = jaccard_similarity(source_ingredients, candidate_ingredients)
    proportion_score = cosine_similarity(source_vector, candidate_vector)
    combined_score = @overlap_weight * overlap_score + @proportion_weight * proportion_score

    shared = MapSet.intersection(source_ingredients, candidate_ingredients) |> MapSet.to_list()
    unique_to_candidate = MapSet.difference(candidate_ingredients, source_ingredients) |> MapSet.to_list()

    %{
      recipe: candidate,
      score: Float.round(combined_score, 3),
      overlap_score: Float.round(overlap_score, 3),
      proportion_score: Float.round(proportion_score, 3),
      shared_ingredients: shared,
      unique_to_other: unique_to_candidate
    }
  end

  @doc """
  Calculates Jaccard similarity between two sets.
  Returns a value between 0.0 and 1.0.
  """
  @spec jaccard_similarity(MapSet.t(), MapSet.t()) :: float()
  def jaccard_similarity(set1, set2) do
    intersection_size = MapSet.intersection(set1, set2) |> MapSet.size()
    union_size = MapSet.union(set1, set2) |> MapSet.size()

    if union_size == 0, do: 0.0, else: intersection_size / union_size
  end

  @doc """
  Calculates cosine similarity between two vectors (represented as maps).
  Returns a value between 0.0 and 1.0.
  """
  @spec cosine_similarity(ingredient_vector(), ingredient_vector()) :: float()
  def cosine_similarity(vec1, vec2) do
    # Get all keys
    all_keys = MapSet.union(MapSet.new(Map.keys(vec1)), MapSet.new(Map.keys(vec2)))

    # Calculate dot product
    dot_product =
      Enum.reduce(all_keys, 0.0, fn key, acc ->
        v1 = Map.get(vec1, key, 0.0)
        v2 = Map.get(vec2, key, 0.0)
        acc + v1 * v2
      end)

    # Calculate magnitudes
    mag1 = :math.sqrt(Enum.sum(Enum.map(Map.values(vec1), fn v -> v * v end)))
    mag2 = :math.sqrt(Enum.sum(Enum.map(Map.values(vec2), fn v -> v * v end)))

    if mag1 == 0 or mag2 == 0 do
      0.0
    else
      dot_product / (mag1 * mag2)
    end
  end
end
