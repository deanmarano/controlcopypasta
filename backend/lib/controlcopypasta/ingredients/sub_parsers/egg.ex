defmodule Controlcopypasta.Ingredients.SubParsers.Egg do
  @moduledoc """
  Sub-parser for egg patterns that the standard parser mishandles.

  Intercepts patterns like:
  - "1 large egg, beaten with 1 tbsp milk" — ing=egg, preps=[beaten]
  - "6 eggs, yolks and whites separated" — ing=egg, preps=[separated]
  - "1 egg plus 1 yolk" — ing=[egg, egg yolk] with separate quantities
  - "8 large eggs, hard-boiled and peeled" — ing=egg, preps=[hard-boiled, peeled]

  Does NOT intercept simple patterns ("4 eggs", "2 egg whites") that
  the standard parser handles correctly.
  """

  @behaviour Controlcopypasta.Ingredients.SubParsers.SubParser

  alias Controlcopypasta.Ingredients.TokenParser
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  @egg_words ~w(egg eggs)
  @yolk_words ~w(yolk yolks)
  @white_words ~w(white whites)

  @impl true
  def match?(tokens) do
    texts = Enum.map(tokens, &String.downcase(&1.text))
    has_egg = Enum.any?(texts, &(&1 in @egg_words))

    has_egg and has_problem_indicator?(texts)
  end

  defp has_problem_indicator?(texts) do
    has_beaten_with = "beaten" in texts and "with" in texts
    has_separated = "separated" in texts and
      (Enum.any?(texts, &(&1 in @yolk_words)) or Enum.any?(texts, &(&1 in @white_words)))
    has_plus_part = "plus" in texts and
      (Enum.any?(texts, &(&1 in @yolk_words)) or Enum.any?(texts, &(&1 in @white_words)))
    has_hard_boiled = "hard-boiled" in texts

    has_beaten_with or has_separated or has_plus_part or has_hard_boiled
  end

  @impl true
  def parse(tokens, original, lookup) do
    texts = Enum.map(tokens, &String.downcase(&1.text))

    cond do
      # "1 egg plus 1 yolk" — compound, produces two ingredients
      "plus" in texts and Enum.any?(texts, &(&1 in @yolk_words ++ @white_words)) ->
        parse_plus_pattern(tokens, original, lookup)

      # "beaten with" — truncate at "beaten with", rest becomes note
      "beaten" in texts and "with" in texts ->
        parse_beaten_with(tokens, original, lookup)

      # "yolks and whites separated" — ingredient is egg, prep is separated
      "separated" in texts ->
        parse_separated(tokens, original, lookup)

      # "hard-boiled and peeled" — compound prep
      "hard-boiled" in texts ->
        parse_hard_boiled(tokens, original, lookup)

      true ->
        :skip
    end
  end

  # --- "beaten with" pattern ---
  # "1 large egg, beaten with 1 tbsp milk"
  # → ing=egg, preps=[beaten]
  defp parse_beaten_with(tokens, original, lookup) do
    # Find egg quantity (before egg token)
    egg_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @egg_words))
    qty_tokens = tokens |> Enum.take(egg_idx || 0) |> Enum.filter(&(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    matched = TokenParser.match_ingredient("egg", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: nil,
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: ["beaten"],
       modifiers: extract_modifiers(tokens, egg_idx),
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  # --- "separated" pattern ---
  # "6 eggs, yolks and whites separated"
  # → ing=egg, preps=[separated]
  defp parse_separated(tokens, original, lookup) do
    egg_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @egg_words))
    qty_tokens = tokens |> Enum.take(egg_idx || 0) |> Enum.filter(&(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    matched = TokenParser.match_ingredient("egg", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: nil,
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: ["separated"],
       modifiers: extract_modifiers(tokens, egg_idx),
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  # --- "plus yolk/white" pattern ---
  # "1 egg plus 1 yolk" → two ingredients: [egg, egg yolk]
  defp parse_plus_pattern(tokens, original, lookup) do
    texts = Enum.map(tokens, &String.downcase(&1.text))
    plus_idx = Enum.find_index(texts, &(&1 == "plus"))

    # Before "plus": extract egg quantity
    before_plus = Enum.take(tokens, plus_idx)
    egg_qty_tokens = Enum.filter(before_plus, &(&1.label == :qty))
    {egg_qty, egg_min, egg_max} = TokenParser.parse_quantity(Enum.map(egg_qty_tokens, & &1.text))

    # After "plus": extract part quantity and type
    after_plus = Enum.drop(tokens, plus_idx + 1)
    part_qty_tokens = Enum.filter(after_plus, &(&1.label == :qty))
    {part_qty, _part_min, _part_max} = TokenParser.parse_quantity(Enum.map(part_qty_tokens, & &1.text))

    after_texts = Enum.map(after_plus, &String.downcase(&1.text))
    part_name = cond do
      Enum.any?(after_texts, &(&1 in @yolk_words)) -> "egg yolk"
      Enum.any?(after_texts, &(&1 in @white_words)) -> "egg white"
      true -> "egg"
    end

    matched_egg = TokenParser.match_ingredient("egg", lookup)
    matched_part = TokenParser.match_ingredient(part_name, lookup)

    # Use the egg quantity as primary; note captures compound nature
    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: if(egg_qty, do: (egg_qty || 0) + (part_qty || 0), else: part_qty),
       quantity_min: egg_min,
       quantity_max: egg_max,
       unit: nil,
       container: nil,
       ingredients: [matched_egg, matched_part],
       primary_ingredient: matched_egg,
       preparations: [],
       modifiers: [],
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  # --- "hard-boiled" pattern ---
  # "8 large eggs, hard-boiled and peeled"
  # → ing=egg, preps=[hard-boiled, peeled]
  defp parse_hard_boiled(tokens, original, lookup) do
    egg_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @egg_words))
    qty_tokens = tokens |> Enum.take(egg_idx || 0) |> Enum.filter(&(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    # Collect preps: "hard-boiled" plus any other prep tokens after the egg
    preps = ["hard-boiled"]
    additional_preps = tokens
      |> Enum.drop((egg_idx || 0) + 1)
      |> Enum.filter(&(&1.label == :prep))
      |> Enum.map(& &1.text)
      |> Enum.reject(&(&1 == "separated"))  # don't mix patterns

    all_preps = preps ++ additional_preps

    matched = TokenParser.match_ingredient("egg", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: nil,
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: all_preps,
       modifiers: extract_modifiers(tokens, egg_idx),
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  # Extract modifier tokens (large, medium, etc.) that appear before the egg
  defp extract_modifiers(tokens, egg_idx) when is_integer(egg_idx) do
    tokens
    |> Enum.take(egg_idx)
    |> Enum.filter(&(&1.label == :mod))
    |> Enum.map(& &1.text)
  end

  defp extract_modifiers(_tokens, _), do: []
end
