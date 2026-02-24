defmodule ControlcopypastaWeb.Admin.IngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient
  alias Controlcopypasta.Ingredients.Matching.{Matcher, IngredientScorer}

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Lists ingredients with admin-focused filters.

  Query params:
  - category: filter by category
  - animal_type: filter by animal_type
  - missing_animal_type: "true" to show only protein ingredients without animal_type
  - search: search by name
  """
  def index(conn, params) do
    filters = build_filters(params)
    ingredients = Ingredients.list_canonical_ingredients(filters)
    render(conn, :index, ingredients: ingredients)
  end

  @doc """
  Gets a single ingredient with all details including matching_rules.
  """
  def show(conn, %{"id" => id}) do
    case Ingredients.get_canonical_ingredient(id) do
      nil ->
        {:error, :not_found}

      ingredient ->
        render(conn, :show, ingredient: ingredient)
    end
  end

  @doc """
  Updates an ingredient's admin-editable fields.
  """
  def update(conn, %{"id" => id, "ingredient" => attrs}) do
    case Ingredients.get_canonical_ingredient(id) do
      nil ->
        {:error, :not_found}

      ingredient ->
        # Only allow updating certain fields via admin
        allowed_attrs =
          Map.take(attrs, [
            "animal_type",
            "category",
            "subcategory",
            "tags",
            "matching_rules",
            "similarity_name",
            "skip_nutrition"
          ])

        case Ingredients.update_canonical_ingredient(ingredient, allowed_attrs) do
          {:ok, updated} ->
            render(conn, :show, ingredient: updated)

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  @doc """
  Tests the ingredient scorer with an input string.

  Returns the top matching ingredients with their scores and scoring details.
  """
  def test_scorer(conn, %{"input" => input}) do
    # Build lookup with rules
    lookup = Ingredients.build_ingredient_lookup_with_rules()

    # Find the match using the matcher
    result = Matcher.match(input, lookup)

    # If we got a match, also show top alternatives by scoring
    alternatives =
      if result.canonical_id do
        # Get a few related ingredients to compare scores
        get_scoring_alternatives(input, lookup, result.canonical_id)
      else
        []
      end

    render(conn, :test_scorer,
      input: input,
      match: result,
      alternatives: alternatives
    )
  end

  # Get alternative matches for comparison
  defp get_scoring_alternatives(input, lookup, matched_id) do
    # Score all ingredients and find top alternatives
    lookup
    |> Enum.map(fn {_key, {canonical_name, id, rules}} ->
      # Get base confidence from match strategy
      base_score = get_base_score(input, canonical_name, lookup)

      # Apply scorer
      score_result = IngredientScorer.score(input, rules, base_score)

      %{
        canonical_name: canonical_name,
        canonical_id: id,
        score: score_result.score,
        matched: score_result.matched,
        details: score_result.details,
        has_rules: rules != nil
      }
    end)
    |> Enum.uniq_by(& &1.canonical_id)
    |> Enum.filter(fn alt -> alt.canonical_id != matched_id end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.take(5)
  end

  defp get_base_score(input, canonical_name, _lookup) do
    normalized_input = String.downcase(input)
    normalized_canonical = String.downcase(canonical_name)

    cond do
      normalized_input == normalized_canonical -> 1.0
      String.contains?(normalized_input, normalized_canonical) -> 0.9
      String.contains?(normalized_canonical, normalized_input) -> 0.85
      true -> 0.7
    end
  end

  @doc """
  Returns options for admin forms (valid categories, animal types, etc.)
  """
  def options(conn, _params) do
    render(conn, :options,
      categories: CanonicalIngredient.valid_categories(),
      animal_types: CanonicalIngredient.valid_animal_types()
    )
  end

  defp build_filters(params) do
    filters = []

    filters =
      if params["category"] && params["category"] != "" do
        [{:category, params["category"]} | filters]
      else
        filters
      end

    filters =
      if params["animal_type"] && params["animal_type"] != "" do
        [{:animal_type, params["animal_type"]} | filters]
      else
        filters
      end

    filters =
      if params["search"] && params["search"] != "" do
        [{:search, params["search"]} | filters]
      else
        filters
      end

    filters =
      if params["missing_animal_type"] == "true" do
        [{:missing_animal_type, true} | filters]
      else
        filters
      end

    # Default ordering
    [{:order_by, :name} | filters]
  end
end
