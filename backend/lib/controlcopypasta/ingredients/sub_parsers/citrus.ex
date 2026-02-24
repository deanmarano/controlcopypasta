defmodule Controlcopypasta.Ingredients.SubParsers.Citrus do
  @moduledoc """
  Sub-parser for citrus juice/zest patterns that the standard parser mishandles.

  Intercepts patterns like:
  - "juice from 2 limes" — ing=lime juice, qty=2
  - "freshly squeezed lemon juice from 2 lemons" — ing=lemon juice
  - "lemon zest from 1 lemon" — ing=lemon zest
  - "juice and zest of 1 lime" — ing=[lime juice, lime zest]
  - "1 lime, juiced" — ing=lime juice
  - "the zest + juice from 1 lime" — ing=[lime juice, lime zest]

  Does NOT match non-citrus juice patterns ("pomegranate juice", "ginger juice").
  Those fall through to the standard parser.
  """

  @behaviour Controlcopypasta.Ingredients.SubParsers.SubParser

  alias Controlcopypasta.Ingredients.TokenParser
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  @citrus_fruits ~w(lime lemon orange grapefruit)
  @citrus_plurals ~w(limes lemons oranges grapefruits)
  @all_citrus @citrus_fruits ++ @citrus_plurals

  @juice_signals ~w(juice juiced squeezed)
  @zest_signals ~w(zest zested)
  @all_signals @juice_signals ++ @zest_signals

  @impl true
  def match?(tokens) do
    texts = Enum.map(tokens, &String.downcase(&1.text))
    has_citrus = Enum.any?(texts, &(&1 in @all_citrus))
    has_signal = Enum.any?(texts, &(&1 in @all_signals))
    has_citrus and has_signal
  end

  @impl true
  def parse(tokens, original, lookup) do
    texts = Enum.map(tokens, &String.downcase(&1.text))

    # Determine derivative type: juice, zest, or both
    derivative = detect_derivative(texts)

    # Find the citrus fruit
    fruit = find_citrus_fruit(texts)

    if fruit do
      parse_citrus(tokens, texts, original, lookup, fruit, derivative)
    else
      :skip
    end
  end

  defp detect_derivative(texts) do
    has_juice = Enum.any?(texts, &(&1 in @juice_signals))
    has_zest = Enum.any?(texts, &(&1 in @zest_signals))

    cond do
      has_juice and has_zest -> :both
      has_juice -> :juice
      has_zest -> :zest
      true -> :juice
    end
  end

  defp find_citrus_fruit(texts) do
    # Find first citrus fruit token, singularize if needed
    Enum.find_value(texts, fn text ->
      cond do
        text in @citrus_fruits -> text
        text in @citrus_plurals -> TokenParser.singularize(text)
        true -> nil
      end
    end)
  end

  defp parse_citrus(tokens, texts, original, lookup, fruit, derivative) do
    # Try to find a measured quantity (e.g., "2 tbsp juice from 1 lemon")
    # or just a fruit count (e.g., "juice from 2 limes")
    {quantity, quantity_min, quantity_max, unit} = extract_quantity_and_unit(tokens, texts)

    # Build ingredient names
    ingredient_names =
      case derivative do
        :both -> ["#{fruit} juice", "#{fruit} zest"]
        :juice -> ["#{fruit} juice"]
        :zest -> ["#{fruit} zest"]
      end

    matched_ingredients = Enum.map(ingredient_names, &TokenParser.match_ingredient(&1, lookup))
    primary = List.first(matched_ingredients)

    {:ok,
     %ParsedIngredient{
       original: original,
       quantity: quantity,
       quantity_min: quantity_min,
       quantity_max: quantity_max,
       unit: unit,
       container: nil,
       ingredients: matched_ingredients,
       primary_ingredient: primary,
       preparations: [],
       modifiers: [],
       storage_medium: nil,
       notes: [],
       is_alternative: false
     }}
  end

  defp extract_quantity_and_unit(tokens, texts) do
    # Look for a measured quantity with a unit (e.g., "2 tbsp")
    # If we find qty + unit before the juice/zest/citrus words, prefer that
    qty_tokens = Enum.filter(tokens, &(&1.label == :qty))
    unit_token = Enum.find(tokens, &(&1.label == :unit))

    # Check if there's a real measurement unit (not just a count unit like "clove")
    has_measured_unit =
      unit_token != nil and
        String.downcase(unit_token.text) not in ~w(clove cloves head heads)

    cond do
      has_measured_unit and length(qty_tokens) >= 1 ->
        # Use the first quantity with the measured unit
        # e.g., "2 tbsp lemon juice" → qty=2, unit=tbsp
        first_qty = hd(qty_tokens)
        {qty, min, max} = TokenParser.parse_quantity([first_qty.text])
        unit = TokenParser.normalize_unit(unit_token.text)
        {qty, min, max, unit}

      length(qty_tokens) >= 1 ->
        # Just a count (e.g., "juice from 2 limes")
        # Find the qty closest to the citrus fruit
        citrus_idx = Enum.find_index(texts, &(&1 in @all_citrus))
        closest_qty = find_closest_qty(qty_tokens, citrus_idx)
        {qty, min, max} = TokenParser.parse_quantity([closest_qty.text])
        {qty, min, max, nil}

      true ->
        {nil, nil, nil, nil}
    end
  end

  defp find_closest_qty(qty_tokens, target_idx) when is_integer(target_idx) do
    # Find qty token closest to (and before) the citrus fruit index
    qty_tokens
    |> Enum.filter(&(&1.position < target_idx))
    |> Enum.max_by(& &1.position, fn -> hd(qty_tokens) end)
  end

  defp find_closest_qty(qty_tokens, _), do: hd(qty_tokens)
end
