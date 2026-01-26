defmodule Controlcopypasta.Similarity.IngredientParser do
  @moduledoc """
  Parses ingredient text into structured components: quantity, unit, and name.
  Examples:
    "2 cups flour" -> %{quantity: 2.0, unit: "cup", name: "flour"}
    "1 1/2 tsp vanilla extract" -> %{quantity: 1.5, unit: "tsp", name: "vanilla extract"}
    "3 large eggs" -> %{quantity: 3.0, unit: nil, name: "large eggs"}
  """

  @type parsed_ingredient :: %{
          quantity: float() | nil,
          unit: String.t() | nil,
          name: String.t(),
          original: String.t()
        }

  # Common cooking units and their canonical forms
  @unit_mappings %{
    # Volume
    "cup" => "cup",
    "cups" => "cup",
    "c" => "cup",
    "tablespoon" => "tbsp",
    "tablespoons" => "tbsp",
    "tbsp" => "tbsp",
    "tbs" => "tbsp",
    "tb" => "tbsp",
    "t" => "tbsp",
    "teaspoon" => "tsp",
    "teaspoons" => "tsp",
    "tsp" => "tsp",
    "ts" => "tsp",
    "fluid ounce" => "fl oz",
    "fluid ounces" => "fl oz",
    "fl oz" => "fl oz",
    "fl. oz" => "fl oz",
    "pint" => "pint",
    "pints" => "pint",
    "pt" => "pint",
    "quart" => "quart",
    "quarts" => "quart",
    "qt" => "quart",
    "gallon" => "gallon",
    "gallons" => "gallon",
    "gal" => "gallon",
    "liter" => "liter",
    "liters" => "liter",
    "litre" => "liter",
    "litres" => "liter",
    "l" => "liter",
    "milliliter" => "ml",
    "milliliters" => "ml",
    "ml" => "ml",
    # Weight
    "ounce" => "oz",
    "ounces" => "oz",
    "oz" => "oz",
    "pound" => "lb",
    "pounds" => "lb",
    "lb" => "lb",
    "lbs" => "lb",
    "gram" => "g",
    "grams" => "g",
    "g" => "g",
    "kilogram" => "kg",
    "kilograms" => "kg",
    "kg" => "kg",
    # Other
    "pinch" => "pinch",
    "pinches" => "pinch",
    "dash" => "dash",
    "dashes" => "dash",
    "bunch" => "bunch",
    "bunches" => "bunch",
    "sprig" => "sprig",
    "sprigs" => "sprig",
    "clove" => "clove",
    "cloves" => "clove",
    "slice" => "slice",
    "slices" => "slice",
    "piece" => "piece",
    "pieces" => "piece",
    "can" => "can",
    "cans" => "can",
    "jar" => "jar",
    "jars" => "jar",
    "package" => "package",
    "packages" => "package",
    "pkg" => "package",
    "stick" => "stick",
    "sticks" => "stick",
    "head" => "head",
    "heads" => "head"
  }

  # Unicode fractions mapping
  @unicode_fractions %{
    "½" => 0.5,
    "⅓" => 0.333,
    "⅔" => 0.667,
    "¼" => 0.25,
    "¾" => 0.75,
    "⅕" => 0.2,
    "⅖" => 0.4,
    "⅗" => 0.6,
    "⅘" => 0.8,
    "⅙" => 0.167,
    "⅚" => 0.833,
    "⅛" => 0.125,
    "⅜" => 0.375,
    "⅝" => 0.625,
    "⅞" => 0.875
  }

  @doc """
  Parses an ingredient string into structured components.
  """
  @spec parse(String.t()) :: parsed_ingredient()
  def parse(text) when is_binary(text) do
    original = text
    text = normalize_text(text)

    {quantity, rest} = extract_quantity(text)
    {unit, name} = extract_unit_and_name(rest)

    %{
      quantity: quantity,
      unit: unit,
      name: normalize_name(name),
      original: original
    }
  end

  @doc """
  Parses an ingredient map (from recipe JSONB) into structured components.
  """
  @spec parse_ingredient_map(map()) :: parsed_ingredient()
  def parse_ingredient_map(%{"text" => text}) when is_binary(text), do: parse(text)
  def parse_ingredient_map(%{text: text}) when is_binary(text), do: parse(text)
  def parse_ingredient_map(_), do: %{quantity: nil, unit: nil, name: "", original: ""}

  defp normalize_text(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> replace_unicode_fractions()
    |> String.replace(~r/\s+/, " ")
  end

  defp replace_unicode_fractions(text) do
    Enum.reduce(@unicode_fractions, text, fn {char, value}, acc ->
      String.replace(acc, char, "#{value} ")
    end)
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp extract_quantity(text) do
    # Try to match various quantity patterns
    cond do
      # Mixed number: "1 1/2" or "1-1/2"
      match = Regex.run(~r/^(\d+)\s*[-\s]\s*(\d+)\/(\d+)\s*(.*)$/, text) ->
        [_, whole, num, den, rest] = match
        quantity = String.to_integer(whole) + String.to_integer(num) / String.to_integer(den)
        {quantity, String.trim(rest)}

      # Fraction: "1/2"
      match = Regex.run(~r/^(\d+)\/(\d+)\s*(.*)$/, text) ->
        [_, num, den, rest] = match
        quantity = String.to_integer(num) / String.to_integer(den)
        {quantity, String.trim(rest)}

      # Range: "2-3" (take the average)
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s*(.*)$/, text) ->
        [_, low, high, rest] = match
        {low_f, _} = Float.parse(low)
        {high_f, _} = Float.parse(high)
        {(low_f + high_f) / 2, String.trim(rest)}

      # Decimal or integer: "2.5" or "2"
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s*(.*)$/, text) ->
        [_, num, rest] = match
        {val, _} = Float.parse(num)
        {val, String.trim(rest)}

      # No quantity found
      true ->
        {nil, text}
    end
  end

  defp extract_unit_and_name(text) do
    # Build a regex pattern for all known units
    unit_pattern =
      @unit_mappings
      |> Map.keys()
      |> Enum.sort_by(&(-String.length(&1)))
      |> Enum.map(&Regex.escape/1)
      |> Enum.join("|")

    case Regex.run(~r/^(#{unit_pattern})\.?\s+(.+)$/i, text) do
      [_, unit, name] ->
        canonical_unit = Map.get(@unit_mappings, String.downcase(unit), String.downcase(unit))
        {canonical_unit, String.trim(name)}

      nil ->
        # Check for parenthetical units like "(14 oz)" or "(400g)"
        case Regex.run(~r/^(.+?)\s*\([\d.]+\s*(#{unit_pattern})\.?\)(.*)$/i, text) do
          [_, name, _unit, extra] ->
            {nil, String.trim(name <> extra)}

          nil ->
            {nil, String.trim(text)}
        end
    end
  end

  defp normalize_name(name) do
    name
    |> String.replace(~r/,.*$/, "")
    |> String.replace(~r/\(.*?\)/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> remove_preparation_words()
  end

  @preparation_words ~w(
    chopped diced minced sliced crushed grated shredded melted softened
    room temperature cold warm hot fresh frozen dried canned packed
    lightly firmly loosely tightly well beaten whisked sifted sieved
    peeled seeded cored pitted trimmed halved quartered cubed julienned
    finely roughly coarsely thinly thickly small medium large extra
  )

  defp remove_preparation_words(name) do
    words = String.split(name, " ")

    cleaned =
      words
      |> Enum.reject(&(&1 in @preparation_words))
      |> Enum.join(" ")

    if String.trim(cleaned) == "", do: name, else: cleaned
  end
end
