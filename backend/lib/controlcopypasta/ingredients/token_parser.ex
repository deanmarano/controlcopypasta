defmodule Controlcopypasta.Ingredients.TokenParser do
  @moduledoc """
  Token-based ingredient parser.

  Uses the Tokenizer to label tokens, then assembles structured ingredient data
  from the labeled tokens. This approach is more robust than regex-based parsing
  because it operates on classified tokens rather than string manipulation.

  ## Example

      iex> TokenParser.parse("1 Tbsp avocado oil or coconut oil")
      %ParsedIngredient{
        original: "1 Tbsp avocado oil or coconut oil",
        quantity: 1.0,
        unit: "tbsp",
        ingredients: [
          %{name: "avocado oil", canonical_name: "avocado oil", canonical_id: "...", confidence: 1.0},
          %{name: "coconut oil", canonical_name: "coconut oil", canonical_id: "...", confidence: 1.0}
        ],
        preparations: [],
        storage_medium: nil
      }
  """

  alias Controlcopypasta.Ingredients.Tokenizer
  alias Controlcopypasta.Ingredients

  defmodule ParsedIngredient do
    @moduledoc "Structured result from parsing an ingredient string."

    defstruct [
      :original,
      :quantity,
      :quantity_min,
      :quantity_max,
      :unit,
      :container,
      :ingredients,      # List of matched ingredients (for alternatives)
      :primary_ingredient,  # The first/main ingredient
      :preparations,
      :modifiers,
      :storage_medium,
      :notes,
      :is_alternative     # true if "or" pattern detected
    ]

    @type ingredient_match :: %{
            name: String.t(),
            canonical_name: String.t() | nil,
            canonical_id: String.t() | nil,
            confidence: float()
          }

    @type t :: %__MODULE__{
            original: String.t(),
            quantity: float() | nil,
            quantity_min: float() | nil,
            quantity_max: float() | nil,
            unit: String.t() | nil,
            container: map() | nil,
            ingredients: [ingredient_match()],
            primary_ingredient: ingredient_match() | nil,
            preparations: [String.t()],
            modifiers: [String.t()],
            storage_medium: String.t() | nil,
            notes: [String.t()],
            is_alternative: boolean()
          }
  end

  @doc """
  Parses an ingredient string into structured data.

  ## Options

  - `:lookup` - Pre-built ingredient lookup map (optional, will build if not provided)

  ## Examples

      iex> TokenParser.parse("2 cups diced tomatoes, drained")
      %ParsedIngredient{
        original: "2 cups diced tomatoes, drained",
        quantity: 2.0,
        unit: "cup",
        ingredients: [%{name: "tomatoes", canonical_name: "tomato", ...}],
        preparations: ["diced", "drained"]
      }
  """
  def parse(text, opts \\ []) when is_binary(text) do
    original = text

    # Tokenize and analyze
    tokens = Tokenizer.tokenize(text)
    analysis = Tokenizer.analyze(tokens)

    # Parse quantity (handle ranges)
    {quantity, quantity_min, quantity_max} = parse_quantity(analysis.quantity)

    # Parse unit
    unit = normalize_unit(analysis.unit)

    # Extract container info if present
    container = extract_container(tokens)

    # Get ingredient names, applying juice/zest transformations
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)
    raw_ingredient_names = clean_ingredient_names(analysis.ingredients)
    ingredient_names = transform_juice_zest_patterns(raw_ingredient_names, analysis.preparations, tokens)
    matched_ingredients = Enum.map(ingredient_names, &match_ingredient(&1, lookup))

    # Get primary ingredient (first one)
    primary = List.first(matched_ingredients)

    %ParsedIngredient{
      original: original,
      quantity: quantity,
      quantity_min: quantity_min,
      quantity_max: quantity_max,
      unit: unit,
      container: container,
      ingredients: matched_ingredients,
      primary_ingredient: primary,
      preparations: analysis.preparations,
      modifiers: analysis.modifiers,
      storage_medium: analysis.storage_medium,
      notes: [],
      is_alternative: analysis.has_alternatives
    }
  end

  @doc """
  Converts a ParsedIngredient to a map suitable for JSONB storage.
  Uses the primary ingredient for backward compatibility.
  """
  def to_jsonb_map(%ParsedIngredient{} = parsed) do
    primary = parsed.primary_ingredient || %{canonical_name: nil, canonical_id: nil, confidence: 0.5}

    base = %{
      "text" => parsed.original,
      "canonical_name" => primary.canonical_name,
      "canonical_id" => primary.canonical_id,
      "confidence" => primary.confidence,
      "quantity" => %{
        "value" => parsed.quantity,
        "min" => parsed.quantity_min,
        "max" => parsed.quantity_max,
        "unit" => parsed.unit
      },
      "preparations" => parsed.preparations,
      "modifiers" => parsed.modifiers
    }

    # Add container if present
    base = if parsed.container do
      Map.put(base, "container", parsed.container)
    else
      base
    end

    # Add storage medium if present
    base = if parsed.storage_medium do
      Map.put(base, "storage_medium", parsed.storage_medium)
    else
      base
    end

    # Add alternatives if present
    if parsed.is_alternative and length(parsed.ingredients) > 1 do
      alternatives = parsed.ingredients
        |> Enum.drop(1)
        |> Enum.map(fn ing ->
          %{
            "name" => ing.name,
            "canonical_name" => ing.canonical_name,
            "canonical_id" => ing.canonical_id
          }
        end)
      Map.put(base, "alternatives", alternatives)
    else
      base
    end
  end

  # Parse quantity strings into floats, handling ranges
  defp parse_quantity([]), do: {nil, nil, nil}
  defp parse_quantity([qty_str | _]) do
    cond do
      # Range: "1-2" or "1/2-3/4"
      String.contains?(qty_str, "-") and not String.starts_with?(qty_str, "-") ->
        case String.split(qty_str, "-", parts: 2) do
          [low, high] ->
            low_val = parse_single_quantity(low)
            high_val = parse_single_quantity(high)
            avg = if low_val && high_val, do: (low_val + high_val) / 2, else: low_val || high_val
            {avg, low_val, high_val}
          _ ->
            val = parse_single_quantity(qty_str)
            {val, val, val}
        end

      true ->
        val = parse_single_quantity(qty_str)
        {val, val, val}
    end
  end

  defp parse_single_quantity(str) do
    str = String.trim(str)
    cond do
      # Fraction: "1/2"
      String.contains?(str, "/") ->
        case String.split(str, "/") do
          [num, den] ->
            with {n, _} <- Float.parse(num),
                 {d, _} <- Float.parse(den),
                 true <- d != 0 do
              n / d
            else
              _ -> nil
            end
          _ -> nil
        end

      # Decimal or integer
      true ->
        case Float.parse(str) do
          {val, _} -> val
          :error -> nil
        end
    end
  end

  # Normalize unit to canonical form
  @unit_mappings %{
    "tablespoons" => "tbsp", "tablespoon" => "tbsp", "tbsp" => "tbsp", "tbs" => "tbsp", "tb" => "tbsp",
    "teaspoons" => "tsp", "teaspoon" => "tsp", "tsp" => "tsp", "ts" => "tsp",
    "cups" => "cup", "cup" => "cup", "c" => "cup",
    "ounces" => "oz", "ounce" => "oz", "oz" => "oz",
    "pounds" => "lb", "pound" => "lb", "lbs" => "lb", "lb" => "lb",
    "grams" => "g", "gram" => "g", "g" => "g",
    "kilograms" => "kg", "kilogram" => "kg", "kg" => "kg",
    "milliliters" => "ml", "milliliter" => "ml", "ml" => "ml",
    "liters" => "l", "liter" => "l", "litres" => "l", "litre" => "l", "l" => "l",
    "pints" => "pint", "pint" => "pint", "pt" => "pint",
    "quarts" => "quart", "quart" => "quart", "qt" => "quart",
    "gallons" => "gallon", "gallon" => "gallon", "gal" => "gallon",
    "cloves" => "clove", "clove" => "clove",
    "slices" => "slice", "slice" => "slice",
    "pieces" => "piece", "piece" => "piece",
    "bunches" => "bunch", "bunch" => "bunch",
    "sprigs" => "sprig", "sprig" => "sprig",
    "heads" => "head", "head" => "head",
    "stalks" => "stalk", "stalk" => "stalk",
    "pinches" => "pinch", "pinch" => "pinch",
    "dashes" => "dash", "dash" => "dash",
    "cans" => "can", "can" => "can",
    "jars" => "jar", "jar" => "jar",
    "bottles" => "bottle", "bottle" => "bottle",
    "packages" => "package", "package" => "package", "pkg" => "package",
    "bags" => "bag", "bag" => "bag",
    "boxes" => "box", "box" => "box"
  }

  defp normalize_unit(nil), do: nil
  defp normalize_unit(unit) do
    Map.get(@unit_mappings, String.downcase(unit), String.downcase(unit))
  end

  # Extract container info from tokens (e.g., "2 (14.5 oz) cans")
  defp extract_container(tokens) do
    # Look for pattern: ( qty unit ) container
    # Find parenthetical with qty and unit
    tokens
    |> find_container_pattern()
  end

  defp find_container_pattern(tokens) do
    # Simple implementation - look for (qty unit) container pattern
    case find_paren_sequence(tokens) do
      {size_value, size_unit, container_type} ->
        %{
          size_value: size_value,
          size_unit: size_unit,
          container_type: container_type
        }
      nil -> nil
    end
  end

  defp find_paren_sequence(tokens) do
    # Find opening paren, then qty, unit, closing paren, container
    paren_start = Enum.find_index(tokens, &(&1.text == "("))

    if paren_start do
      rest = Enum.drop(tokens, paren_start + 1)

      with [%{label: :qty, text: qty_text} | rest] <- rest,
           [%{label: :unit, text: unit_text} | rest] <- rest,
           [%{text: ")"} | rest] <- rest,
           [%{label: :container, text: container_text} | _] <- rest do
        {parse_single_quantity(qty_text), normalize_unit(unit_text), container_text}
      else
        _ -> nil
      end
    else
      nil
    end
  end

  # Clean ingredient names (remove asterisks, extra whitespace, etc.)
  defp clean_ingredient_names(names) do
    names
    |> Enum.map(&clean_name/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp clean_name(name) do
    name
    |> String.replace(~r/\*+$/, "")  # Remove trailing asterisks
    |> String.replace(~r/^\*+/, "")  # Remove leading asterisks
    |> String.replace(~r/\s+/, " ")  # Normalize whitespace
    |> String.trim()
  end

  # Transform juice/zest patterns to extract derived ingredients
  # E.g., "1 lime, juiced" → "lime juice"
  #       "juice and zest of 1 lime" → ["lime juice", "lime zest"]
  defp transform_juice_zest_patterns(ingredient_names, preparations, tokens) do
    has_juiced = "juiced" in preparations
    has_zested = "zested" in preparations

    # Check for "juice of/from" or "zest of/from" patterns in tokens
    juice_zest_pattern = detect_juice_zest_of_pattern(tokens)

    cond do
      # Pattern: "juice and zest of X" or "zest + juice from X"
      juice_zest_pattern == :both ->
        # The ingredient name is the fruit/citrus - transform to both juice and zest
        # Filter out words that are part of the "juice/zest of" pattern, not the actual ingredient
        ingredient_names
        |> Enum.reject(&is_juice_zest_noise?/1)
        |> Enum.flat_map(fn name -> ["#{name} juice", "#{name} zest"] end)

      # Pattern: "juice of X" or "juice from X"
      juice_zest_pattern == :juice ->
        ingredient_names
        |> Enum.reject(&is_juice_zest_noise?/1)
        |> Enum.map(fn name -> "#{name} juice" end)

      # Pattern: "zest of X" or "zest from X"
      juice_zest_pattern == :zest ->
        ingredient_names
        |> Enum.reject(&is_juice_zest_noise?/1)
        |> Enum.map(fn name -> "#{name} zest" end)

      # Pattern: "X, juiced" or "X (juiced)" - with both juiced and zested
      has_juiced and has_zested ->
        Enum.flat_map(ingredient_names, &["#{&1} juice", "#{&1} zest"])

      # Pattern: "X, juiced" or "X (juiced)"
      has_juiced ->
        Enum.map(ingredient_names, &"#{&1} juice")

      # Pattern: "X, zested" or "X (zested)"
      has_zested ->
        Enum.map(ingredient_names, &"#{&1} zest")

      # No transformation needed
      true ->
        ingredient_names
    end
  end

  # Check if a name is just noise from "juice/zest of" patterns
  # E.g., "juice", "zest", "the", "zest of", "juice and zest" should be filtered
  defp is_juice_zest_noise?(name) do
    normalized = String.downcase(name)
    normalized in ["juice", "zest", "the", "zest of", "juice of",
                   "juice and zest", "zest and juice", "juice + zest", "zest + juice"] or
    String.starts_with?(normalized, "zest of") or
    String.starts_with?(normalized, "juice of") or
    String.starts_with?(normalized, "juice and") or
    String.starts_with?(normalized, "zest and")
  end

  # Detect "juice of", "zest of", "juice from", "zest from" patterns
  # Returns :juice, :zest, :both, or nil
  defp detect_juice_zest_of_pattern(tokens) do
    token_texts = Enum.map(tokens, & &1.text)
    text = Enum.join(token_texts, " ")

    has_juice_of = String.contains?(text, "juice of") or String.contains?(text, "juice from")
    has_zest_of = String.contains?(text, "zest of") or String.contains?(text, "zest from")

    # Also check for "juice and zest" or "zest + juice" patterns
    has_juice_and_zest = String.contains?(text, "juice and zest") or
                         String.contains?(text, "zest and juice") or
                         String.contains?(text, "juice + zest") or
                         String.contains?(text, "zest + juice")

    cond do
      has_juice_and_zest -> :both
      has_juice_of and has_zest_of -> :both
      has_juice_of -> :juice
      has_zest_of -> :zest
      true -> nil
    end
  end

  # Match ingredient name to canonical ingredient
  defp match_ingredient(name, lookup) do
    normalized = String.downcase(name) |> String.trim()

    case find_canonical_match(normalized, lookup) do
      {canonical_name, canonical_id, confidence} ->
        %{
          name: name,
          canonical_name: canonical_name,
          canonical_id: canonical_id,
          confidence: confidence
        }

      nil ->
        %{
          name: name,
          canonical_name: nil,
          canonical_id: nil,
          confidence: 0.5
        }
    end
  end

  # Find canonical match using various strategies
  defp find_canonical_match(name, lookup) do
    # Strategy 1: Exact match
    case Map.get(lookup, name) do
      {canonical_name, id} -> {canonical_name, id, 1.0}
      nil ->
        # Strategy 1b: Try singularized form
        singular = singularize_phrase(name)
        case if(singular != name, do: Map.get(lookup, singular)) do
          {canonical_name, id} -> {canonical_name, id, 0.98}
          _ -> try_partial_match(name, lookup)
        end
    end
  end

  # Try partial matching strategies
  defp try_partial_match(name, lookup) do
    words = String.split(name, " ")

    # Strategy 2: Remove leading adjectives (fresh, large, etc.)
    stripped = strip_leading_modifiers(words)
    case Map.get(lookup, stripped) do
      {canonical_name, id} -> {canonical_name, id, 0.95}
      nil ->
        # Strategy 2b: Try singularized stripped form
        singular_stripped = singularize_phrase(stripped)
        case if(singular_stripped != stripped, do: Map.get(lookup, singular_stripped)) do
          {canonical_name, id} -> {canonical_name, id, 0.93}
          _ -> try_shorter_matches(words, lookup)
        end
    end
  end

  @leading_modifiers ~w(fresh dried frozen canned raw cooked large small medium
                        extra-large whole ground light dark unsalted salted organic
                        ripe unripe hot cold warm thin thick fine coarse)

  defp strip_leading_modifiers(words) do
    words
    |> Enum.drop_while(&(String.downcase(&1) in @leading_modifiers))
    |> Enum.join(" ")
  end

  # Try progressively shorter versions
  defp try_shorter_matches(words, lookup) when length(words) > 1 do
    # Try removing first word
    shorter_front = words |> tl() |> Enum.join(" ")
    case Map.get(lookup, shorter_front) do
      {canonical_name, id} -> {canonical_name, id, 0.9}
      nil ->
        # Try removing last word
        shorter_back = words |> Enum.take(length(words) - 1) |> Enum.join(" ")
        case Map.get(lookup, shorter_back) do
          {canonical_name, id} -> {canonical_name, id, 0.9}
          nil -> try_shorter_matches(tl(words), lookup)
        end
    end
  end

  defp try_shorter_matches([single_word], lookup) do
    case Map.get(lookup, single_word) do
      {canonical_name, id} -> {canonical_name, id, 0.8}
      nil -> try_fuzzy_match(single_word, lookup)
    end
  end

  defp try_shorter_matches([], _lookup), do: nil

  # Singularize a multi-word phrase by singularizing the last word
  # "red peppers" -> "red pepper", "cherry tomatoes" -> "cherry tomato"
  defp singularize_phrase(phrase) do
    words = String.split(phrase, " ")

    case words do
      [] -> phrase
      [single] -> singularize(single)
      multiple ->
        last = List.last(multiple)
        rest = Enum.take(multiple, length(multiple) - 1)
        singular_last = singularize(last)
        Enum.join(rest ++ [singular_last], " ")
    end
  end

  # Words that naturally end in 's' and should not be singularized
  @no_singularize ~w(
    hummus couscous asparagus molasses cilantro
    jus floss glass grass moss
    Swiss swiss dress press
  )

  @doc """
  Attempts to singularize an English word.

  Uses conservative rules to avoid breaking words that naturally end in 's'.
  Returns the word unchanged if it's in the exception list or doesn't match
  any known plural pattern.
  """
  def singularize(word) do
    downcased = String.downcase(word)

    cond do
      # Don't singularize short words or words in exception list
      String.length(word) < 3 -> word
      downcased in @no_singularize -> word

      # -ves -> -f (leaves -> leaf, halves -> half, loaves -> loaf)
      String.ends_with?(downcased, "ves") ->
        String.slice(word, 0..-4//1) <> "f"

      # -ies -> -y (berries -> berry, anchovies -> anchovy)
      String.ends_with?(downcased, "ies") ->
        String.slice(word, 0..-4//1) <> "y"

      # -sses -> -ss (molasses stays, but grasses -> grass)
      String.ends_with?(downcased, "sses") ->
        word

      # -shes -> -sh (radishes -> radish)
      String.ends_with?(downcased, "shes") ->
        String.slice(word, 0..-3//1)

      # -ches -> -ch (peaches -> peach)
      String.ends_with?(downcased, "ches") ->
        String.slice(word, 0..-3//1)

      # -xes -> -x (boxes -> box)
      String.ends_with?(downcased, "xes") ->
        String.slice(word, 0..-3//1)

      # -zes -> -z (fizzes handled by -sses above)
      String.ends_with?(downcased, "zes") ->
        String.slice(word, 0..-3//1)

      # -toes -> -to (tomatoes -> tomato, potatoes -> potato)
      String.ends_with?(downcased, "toes") ->
        String.slice(word, 0..-3//1)

      # -oes -> -o (but keep heroes -> hero pattern)
      String.ends_with?(downcased, "oes") ->
        String.slice(word, 0..-3//1)

      # -s (general plural, but not -ss, -us)
      String.ends_with?(downcased, "s") and
        not String.ends_with?(downcased, "ss") and
        not String.ends_with?(downcased, "us") ->
        String.slice(word, 0..-2//1)

      true -> word
    end
  end

  # Conservative fuzzy matching
  defp try_fuzzy_match(name, lookup) do
    # Only try prefix matching for longer names
    if String.length(name) >= 4 do
      # Find canonical that starts with this name
      match = Enum.find(lookup, fn {key, _} ->
        String.starts_with?(key, name <> " ") or
        String.starts_with?(name, key <> " ")
      end)

      case match do
        {_key, {canonical_name, id}} -> {canonical_name, id, 0.7}
        nil -> nil
      end
    else
      nil
    end
  end
end
