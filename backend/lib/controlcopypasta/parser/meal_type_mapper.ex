defmodule Controlcopypasta.Parser.MealTypeMapper do
  @moduledoc """
  Maps recipe category and keyword terms from JSON-LD metadata
  to normalized meal type tag names.
  """

  @tag_mappings %{
    "breakfast" => ["breakfast", "brunch"],
    "lunch" => ["lunch"],
    "dinner" => ["dinner", "main course", "main dish", "entree", "entrée", "supper"],
    "dessert" => ["dessert", "sweets", "baking", "cake", "cookies", "pie", "pastry"],
    "snack" => ["snack", "snacks"],
    "appetizer" => ["appetizer", "starter", "hors d'oeuvre", "finger food", "appetizers"],
    "side dish" => ["side dish", "side", "accompaniment"],
    "beverage" => ["beverage", "drink", "cocktail", "smoothie", "juice"],
    "soup" => ["soup", "stew", "chili", "chowder", "bisque"],
    "salad" => ["salad"],
    "bread" => ["bread", "muffin", "roll", "muffins", "rolls"],
    "sauce" => ["sauce", "condiment", "dressing", "dip", "marinade"]
  }

  # Build a reverse lookup: lowercased term -> tag name
  @reverse_lookup (for {tag, terms} <- @tag_mappings, term <- terms, into: %{} do
                     {term, tag}
                   end)

  @doc """
  Given lists of category and keyword terms from JSON-LD,
  returns a sorted list of matching tag names.

  ## Examples

      iex> suggest_meal_tags(["Main Course", "Italian"], ["easy weeknight"])
      ["dinner"]

      iex> suggest_meal_tags(["Dessert"], ["cookies", "baking"])
      ["dessert"]
  """
  def suggest_meal_tags(categories, keywords) do
    all_terms = List.wrap(categories) ++ List.wrap(keywords)

    all_terms
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&String.trim/1)
    |> Enum.flat_map(fn term ->
      case Map.get(@reverse_lookup, term) do
        nil -> []
        tag -> [tag]
      end
    end)
    |> Enum.uniq()
    |> Enum.sort()
  end
end
