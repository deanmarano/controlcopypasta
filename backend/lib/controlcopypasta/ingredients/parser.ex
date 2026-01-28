defmodule Controlcopypasta.Ingredients.Parser do
  @moduledoc """
  Enhanced ingredient parser that extracts structured data from ingredient text.

  Handles complex patterns like:
  - `"2 (14.5 oz) cans diced tomatoes"` → container with size
  - `"1 cup (about 200g) flour"` → primary with alternative measurement
  - `"1 lb chicken breast, diced"` → ingredient with preparation
  - `"1/2 cup firmly packed brown sugar"` → quantity with modifier

  ## Output Structure

  Returns a `ParsedIngredient` struct with:
  - `original` - Original input text
  - `canonical_name` - Matched canonical ingredient name
  - `canonical_id` - UUID of matched canonical ingredient
  - `form` - Product form (canned, frozen, etc.)
  - `quantity` - Primary quantity value
  - `unit` - Primary unit
  - `container` - Container info (size_value, size_unit)
  - `preparations` - List of preparation methods
  - `modifiers` - Modifiers like "firmly packed"
  - `confidence` - Confidence score (0.0 - 1.0)
  """

  alias Controlcopypasta.Ingredients

  defmodule ParsedIngredient do
    @moduledoc """
    Struct representing a parsed ingredient.
    """
    defstruct [
      :original,
      :canonical_name,
      :canonical_id,
      :form,
      :quantity,
      :quantity_min,
      :quantity_max,
      :unit,
      :container,
      :alt_quantity,
      :alt_unit,
      :preparations,
      :modifiers,
      :confidence,
      :raw_name,
      :alternatives
    ]

    @type t :: %__MODULE__{
            original: String.t(),
            canonical_name: String.t() | nil,
            canonical_id: String.t() | nil,
            form: String.t() | nil,
            quantity: float() | nil,
            quantity_min: float() | nil,
            quantity_max: float() | nil,
            unit: String.t() | nil,
            container: map() | nil,
            alt_quantity: float() | nil,
            alt_unit: String.t() | nil,
            preparations: [String.t()],
            modifiers: [String.t()],
            confidence: float(),
            raw_name: String.t(),
            alternatives: [String.t()]
          }
  end

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
    # Containers/counts
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
    "heads" => "head",
    "box" => "box",
    "boxes" => "box",
    "bag" => "bag",
    "bags" => "bag",
    "bottle" => "bottle",
    "bottles" => "bottle"
  }

  @container_units ~w(can cans jar jars package packages pkg box boxes bag bags bottle bottles)

  # Multi-word preparations that need to be matched before word-by-word processing
  @multi_word_preparations %{
    "room temperature" => "room temperature",
    "at room temperature" => "room temperature",
    "at room temp" => "room temperature",
    "cut into pieces" => "cut into pieces",
    "cut into cubes" => "diced",
    "cut into strips" => "julienned",
    "cut into matchsticks" => "julienned",
    "cut into wedges" => "cut into wedges",
    "cut into chunks" => "cut into chunks",
    "thinly sliced" => "sliced",
    "finely chopped" => "chopped",
    "finely minced" => "minced",
    "finely grated" => "grated",
    "coarsely chopped" => "chopped",
    "roughly chopped" => "chopped",
    "split lengthwise" => "split",
    "halved lengthwise" => "halved",
    "quartered lengthwise" => "quartered",
    "casings removed" => "casings removed"
  }

  # Descriptors to strip from beginning of ingredient names
  @prefix_descriptors ~w(
    skinless boneless bone-in skin-on large small medium extra-large
    fresh frozen dried organic raw ripe unripe whole unsalted
  )

  # Descriptors to strip from end of ingredient names
  @suffix_descriptors ~w(
    cloves clove pieces piece chunks chunk slices slice
    halves half florets leaves leaf stalks stalk sprigs sprig
    rings ring wedges wedge strips strip cubes cube
    tails tail filets fillet fillets breasts breast thighs thigh
    legs leg wings wing
  )

  @preparation_words %{
    # Cutting methods
    "chopped" => "chopped",
    "diced" => "diced",
    "minced" => "minced",
    "sliced" => "sliced",
    "cubed" => "diced",
    "julienned" => "julienned",
    "shredded" => "shredded",
    "grated" => "grated",
    "crushed" => "crushed",
    "smashed" => "smashed",
    "halved" => "halved",
    "quartered" => "quartered",
    "torn" => "torn",
    "separated" => "separated",
    "crumbled" => "crumbled",
    # Temperature/state
    "melted" => "melted",
    "softened" => "softened",
    "cold" => "cold",
    "warm" => "warm",
    "hot" => "hot",
    "frozen" => "frozen",
    "thawed" => "thawed",
    "chilled" => "chilled",
    "cooled" => "cooled",
    # Processing
    "drained" => "drained",
    "rinsed" => "rinsed",
    "strained" => "strained",
    "peeled" => "peeled",
    "seeded" => "seeded",
    "cored" => "cored",
    "pitted" => "pitted",
    "trimmed" => "trimmed",
    "deveined" => "deveined",
    # Texture
    "mashed" => "mashed",
    "pureed" => "pureed",
    "beaten" => "beaten",
    "whisked" => "whisked",
    "sifted" => "sifted",
    # Freshness/form
    "fresh" => "fresh",
    "dried" => "dried",
    "canned" => "canned",
    "cooked" => "cooked",
    "raw" => "raw",
    "toasted" => "toasted",
    "roasted" => "roasted"
  }

  @modifiers ~w(
    lightly firmly loosely tightly well roughly coarsely finely
    thinly thickly small medium large extra packed heaping scant level
  )

  @doc """
  Parses an ingredient string into a structured ParsedIngredient.

  ## Options

  - `:lookup` - Pre-built ingredient lookup map (optional, will build if not provided)
  - `:match_canonical` - Whether to match against canonical ingredients (default: true)

  ## Examples

      iex> Parser.parse("2 (14.5 oz) cans diced tomatoes, drained")
      %ParsedIngredient{
        original: "2 (14.5 oz) cans diced tomatoes, drained",
        quantity: 2.0,
        unit: "can",
        container: %{size_value: 14.5, size_unit: "oz"},
        canonical_name: "tomato",
        preparations: ["diced", "drained"],
        confidence: 0.95
      }

      iex> Parser.parse("1 lb chicken breast, diced")
      %ParsedIngredient{
        original: "1 lb chicken breast, diced",
        quantity: 1.0,
        unit: "lb",
        canonical_name: "chicken breast",
        preparations: ["diced"],
        confidence: 0.9
      }
  """
  @spec parse(String.t(), keyword()) :: ParsedIngredient.t()
  def parse(text, opts \\ []) when is_binary(text) do
    original = text

    # Check if this is equipment or a non-ingredient entry
    cond do
      is_equipment?(text) ->
        %ParsedIngredient{
          original: original,
          raw_name: text,
          confidence: 0.0,
          preparations: [],
          modifiers: [],
          alternatives: [],
          alt_quantity: nil,
          alt_unit: nil
        }

      is_non_ingredient?(text) ->
        %ParsedIngredient{
          original: original,
          raw_name: text,
          confidence: 0.0,
          preparations: [],
          modifiers: [],
          alternatives: [],
          alt_quantity: nil,
          alt_unit: nil
        }

      true ->
        parse_ingredient(text, original, opts)
    end
  end

  defp parse_ingredient(text, original, opts) do
    text = normalize_text(text)

    # Extract components (with quantity range support)
    {quantity, quantity_min, quantity_max, container, rest} = extract_quantity_and_container(text)
    {unit, rest} = extract_unit(rest)

    # If no unit was extracted but we have a container with size_unit, use that
    # This handles patterns like "1 14 ounce can coconut milk"
    unit = unit || (container && container.size_unit)

    # Extract alternative measurement from parentheticals BEFORE cleaning them
    # e.g., "1 cup (120g) flour" -> alt_quantity: 120, alt_unit: "g"
    {alt_quantity, alt_unit, rest} = extract_alt_measurement(rest)

    # Extract form alternatives BEFORE preparations (so "fresh or dried" isn't broken up)
    {form_alternatives, rest} = extract_form_alternatives(rest)

    {preparations, modifiers, rest} = extract_preparations_and_modifiers(rest)
    raw_name = clean_ingredient_name(rest)

    # Handle "or" alternatives (e.g., "chicken or vegetable broth")
    {primary_name, alternatives} = extract_alternatives(raw_name)

    # If we have form alternatives, prepend the primary form to the name
    # and add the alternate forms as alternatives
    {primary_name, alternatives, explicit_form} =
      case form_alternatives do
        [primary_form | alt_forms] ->
          # Primary name gets the first form
          new_primary = "#{primary_form} #{primary_name}"
          # Alternatives get the other forms combined with the base name
          form_alts = Enum.map(alt_forms, fn form -> "#{form} #{primary_name}" end)
          {new_primary, form_alts ++ alternatives, primary_form}

        [] ->
          {primary_name, alternatives, nil}
      end

    # Detect form - use explicit form from alternatives if available, otherwise scan text
    form = explicit_form || detect_form(original, unit)

    # Match to canonical ingredient (use primary name for matching)
    {canonical_name, canonical_id, confidence} =
      if Keyword.get(opts, :match_canonical, true) do
        match_canonical(primary_name, opts)
      else
        {nil, nil, 0.5}
      end

    %ParsedIngredient{
      original: original,
      canonical_name: canonical_name,
      canonical_id: canonical_id,
      form: form,
      quantity: quantity,
      quantity_min: quantity_min,
      quantity_max: quantity_max,
      unit: unit,
      container: container,
      alt_quantity: alt_quantity,
      alt_unit: alt_unit,
      preparations: preparations,
      modifiers: modifiers,
      confidence: confidence,
      raw_name: primary_name,
      alternatives: alternatives
    }
  end

  @doc """
  Parses an ingredient map (from recipe JSONB) into structured components.
  """
  @spec parse_ingredient_map(map(), keyword()) :: ParsedIngredient.t()
  def parse_ingredient_map(%{"text" => text}, opts) when is_binary(text), do: parse(text, opts)
  def parse_ingredient_map(%{text: text}, opts) when is_binary(text), do: parse(text, opts)

  def parse_ingredient_map(_, _opts) do
    %ParsedIngredient{
      original: "",
      canonical_name: nil,
      canonical_id: nil,
      form: nil,
      quantity: nil,
      quantity_min: nil,
      quantity_max: nil,
      unit: nil,
      container: nil,
      alt_quantity: nil,
      alt_unit: nil,
      preparations: [],
      modifiers: [],
      confidence: 0.0,
      raw_name: "",
      alternatives: []
    }
  end

  @doc """
  Converts a ParsedIngredient to a map suitable for JSONB storage.
  """
  @spec to_jsonb_map(ParsedIngredient.t()) :: map()
  def to_jsonb_map(%ParsedIngredient{} = parsed) do
    base = %{
      "canonical_name" => parsed.canonical_name,
      "canonical_id" => parsed.canonical_id,
      "form" => parsed.form,
      "quantity" => %{
        "value" => parsed.quantity,
        "min" => parsed.quantity_min,
        "max" => parsed.quantity_max,
        "unit" => parsed.unit
      },
      "preparations" => parsed.preparations,
      "confidence" => parsed.confidence
    }

    base =
      if parsed.container do
        container_map = %{
          "size_value" => parsed.container.size_value,
          "size_unit" => parsed.container.size_unit
        }

        Map.put(base, "container_size", container_map)
      else
        base
      end

    # Add alternative measurement if present
    if parsed.alt_quantity && parsed.alt_unit do
      Map.put(base, "alt_quantity", %{
        "value" => parsed.alt_quantity,
        "unit" => parsed.alt_unit
      })
    else
      base
    end
  end

  # =============================================================================
  # Private Functions
  # =============================================================================

  defp normalize_text(text) do
    text
    |> String.trim()
    |> String.downcase()
    # Replace unicode fractions FIRST, before any other regex processing
    # This prevents the dash normalization from corrupting multi-byte unicode sequences
    |> replace_unicode_fractions()
    # Normalize dashes: en-dash and em-dash to hyphen (use unicode-aware regex)
    |> String.replace(~r/[–—]/u, "-")
    |> String.replace(~r/\s+/, " ")
  end

  defp replace_unicode_fractions(text) do
    Enum.reduce(@unicode_fractions, text, fn {char, value}, acc ->
      # If preceded by a digit, this is a mixed number (e.g., "1½" -> "1+0.5")
      # Use a two-step replacement to handle this reliably with unicode
      if String.contains?(acc, char) do
        # First, handle digit immediately followed by fraction (mixed number)
        # Find all occurrences of digit+fraction and replace them
        acc = Regex.replace(~r/(\d)#{Regex.escape(char)}/, acc, fn _, digit ->
          "#{digit}+#{value}"
        end)
        # Then replace any remaining standalone fractions
        String.replace(acc, char, "#{value}")
      else
        acc
      end
    end)
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Extracts quantity and optional container size (e.g., "2 (14.5 oz) cans")
  defp extract_quantity_and_container(text) do
    # Pattern 1: "2 (14.5 oz) cans" or "2 (400g) cans" - with parentheses
    container_pattern_parens =
      ~r/^(\d+(?:\.\d+)?)\s*\((\d+(?:\.\d+)?)\s*(#{unit_pattern()})\)\s*(.*)$/i

    # Pattern 2: "1 14 ounce can" or "2 15-oz cans" - without parentheses
    # Matches: count + size + unit + container_type + rest
    container_pattern_no_parens =
      ~r/^(\d+)\s+(\d+(?:\.\d+)?)\s*-?\s*(ounce|ounces|oz|gram|grams|g|ml|milliliter|milliliters|liter|liters|l|fl oz|fluid ounce|fluid ounces)\s+(can|cans|jar|jars|bottle|bottles|package|packages|pkg|box|boxes|bag|bags|container|containers)\s+(.*)$/i

    cond do
      match = Regex.run(container_pattern_parens, text) ->
        [_, qty, size_val, size_unit, rest] = match
        {qty_float, _} = Float.parse(qty)
        {size_float, _} = Float.parse(size_val)
        canonical_size_unit = Map.get(@unit_mappings, String.downcase(size_unit), size_unit)

        container = %{
          size_value: size_float,
          size_unit: canonical_size_unit
        }

        # Container patterns have exact quantities (no range)
        {qty_float, qty_float, qty_float, container, String.trim(rest)}

      match = Regex.run(container_pattern_no_parens, text) ->
        # "1 14 ounce can coconut milk" -> qty=1, size=14, unit=oz, container=can
        # Total quantity = count * size = 1 * 14 = 14 oz
        [_, count, size_val, size_unit, _container_type, rest] = match
        {count_float, _} = Float.parse(count)
        {size_float, _} = Float.parse(size_val)
        total_quantity = count_float * size_float
        canonical_size_unit = Map.get(@unit_mappings, String.downcase(size_unit), size_unit)

        container = %{
          size_value: size_float,
          size_unit: canonical_size_unit
        }

        # Container patterns have exact quantities (no range)
        {total_quantity, total_quantity, total_quantity, container, String.trim(rest)}

      true ->
        # Try standard quantity extraction (may return range)
        {qty, qty_min, qty_max, rest} = extract_standard_quantity(text)
        {qty, qty_min, qty_max, nil, rest}
    end
  end

  # Returns {quantity_best, quantity_min, quantity_max, rest}
  # For ranges like "2-3 cups", preserves min/max for uncertainty tracking
  defp extract_standard_quantity(text) do
    cond do
      # Mixed number with + (from Unicode fraction): "2+0.333"
      match = Regex.run(~r/^(\d+)\+(\d+(?:\.\d+)?)\s*(.*)$/, text) ->
        [_, whole, frac, rest] = match
        {frac_val, _} = Float.parse(frac)
        quantity = String.to_integer(whole) + frac_val
        {quantity, quantity, quantity, String.trim(rest)}

      # Mixed number: "1 1/2" or "1-1/2"
      match = Regex.run(~r/^(\d+)\s*[-\s]\s*(\d+)\/(\d+)\s*(.*)$/, text) ->
        [_, whole, num, den, rest] = match
        quantity = String.to_integer(whole) + String.to_integer(num) / String.to_integer(den)
        {quantity, quantity, quantity, String.trim(rest)}

      # Fraction: "1/2"
      match = Regex.run(~r/^(\d+)\/(\d+)\s*(.*)$/, text) ->
        [_, num, den, rest] = match
        quantity = String.to_integer(num) / String.to_integer(den)
        {quantity, quantity, quantity, String.trim(rest)}

      # Range with hyphen: "2-3" (preserve min/max, use average as best)
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s*-\s*(\d+(?:\.\d+)?)\s+(.*)$/, text) ->
        [_, low, high, rest] = match
        {low_f, _} = Float.parse(low)
        {high_f, _} = Float.parse(high)
        best = (low_f + high_f) / 2
        {best, low_f, high_f, String.trim(rest)}

      # Range with "or": "2 or 3" (preserve min/max, use average as best)
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s+or\s+(\d+(?:\.\d+)?)\s+(.*)$/i, text) ->
        [_, low, high, rest] = match
        {low_f, _} = Float.parse(low)
        {high_f, _} = Float.parse(high)
        best = (low_f + high_f) / 2
        {best, low_f, high_f, String.trim(rest)}

      # Range with "to": "3 to 4" (preserve min/max, use average as best)
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s+to\s+(\d+(?:\.\d+)?)\s+(.*)$/i, text) ->
        [_, low, high, rest] = match
        {low_f, _} = Float.parse(low)
        {high_f, _} = Float.parse(high)
        best = (low_f + high_f) / 2
        {best, low_f, high_f, String.trim(rest)}

      # Decimal or integer: "2.5" or "2" (no range, min = max = best)
      match = Regex.run(~r/^(\d+(?:\.\d+)?)\s*(.*)$/, text) ->
        [_, num, rest] = match
        {val, _} = Float.parse(num)
        {val, val, val, String.trim(rest)}

      # No quantity found
      true ->
        {nil, nil, nil, text}
    end
  end

  defp extract_unit(text) do
    pattern = ~r/^(#{unit_pattern()})\.?\s+(.+)$/i

    case Regex.run(pattern, text) do
      [_, unit, name] ->
        canonical_unit = Map.get(@unit_mappings, String.downcase(unit), String.downcase(unit))
        {canonical_unit, String.trim(name)}

      nil ->
        {nil, String.trim(text)}
    end
  end

  defp unit_pattern do
    @unit_mappings
    |> Map.keys()
    |> Enum.sort_by(&(-String.length(&1)))
    |> Enum.map(&Regex.escape/1)
    |> Enum.join("|")
  end

  # Extracts "fresh or dried" / "dried or fresh" patterns before preparation extraction
  # Returns {[alternative_forms], remaining_text}
  # e.g., "fresh or dried bay leaf" -> {["fresh", "dried"], "bay leaf"}
  defp extract_form_alternatives(text) do
    # Pattern: "fresh or dried X" or "dried or fresh X"
    case Regex.run(~r/^(fresh|dried|frozen|canned)\s+or\s+(fresh|dried|frozen|canned)\s+(.+)$/i, text) do
      [_, form1, form2, rest] ->
        {[String.downcase(form1), String.downcase(form2)], String.trim(rest)}

      nil ->
        {[], text}
    end
  end

  # Alternative measurement units (metric weights and volumes)
  @alt_measurement_units ~w(g grams gram kg kilograms kilogram ml milliliters milliliter l liters liter)

  # Extracts alternative measurements from parentheticals
  # e.g., "(120g)" or "(about 4 cups)" -> {quantity, unit}
  # Returns {alt_quantity, alt_unit, cleaned_text}
  defp extract_alt_measurement(text) do
    # Pattern 1: Metric weight/volume in parens: "(120g)", "(120 g)", "(120 grams)"
    # Must match metric units to avoid matching "(14.5 oz) cans" container patterns
    metric_pattern = ~r/\(\s*([\d\.]+)\s*(#{Enum.join(@alt_measurement_units, "|")})\s*\)/i

    case Regex.run(metric_pattern, text) do
      [full_match, qty_str, unit] ->
        {qty, _} = Float.parse(qty_str)
        normalized_unit = normalize_alt_unit(unit)
        cleaned = String.replace(text, full_match, "") |> String.replace(~r/\s+/, " ") |> String.trim()
        {qty, normalized_unit, cleaned}

      nil ->
        # Pattern 2: "about X cups" in parens: "(about 4 cups)", "(approximately 2 cups)"
        about_pattern = ~r/\(\s*(?:about|approximately|roughly|around|~)\s*([\d\.\/½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+)\s*(#{unit_pattern()})\s*\)/i

        case Regex.run(about_pattern, text) do
          [full_match, qty_str, unit] ->
            qty = parse_alt_quantity(qty_str)
            normalized_unit = Map.get(@unit_mappings, String.downcase(unit), String.downcase(unit))
            cleaned = String.replace(text, full_match, "") |> String.replace(~r/\s+/, " ") |> String.trim()
            {qty, normalized_unit, cleaned}

          nil ->
            {nil, nil, text}
        end
    end
  end

  # Normalize alternative measurement units to short forms
  defp normalize_alt_unit(unit) do
    case String.downcase(unit) do
      u when u in ~w(g gram grams) -> "g"
      u when u in ~w(kg kilogram kilograms) -> "kg"
      u when u in ~w(ml milliliter milliliters) -> "ml"
      u when u in ~w(l liter liters) -> "l"
      other -> other
    end
  end

  # Parse alternative quantity (handles fractions and unicode fractions)
  defp parse_alt_quantity(str) do
    str = String.trim(str)

    # Check for unicode fractions first
    unicode_val = Enum.find_value(@unicode_fractions, fn {char, val} ->
      if String.contains?(str, char), do: val
    end)

    cond do
      unicode_val != nil ->
        # Handle mixed number with unicode (e.g., "1½")
        case Regex.run(~r/^(\d+)/, str) do
          [_, whole] -> String.to_integer(whole) + unicode_val
          nil -> unicode_val
        end

      String.contains?(str, "/") ->
        # Handle fraction (e.g., "1/2")
        case Regex.run(~r/^(\d+)\/(\d+)$/, str) do
          [_, num, den] -> String.to_integer(num) / String.to_integer(den)
          nil -> parse_float_safe(str)
        end

      true ->
        parse_float_safe(str)
    end
  end

  defp parse_float_safe(str) do
    case Float.parse(str) do
      {val, _} -> val
      :error -> nil
    end
  end

  defp extract_preparations_and_modifiers(text) do
    # First, extract multi-word preparations from the entire text
    {multi_preps, text} = extract_multi_word_preparations(text)

    # Split on comma to separate post-prep instructions
    parts = String.split(text, ",", trim: true)

    # Extract preparations from all parts
    {all_preps, all_mods, cleaned_parts} =
      Enum.reduce(parts, {[], [], []}, fn part, {preps, mods, cleaned} ->
        part = String.trim(part)

        # Skip parts that are just instructions like "plus more", "divided", etc.
        if skip_part?(part) do
          {preps, mods, cleaned}
        else
          words = String.split(part, " ")

          # Extract preparations and modifiers from this part
          {part_preps, part_mods, remaining_words} =
            Enum.reduce(words, {[], [], []}, fn word, {p, m, r} ->
              cond do
                Map.has_key?(@preparation_words, word) ->
                  {[Map.get(@preparation_words, word) | p], m, r}

                word in @modifiers ->
                  {p, [word | m], r}

                true ->
                  {p, m, [word | r]}
              end
            end)

          remaining = remaining_words |> Enum.reverse() |> Enum.join(" ") |> String.trim()

          if remaining == "" do
            {preps ++ Enum.reverse(part_preps), mods ++ Enum.reverse(part_mods), cleaned}
          else
            {preps ++ Enum.reverse(part_preps), mods ++ Enum.reverse(part_mods), cleaned ++ [remaining]}
          end
        end
      end)

    cleaned_text = Enum.join(cleaned_parts, ", ")

    {Enum.uniq(multi_preps ++ all_preps), Enum.uniq(all_mods), cleaned_text}
  end

  # Extract multi-word preparations from text and return {preparations, cleaned_text}
  defp extract_multi_word_preparations(text) do
    Enum.reduce(@multi_word_preparations, {[], text}, fn {phrase, canonical}, {preps, txt} ->
      if String.contains?(txt, phrase) do
        {[canonical | preps], String.replace(txt, phrase, "")}
      else
        {preps, txt}
      end
    end)
  end

  # Parts to skip entirely (instructions, not ingredients)
  defp skip_part?(part) do
    part = String.downcase(part)

    cond do
      # "plus more", "plus more for surface", etc.
      String.starts_with?(part, "plus more") -> true
      String.starts_with?(part, "and more") -> true
      # "divided" by itself
      part == "divided" -> true
      # "for serving", "for garnish", etc.
      String.starts_with?(part, "for ") -> true
      # "optional"
      part == "optional" -> true
      # "to taste"
      part == "to taste" -> true
      # "as needed"
      part == "as needed" -> true
      # "preferably X"
      String.starts_with?(part, "preferably") -> true
      true -> false
    end
  end

  # Equipment terms that indicate this is not an ingredient
  @equipment_terms [
    "thermometer", "timer", "pastry bag", "piping bag", "stand mixer",
    "hand mixer", "food processor", "blender", "immersion blender",
    "scale", "kitchen scale", "baking sheet", "sheet pan", "parchment",
    "paper towel", "plastic wrap", "aluminum foil", "dutch oven",
    "skillet", "saucepan", "pot", "pan", "rack", "springform pan",
    "cake pan", "pie pan", "muffin tin", "cookie sheet", "rolling pin",
    "whisk", "spatula", "tongs", "ladle", "strainer", "colander",
    "mandoline", "grater", "peeler", "zester", "knife", "cutting board",
    "blowtorch", "kitchen torch", "glass jar", "mason jar", "canning jar",
    "spice mill", "mortar and pestle", "skewer", "metal skewer", "bamboo skewer",
    "baking dish", "casserole dish", "roasting pan", "grill", "grill pan",
    "ramekin", "ramekins", "air fryer", "cheesecloth", "cookie cutter",
    "round cutter", "pastry tip", "instant pot", "pressure cooker"
  ]

  defp is_equipment?(text) do
    lower = String.downcase(text)

    # Equipment patterns:
    # - Starts with "a" or "an" (e.g., "A deep-fry thermometer")
    # - Starts with a number word (e.g., "Eight 6-oz. glass jars")
    number_words = ~w(one two three four five six seven eight nine ten twelve)
    starts_with_article = String.starts_with?(lower, "a ") or String.starts_with?(lower, "an ")
    starts_with_number = Enum.any?(number_words, &String.starts_with?(lower, "#{&1} "))

    (starts_with_article or starts_with_number) and
      Enum.any?(@equipment_terms, &String.contains?(lower, &1))
  end

  # Patterns that indicate section headers, notes, or instructions rather than ingredients
  @non_ingredient_patterns [
    # Section headers
    ~r/^(dry|wet|for the|for sauce|for filling|for topping|for crust|for frosting|for glaze)\s+ingredients?$/i,
    ~r/^ingredients?\s*(:|$)/i,
    ~r/^(sauce|filling|topping|crust|frosting|glaze|dressing|marinade|batter|dough)(\s*:)?$/i,
    # Notes and references
    ~r/^\*?see\s+(note|recipe|instructions)/i,
    ~r/^\*+(see|note)/i,
    ~r/^note:/i,
    # Optional instructions
    ~r/^optional:/i,
    # Store/market references (these are notes, not ingredients)
    ~r/can be found (at|in)/i,
    ~r/is available (at|in)/i,
    ~r/are available (at|in)/i,
    # Pure instructions
    ~r/^(toppings?|garnish(es)?)\s+as\s+desired/i,
    # Equipment items without article prefix
    ~r/^dolsot bowls?$/i
  ]

  defp is_non_ingredient?(text) do
    lower = String.downcase(String.trim(text))

    # Check against patterns
    Enum.any?(@non_ingredient_patterns, &Regex.match?(&1, lower))
  end

  defp clean_ingredient_name(name) do
    name
    # Remove parentheticals like "(about 200g)" or "(optional)"
    # Use greedy matching to handle nested parens like ((optional))
    |> String.replace(~r/\([^()]*\)/, "")
    # Run again to catch outer parens after inner ones removed
    |> String.replace(~r/\([^()]*\)/, "")
    # Remove any orphaned closing parentheses
    |> String.replace(~r/\)+/, "")
    # Remove any orphaned opening parentheses
    |> String.replace(~r/\(+/, "")
    # Remove "divided" from ingredient name
    |> String.replace(~r/,?\s*divided\s*$/, "")
    |> String.replace(~r/,?\s*divided,/, ",")
    # Remove "plus more" patterns
    |> String.replace(~r/[,;]?\s*plus more.*$/i, "")
    # Remove "for serving" etc.
    |> String.replace(~r/[,;]?\s*for\s+(serving|garnish|drizzling|brushing|dusting|surface|frying).*$/i, "")
    # Remove trailing asterisks (recipe notes markers)
    |> String.replace(~r/\*+$/, "")
    # Remove leading asterisks
    |> String.replace(~r/^\*+/, "")
    # Normalize apostrophes (curly to straight)
    |> String.replace(~r/[''`]/, "'")
    # Remove leading "of" (from "1 cup of flour")
    |> String.replace(~r/^of\s+/i, "")
    # Remove leading/trailing punctuation (including semicolons)
    |> String.replace(~r/^[,.;\s]+|[,.;\s]+$/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Words that are commonly shared suffixes in "X or Y Z" patterns
  @shared_suffix_words ~w(broth stock milk cream cheese oil butter juice vinegar
                          wine sauce paste flour sugar salt pepper powder extract)

  # Form descriptors that can be alternatives (fresh or dried, etc.)
  @form_descriptor_words ~w(fresh dried frozen canned)

  # Extracts alternatives from "X or Y" patterns
  # Returns {primary, [alternatives]}
  #
  # Handles patterns like:
  # - "chicken or vegetable broth" -> {"chicken broth", ["vegetable broth"]}
  # - "plums, apricots, or peaches" -> {"plums", ["apricots", "peaches"]}
  # - "capers or jalapeños" -> {"capers", ["jalapeños"]}
  # - "fresh or dried bay leaf" -> {"fresh bay leaf", ["dried bay leaf"]}
  defp extract_alternatives(name) do
    # Remove "or other X" patterns (generic fallbacks)
    name = String.replace(name, ~r/,?\s+or\s+other\s+\w+.*$/i, "")

    cond do
      # Pattern: comma-separated list with "or" (e.g., "plums, apricots, or peaches")
      # Also handles "amaretto, Grand Marnier, or sweet vermouth"
      String.contains?(name, ",") ->
        # Split on both commas and " or "
        parts =
          name
          |> String.replace(~r/,?\s+or\s+/, ", ")
          |> String.split(~r/,\s*/, trim: true)
          |> Enum.map(&String.trim/1)
          |> Enum.reject(&(&1 == ""))

        case parts do
          [primary | rest] -> {primary, rest}
          _ -> {name, []}
        end

      # Check for "X or Y" pattern
      String.contains?(name, " or ") ->
        case String.split(name, " or ", parts: 2) do
          [left, right] ->
            left = String.trim(left)
            right = String.trim(right)
            left_words = String.split(left, " ")
            right_words = String.split(right, " ")

            cond do
              # Pattern: "fresh or dried X" - form descriptors with shared ingredient
              # e.g., "fresh or dried bay leaf" -> {"fresh bay leaf", ["dried bay leaf"]}
              length(left_words) == 1 and length(right_words) >= 2 and
                  String.downcase(hd(left_words)) in @form_descriptor_words and
                  String.downcase(hd(right_words)) in @form_descriptor_words ->
                [right_form | ingredient_words] = right_words
                ingredient = Enum.join(ingredient_words, " ")
                primary = "#{left} #{ingredient}"
                alt = "#{right_form} #{ingredient}"
                {primary, [alt]}

              # Pattern: "X or Y Z" - shared suffix (e.g., "chicken or vegetable broth")
              # Only apply if left is a single word and right has exactly 2 words
              # with the last word being a known suffix
              length(left_words) == 1 and length(right_words) == 2 ->
                [right_adj, suffix] = right_words

                if String.downcase(suffix) in @shared_suffix_words do
                  # This is a shared suffix pattern
                  primary = "#{left} #{suffix}"
                  alt = "#{right_adj} #{suffix}"
                  {primary, [alt]}
                else
                  # Not a known suffix, treat as separate items
                  {left, [right]}
                end

              # Default: just split on "or"
              true ->
                {left, [right]}
            end

          _ ->
            {name, []}
        end

      true ->
        {name, []}
    end
  end

  defp detect_form(original, unit) do
    original_lower = String.downcase(original)

    cond do
      String.contains?(original_lower, "canned") or unit == "can" ->
        "canned"

      String.contains?(original_lower, "frozen") ->
        "frozen"

      String.contains?(original_lower, "dried") ->
        "dried"

      String.contains?(original_lower, "fresh") ->
        "fresh"

      unit in @container_units ->
        detect_form_from_container(unit)

      true ->
        nil
    end
  end

  defp detect_form_from_container(unit) when unit in ~w(can cans), do: "canned"
  defp detect_form_from_container(unit) when unit in ~w(jar jars), do: "jarred"
  defp detect_form_from_container(unit) when unit in ~w(box boxes), do: "boxed"
  defp detect_form_from_container(unit) when unit in ~w(bag bags), do: "bagged"
  defp detect_form_from_container(unit) when unit in ~w(bottle bottles), do: "bottled"
  defp detect_form_from_container(_), do: nil

  defp match_canonical(raw_name, opts) do
    # Get or build lookup map
    # Lookup maps names/aliases -> {canonical_name, canonical_id}
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)

    # Clean up name: remove extra spaces, trailing commas
    normalized_name =
      raw_name
      |> String.downcase()
      |> String.replace(~r/\s+/, " ")
      |> String.replace(~r/,\s*$/, "")
      |> String.trim()

    # Try exact match first
    case Map.get(lookup, normalized_name) do
      {canonical_name, id} ->
        # Exact match (whether direct name or alias)
        {canonical_name, id, 1.0}

      nil ->
        # Try stripping prefix descriptors
        stripped = strip_prefix_descriptors(normalized_name)

        case Map.get(lookup, stripped) do
          {canonical_name, id} ->
            {canonical_name, id, 1.0}

          nil ->
            # Try stripping suffix descriptors (like "cloves" from "garlic cloves")
            suffix_stripped = strip_suffix_descriptors(stripped)

            case Map.get(lookup, suffix_stripped) do
              {canonical_name, id} ->
                {canonical_name, id, 1.0}

              nil ->
                # Try progressively shorter versions of the name (removing leading words)
                words = String.split(stripped, " ")
                find_partial_match(words, lookup, normalized_name)
            end
        end
    end
  end

  defp strip_prefix_descriptors(name) do
    words = String.split(name, " ")

    stripped =
      Enum.drop_while(words, fn word ->
        word in @prefix_descriptors or String.ends_with?(word, ",")
      end)

    if Enum.empty?(stripped) do
      name
    else
      Enum.join(stripped, " ")
    end
  end

  defp strip_suffix_descriptors(name) do
    words = String.split(name, " ")

    stripped =
      words
      |> Enum.reverse()
      |> Enum.drop_while(fn word ->
        clean_word = String.replace(word, ~r/[,.]$/, "")
        clean_word in @suffix_descriptors
      end)
      |> Enum.reverse()

    if Enum.empty?(stripped) do
      name
    else
      Enum.join(stripped, " ")
    end
  end

  defp find_partial_match(words, lookup, original_name) when length(words) > 1 do
    # Try removing leading word (adjectives/descriptors)
    shorter_front = words |> tl() |> Enum.join(" ")

    case Map.get(lookup, shorter_front) do
      {canonical_name, id} ->
        {canonical_name, id, 0.9}

      nil ->
        # Try removing trailing word (e.g., "pasta dough" -> "pasta")
        shorter_back = words |> Enum.take(length(words) - 1) |> Enum.join(" ")

        case Map.get(lookup, shorter_back) do
          {canonical_name, id} ->
            {canonical_name, id, 0.9}

          nil ->
            # Try even shorter from front
            find_partial_match(tl(words), lookup, original_name)
        end
    end
  end

  defp find_partial_match([single_word], lookup, _original_name) do
    case Map.get(lookup, single_word) do
      {canonical_name, id} ->
        {canonical_name, id, 0.8}

      nil ->
        # No match found, try fuzzy matching
        fuzzy_match(single_word, lookup)
    end
  end

  defp find_partial_match([], _lookup, _original_name) do
    {nil, nil, 0.5}
  end

  defp fuzzy_match(name, lookup) do
    # More conservative fuzzy matching:
    # 1. Only match if name is a prefix of a canonical (e.g., "tomato" matches "tomato paste")
    # 2. Or if the canonical is a prefix of name (e.g., "lobster" matches "lobster tail")
    # 3. Don't match short words (< 5 chars) on substring alone to avoid "tail" -> "oxtail"

    # First, try exact prefix match (name is start of canonical)
    prefix_match =
      lookup
      |> Enum.find(fn {key, _value} ->
        String.starts_with?(key, name <> " ") or key == name
      end)

    case prefix_match do
      {_matched_key, {canonical_name, id}} ->
        {canonical_name, id, 0.8}

      nil ->
        # Try reverse prefix (canonical is start of name)
        reverse_prefix_match =
          lookup
          |> Enum.find(fn {key, _value} ->
            String.starts_with?(name, key <> " ") or name == key
          end)

        case reverse_prefix_match do
          {_matched_key, {canonical_name, id}} ->
            {canonical_name, id, 0.8}

          nil ->
            # Only do substring matching for longer names (6+ chars)
            # This prevents "tail" matching "oxtail" or "dough" matching "sourdough"
            if String.length(name) >= 6 do
              substring_match =
                lookup
                |> Enum.find(fn {key, _value} ->
                  # Require the match to be significant - at least 80% of the shorter string
                  key_len = String.length(key)
                  name_len = String.length(name)
                  min_len = min(key_len, name_len)

                  (String.contains?(key, name) and name_len >= min_len * 0.8) or
                    (String.contains?(name, key) and key_len >= min_len * 0.8)
                end)

              case substring_match do
                {_matched_key, {canonical_name, id}} ->
                  {canonical_name, id, 0.7}

                nil ->
                  {nil, nil, 0.5}
              end
            else
              # Short name with no prefix match - don't guess
              {nil, nil, 0.5}
            end
        end
    end
  end
end
