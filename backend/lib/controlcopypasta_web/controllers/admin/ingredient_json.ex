defmodule ControlcopypastaWeb.Admin.IngredientJSON do
  @doc """
  Renders a list of ingredients for admin.
  """
  def index(%{ingredients: ingredients}) do
    %{data: for(ingredient <- ingredients, do: data(ingredient))}
  end

  @doc """
  Renders a single ingredient.
  """
  def show(%{ingredient: ingredient}) do
    %{data: data(ingredient)}
  end

  @doc """
  Renders options for admin forms.
  """
  def options(%{categories: categories, animal_types: animal_types}) do
    %{
      categories: categories,
      animal_types: animal_types
    }
  end

  @doc """
  Renders test scorer results.
  """
  def test_scorer(%{input: input, match: match, alternatives: alternatives}) do
    %{
      data: %{
        input: input,
        match: %{
          name: match.name,
          canonical_name: match.canonical_name,
          canonical_id: match.canonical_id,
          confidence: match.confidence,
          scoring_details: Map.get(match, :scoring_details)
        },
        alternatives:
          Enum.map(alternatives, fn alt ->
            %{
              canonical_name: alt.canonical_name,
              canonical_id: alt.canonical_id,
              score: alt.score,
              matched: alt.matched,
              has_rules: alt.has_rules,
              details: alt.details
            }
          end)
      }
    }
  end

  defp data(ingredient) do
    %{
      id: ingredient.id,
      name: ingredient.name,
      display_name: ingredient.display_name,
      category: ingredient.category,
      subcategory: ingredient.subcategory,
      animal_type: ingredient.animal_type,
      tags: ingredient.tags || [],
      usage_count: ingredient.usage_count || 0,
      matching_rules: ingredient.matching_rules,
      aliases: ingredient.aliases || [],
      similarity_name: ingredient.similarity_name,
      skip_nutrition: ingredient.skip_nutrition || false
    }
  end
end
