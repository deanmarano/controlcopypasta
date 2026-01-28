defmodule Controlcopypasta.Ingredients.SubParsers.Garlic do
  @moduledoc """
  Sub-parser for garlic patterns that the standard parser mishandles.

  Intercepts patterns like:
  - "1 head garlic, cloves peeled" — unit=head, ing=garlic, preps=[peeled]
  - "5 garlic cloves (about 1 tbsp), minced" — unit=clove, ing=garlic, preps=[minced]
  - "Cloves from 1 head of garlic" — unit=head, ing=garlic
  - "Cloves from 1 head of garlic (about 8 cloves), smashed and peeled"

  Does NOT match "1 tsp whole cloves" (no "garlic" token).
  Returns :skip for simple patterns like "4 cloves garlic, minced" that
  the standard parser handles correctly.
  """

  @behaviour Controlcopypasta.Ingredients.SubParsers.SubParser

  alias Controlcopypasta.Ingredients.TokenParser
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  @garlic_words ~w(garlic)
  @clove_words ~w(clove cloves)
  @head_words ~w(head heads)

  @impl true
  def match?(tokens) do
    texts = Enum.map(tokens, &String.downcase(&1.text))
    has_garlic = Enum.any?(texts, &(&1 in @garlic_words))
    has_clove_or_head = Enum.any?(texts, &(&1 in @clove_words ++ @head_words))
    has_garlic and has_clove_or_head
  end

  @impl true
  def parse(tokens, original, lookup) do
    texts = Enum.map(tokens, &String.downcase(&1.text))

    cond do
      # Pattern: "cloves from N head of garlic ..."
      cloves_from_head?(texts) ->
        parse_cloves_from_head(tokens, original, lookup)

      # Pattern: "N head garlic, cloves peeled"
      head_garlic_cloves_prep?(texts) ->
        parse_head_garlic(tokens, original, lookup)

      # Pattern: "N garlic cloves (about ...)" or "N garlic cloves, prep"
      garlic_cloves_pattern?(texts) ->
        parse_garlic_cloves(tokens, original, lookup)

      true ->
        :skip
    end
  end

  # --- Pattern detection ---

  defp cloves_from_head?(texts) do
    # "cloves from N head of garlic" or "cloves from N head garlic"
    clove_idx = Enum.find_index(texts, &(&1 in @clove_words))
    from_idx = if clove_idx, do: Enum.find_index(Enum.drop(texts, clove_idx + 1), &(&1 == "from"))

    clove_idx != nil and from_idx != nil
  end

  defp head_garlic_cloves_prep?(texts) do
    # "N head garlic, cloves peeled" — head before garlic, cloves after comma
    head_idx = Enum.find_index(texts, &(&1 in @head_words))
    garlic_idx = Enum.find_index(texts, &(&1 in @garlic_words))
    comma_idx = Enum.find_index(texts, &(&1 == ","))

    head_idx != nil and garlic_idx != nil and head_idx < garlic_idx and
      comma_idx != nil and comma_idx > garlic_idx and
      has_clove_after_comma?(texts, comma_idx)
  end

  defp has_clove_after_comma?(texts, comma_idx) do
    texts
    |> Enum.drop(comma_idx + 1)
    |> Enum.any?(&(&1 in @clove_words))
  end

  defp garlic_cloves_pattern?(texts) do
    # "N garlic cloves ..." where garlic appears before cloves
    garlic_idx = Enum.find_index(texts, &(&1 in @garlic_words))
    clove_idx = Enum.find_index(texts, &(&1 in @clove_words))

    garlic_idx != nil and clove_idx != nil and garlic_idx < clove_idx and
      clove_idx == garlic_idx + 1
  end

  # --- Parsers ---

  defp parse_cloves_from_head(tokens, original, lookup) do
    # "Cloves from 1 head of garlic (about 8 cloves), smashed and peeled"
    # Find quantity (the number before "head")
    head_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @head_words))
    qty_tokens = tokens |> Enum.take(head_idx) |> Enum.filter(&(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    # Extract preparations from after the comma (or parenthetical)
    preps = extract_preps_after_garlic(tokens)

    matched = TokenParser.match_ingredient("garlic", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: "head",
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: preps,
       modifiers: [],
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  defp parse_head_garlic(tokens, original, lookup) do
    # "1 head garlic, cloves peeled"
    qty_tokens = Enum.filter(tokens, &(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    preps = extract_preps_after_garlic(tokens)

    matched = TokenParser.match_ingredient("garlic", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: "head",
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: preps,
       modifiers: [],
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  defp parse_garlic_cloves(tokens, original, lookup) do
    # "5 garlic cloves (about 1 tbsp), minced"
    # Quantity is before "garlic"
    garlic_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @garlic_words))
    qty_tokens = tokens |> Enum.take(garlic_idx) |> Enum.filter(&(&1.label == :qty))
    {quantity, quantity_min, quantity_max} = TokenParser.parse_quantity(Enum.map(qty_tokens, & &1.text))

    preps = extract_preps_after_garlic(tokens)

    matched = TokenParser.match_ingredient("garlic", lookup)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: "clove",
       container: nil,
       ingredients: [matched],
       primary_ingredient: matched,
       preparations: preps,
       modifiers: [],
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  # Extract preparation words that appear after garlic-related tokens,
  # skipping parenthetical content and clove/garlic words
  defp extract_preps_after_garlic(tokens) do
    garlic_idx = Enum.find_index(tokens, &(String.downcase(&1.text) in @garlic_words))

    tokens
    |> Enum.drop((garlic_idx || 0) + 1)
    |> strip_parenthetical()
    |> Enum.filter(&(&1.label == :prep))
    |> Enum.map(& &1.text)
  end

  # Remove everything between ( and ) inclusive
  defp strip_parenthetical(tokens) do
    case Enum.find_index(tokens, &(&1.text == "(")) do
      nil ->
        tokens

      open_idx ->
        close_idx = Enum.find_index(tokens, &(&1.text == ")"))
        close_idx = close_idx || length(tokens) - 1

        Enum.take(tokens, open_idx) ++ Enum.drop(tokens, close_idx + 1)
    end
  end
end
