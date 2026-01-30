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
  alias Controlcopypasta.Ingredients.SubParsers
  alias Controlcopypasta.Ingredients.ParseDiagnostics
  alias Controlcopypasta.Ingredients.PreStepGenerator

  @sub_parsers [
    SubParsers.RecipeReference,  # Check for recipe references first
    SubParsers.Garlic,
    SubParsers.Citrus,
    SubParsers.Egg
  ]

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
      :is_alternative,    # true if "or" pattern detected
      :choices,           # "such as X, Y, or Z" - specific options to choose from
      :recipe_reference,  # Reference to another recipe (sub-recipe)
      :diagnostics        # ParseDiagnostics struct when enabled
    ]

    @type recipe_reference :: %{
            type: :below | :above | :notes | :link | :inline,
            text: String.t() | nil,
            name: String.t() | nil,
            is_optional: boolean()
          }

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
            is_alternative: boolean(),
            choices: [ingredient_match()] | nil,
            recipe_reference: recipe_reference() | nil,
            diagnostics: ParseDiagnostics.t() | nil
          }
  end

  @doc """
  Parses an ingredient string into structured data.

  ## Options

  - `:lookup` - Pre-built ingredient lookup map (optional, will build if not provided)
  - `:diagnostics` - When true, captures detailed parsing diagnostics (default: false)

  ## Examples

      iex> TokenParser.parse("2 cups diced tomatoes, drained")
      %ParsedIngredient{
        original: "2 cups diced tomatoes, drained",
        quantity: 2.0,
        unit: "cup",
        ingredients: [%{name: "tomatoes", canonical_name: "tomato", ...}],
        preparations: ["diced", "drained"]
      }

      iex> TokenParser.parse("1 cup flour", diagnostics: true)
      %ParsedIngredient{
        ...
        diagnostics: %ParseDiagnostics{tokens: [...], parser_used: :standard, ...}
      }
  """
  def parse(text, opts \\ []) when is_binary(text) do
    start_time = System.monotonic_time(:microsecond)
    include_diagnostics = Keyword.get(opts, :diagnostics, false)

    # Preprocess text to normalize problematic patterns
    case preprocess_text(text) do
      :skip ->
        # Non-ingredient (equipment) - return empty result
        %ParsedIngredient{
          original: text,
          quantity: nil,
          quantity_min: nil,
          quantity_max: nil,
          unit: nil,
          container: nil,
          ingredients: [],
          primary_ingredient: nil,
          preparations: [],
          modifiers: [],
          storage_medium: nil,
          notes: [],
          is_alternative: false,
          choices: nil
        }

      preprocessed_text ->
        parse_preprocessed(preprocessed_text, text, opts, start_time, include_diagnostics)
    end
  end

  defp parse_preprocessed(preprocessed_text, original_text, opts, start_time, include_diagnostics) do
    tokens = Tokenizer.tokenize(preprocessed_text)
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)

    {result, parser_used} = case try_sub_parsers(tokens, original_text, lookup) do
      {:ok, parsed, parser_name} -> {parsed, parser_name}
      {:ok, parsed} -> {parsed, :sub_parser}
      :skip -> {parse_standard(tokens, original_text, lookup), :standard}
    end

    if include_diagnostics do
      diagnostics = build_diagnostics(tokens, parser_used, result, start_time)
      %{result | diagnostics: diagnostics}
    else
      result
    end
  end

  # Equipment words that indicate non-ingredient items
  @equipment_words ~w(
    thermometer thermometers mill mills pan pans cutter cutters skewer skewers
    cheesecloth mortar pestle grater graters peeler peelers strainer strainers
    colander colanders sieve sieves whisk whisks spatula spatulas ladle ladles
    tongs mandoline mandolines zester zesters reamer reamers juicer juicers
    blender blenders processor processors mixer mixers fryer fryers
    torch torches brush brushes rack racks sheet sheets baking\ sheet
    parchment springform bundt muffin\ tin loaf\ pan pie\ dish casserole
    dutch\ oven roasting\ pan sheet\ pan air\ fryer instant\ pot
  )

  # Preprocess ingredient text to normalize problematic patterns
  # Returns :skip for non-ingredients, or the preprocessed text
  defp preprocess_text(text) do
    cond do
      # Filter out kitchen equipment
      is_equipment?(text) -> :skip

      true ->
        text
        |> normalize_slash_measurements()
        |> normalize_gram_measurements()
        |> normalize_stick_butter()
        |> normalize_ginger_size()
    end
  end

  # Detect kitchen equipment (starts with "A " or "An " followed by equipment)
  defp is_equipment?(text) do
    normalized = String.downcase(text)

    # Pattern 1: Starts with "a" or "an" followed by equipment
    starts_with_article = Regex.match?(~r/^an?\s+/i, text)

    if starts_with_article do
      # Check if any equipment word is in the text
      Enum.any?(@equipment_words, fn word ->
        String.contains?(normalized, word)
      end)
    else
      false
    end
  end

  # Normalize slash measurements: "1/2 cup/100 grams sugar" -> "1/2 cup sugar"
  # Pattern: X unit/Y grams -> X unit
  defp normalize_slash_measurements(text) do
    # Match: unit/number followed by grams/g
    # E.g., "cup/100 grams", "cups/256 grams", "cup/100g"
    text
    |> String.replace(~r/(\b(?:cups?|tablespoons?|tbsp?|teaspoons?|tsp)\s*)\/\s*\d+\s*(?:grams?|g)\b/i, "\\1")
  end

  # Normalize gram measurements in parentheses: "1 cup (200g) flour" -> "1 cup flour"
  # Also handles: "(200g)", "(200 g)", "(200 grams)"
  defp normalize_gram_measurements(text) do
    text
    |> String.replace(~r/\(\s*\d+(?:\.\d+)?\s*(?:g|grams?)\s*\)/i, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Normalize stick butter notation
  # "2 sticks (1 cup) salted butter" -> "1 cup salted butter"
  # "1/2 cup (1 stick) unsalted butter" -> "1/2 cup unsalted butter"
  # "1 stick (8 tablespoons) salted butter" -> "8 tablespoons salted butter"
  defp normalize_stick_butter(text) do
    if String.contains?(String.downcase(text), "butter") and
       String.contains?(String.downcase(text), "stick") do

      text
      # Pattern: "X sticks (Y unit)" -> "Y unit"
      |> String.replace(~r/\d+\s*(?:1\/2\s+)?sticks?\s*\(([^)]+)\)/i, "\\1")
      # Pattern: "(X stick)" or "(X sticks)" -> remove
      |> String.replace(~r/\(\s*\d*\s*(?:1\/2\s+)?sticks?\s*\)/i, "")
      # Pattern: "X stick" at start without parenthetical -> "X stick" (keep as unit)
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    else
      text
    end
  end

  # Normalize ginger size notation
  # "1 1" piece ginger" -> "1 piece ginger" (preserve quantity, normalize unit)
  # "1 2-inch piece ginger" -> "1 piece ginger"
  # "1 inch piece fresh ginger" -> "1 piece fresh ginger"
  defp normalize_ginger_size(text) do
    if String.contains?(String.downcase(text), "ginger") and
       (String.contains?(String.downcase(text), "inch") or
        String.contains?(text, "\"") or
        String.contains?(String.downcase(text), "piece")) do

      text
      # Pattern: X (size)" piece -> X piece (remove the size quote notation)
      |> String.replace(~r/(\d+)\s+\d+(?:\/\d+)?["″]\s*piece/i, "\\1 piece")
      # Pattern: X Y-inch piece -> X piece
      |> String.replace(~r/(\d+)\s+\d+(?:\/\d+)?(?:-|\s)?inch(?:es)?\s*piece/i, "\\1 piece")
      # Pattern: X inch piece -> X piece
      |> String.replace(~r/(\d+)\s*(?:-|\s)?inch(?:es)?\s*piece/i, "\\1 piece")
      # Pattern: X-inch piece without leading qty -> 1 piece
      |> String.replace(~r/^\s*\d+(?:\/\d+)?(?:-|\s)?inch(?:es)?\s*piece/i, "1 piece")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    else
      text
    end
  end

  defp build_diagnostics(tokens, parser_used, result, start_time) do
    parse_time = System.monotonic_time(:microsecond) - start_time

    # Determine match strategy from confidence
    match_strategy = if result.primary_ingredient do
      case result.primary_ingredient.confidence do
        1.0 -> :exact
        c when c >= 0.95 -> :partial
        c when c >= 0.9 -> :stripped
        c when c >= 0.8 -> :shortened
        _ -> :fuzzy
      end
    end

    %ParseDiagnostics{
      tokens: tokens,
      token_string: Tokenizer.format(tokens),
      parser_used: parser_used,
      match_candidates: build_match_candidates(result),
      selected_match: summarize_selected_match(result.primary_ingredient),
      match_strategy: match_strategy,
      warnings: ParseDiagnostics.detect_warnings(tokens, result),
      parse_time_us: parse_time
    }
  end

  defp build_match_candidates(result) do
    # For now, just return the matched ingredients as candidates
    # A more sophisticated implementation could track all candidates tried
    result.ingredients
    |> Enum.map(fn ing ->
      %{
        name: ing.name,
        canonical_name: ing.canonical_name,
        confidence: ing.confidence,
        strategy: confidence_to_strategy(ing.confidence)
      }
    end)
  end

  defp confidence_to_strategy(confidence) do
    cond do
      confidence >= 1.0 -> :exact
      confidence >= 0.95 -> :partial
      confidence >= 0.9 -> :stripped
      confidence >= 0.8 -> :shortened
      true -> :fuzzy
    end
  end

  defp summarize_selected_match(nil), do: nil
  defp summarize_selected_match(primary) do
    %{
      name: primary.name,
      canonical_name: primary.canonical_name,
      confidence: primary.confidence
    }
  end

  defp try_sub_parsers(tokens, original, lookup) do
    Enum.find_value(@sub_parsers, :skip, fn parser ->
      if parser.match?(tokens) do
        case parser.parse(tokens, original, lookup) do
          {:ok, parsed} ->
            # Extract parser name from module (e.g., SubParsers.Garlic -> :garlic)
            parser_name = parser
              |> Module.split()
              |> List.last()
              |> String.downcase()
              |> String.to_atom()
            {:ok, parsed, parser_name}
          :skip -> nil
        end
      end
    end)
  end

  @doc false
  def parse_standard(tokens, original, lookup) do
    analysis = Tokenizer.analyze(tokens)

    # Parse quantity (handle ranges)
    {quantity, quantity_min, quantity_max} = parse_quantity(analysis.quantity)

    # Parse unit
    unit = normalize_unit(analysis.unit)

    # Extract container info if present
    container = extract_container(tokens)

    # Get ingredient names, applying juice/zest transformations
    raw_ingredient_names = clean_ingredient_names(analysis.ingredients)
    ingredient_names = transform_juice_zest_patterns(raw_ingredient_names, analysis.preparations, tokens)
    matched_ingredients = Enum.map(ingredient_names, &match_ingredient(&1, lookup))

    # Get primary ingredient (first one)
    primary = List.first(matched_ingredients)

    # Extract choices from "such as X, Y, or Z" patterns
    {choices, extra_preparations} = extract_choices(tokens, lookup)

    # Combine preparations from analysis with any found after choices
    all_preparations = (analysis.preparations ++ extra_preparations) |> Enum.uniq()

    %ParsedIngredient{
      original: original,
      quantity: quantity,
      quantity_min: quantity_min,
      quantity_max: quantity_max,
      unit: unit,
      container: container,
      ingredients: matched_ingredients,
      primary_ingredient: primary,
      preparations: all_preparations,
      modifiers: analysis.modifiers,
      storage_medium: analysis.storage_medium,
      notes: [],
      is_alternative: analysis.has_alternatives,
      choices: choices
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
      container = %{
        "size_value" => parsed.container.size_value,
        "size_unit" => parsed.container.size_unit,
        "container_type" => parsed.container.container_type
      }
      Map.put(base, "container", container)
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
    base = if parsed.is_alternative and length(parsed.ingredients) > 1 do
      alternatives = parsed.ingredients
        |> Enum.drop(1)
        |> Enum.map(fn ing ->
          %{
            "name" => ing.name,
            "canonical_name" => ing.canonical_name,
            "canonical_id" => ing.canonical_id
          }
        end)
      base
      |> Map.put("alternatives", alternatives)
      |> Map.put("is_alternative", true)
    else
      base
    end

    # Add recipe reference if present
    base = if parsed.recipe_reference do
      ref = parsed.recipe_reference
      Map.put(base, "recipe_reference", %{
        "type" => Atom.to_string(ref.type),
        "text" => ref.text,
        "name" => ref.name,
        "is_optional" => ref.is_optional
      })
    else
      base
    end

    # Add choices if present (from "such as X, Y, or Z" patterns)
    base = if parsed.choices && parsed.choices != [] do
      choices = Enum.map(parsed.choices, fn choice ->
        %{
          "name" => choice.name,
          "canonical_name" => choice.canonical_name,
          "canonical_id" => choice.canonical_id
        }
      end)
      Map.put(base, "choices", choices)
    else
      base
    end

    # Add pre_steps generated from preparations
    pre_steps = PreStepGenerator.generate_pre_steps(parsed)
    base = if pre_steps != [] do
      Map.put(base, "pre_steps", Enum.map(pre_steps, &PreStepGenerator.to_map/1))
    else
      base
    end

    # Add diagnostics if present (prefixed with _ to indicate internal/debug)
    if parsed.diagnostics do
      Map.put(base, "_diagnostics", ParseDiagnostics.to_map(parsed.diagnostics))
    else
      base
    end
  end

  @doc false
  def parse_quantity([]), do: {nil, nil, nil}
  def parse_quantity(qty_list) do
    # Find if any quantity token contains a range (e.g., "1-2")
    range_token = Enum.find(qty_list, fn qty_str ->
      String.contains?(qty_str, "-") and not String.starts_with?(qty_str, "-")
    end)

    case range_token do
      nil ->
        # No range - sum all quantities (handles compound like "1 1/2" = 1.5)
        total = qty_list
          |> Enum.map(&parse_single_quantity/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.sum()
        total = if total == 0, do: nil, else: total
        {total, total, total}

      range_str ->
        # Has range - parse the range, then add any additional fractions to upper bound
        # This handles "1-1 1/2" = range from 1 to 1.5
        case String.split(range_str, "-", parts: 2) do
          [low, high] ->
            low_val = parse_single_quantity(low)
            high_val = parse_single_quantity(high)

            # Get any additional quantities (fractions) after the range token
            # For "1-1 1/2", qty_list is ["1-1", "1/2"], so we add "1/2" to the upper bound
            idx = Enum.find_index(qty_list, &(&1 == range_str))
            additional = qty_list
              |> Enum.drop(idx + 1)
              |> Enum.map(&parse_single_quantity/1)
              |> Enum.reject(&is_nil/1)

            high_val = if additional != [], do: high_val + Enum.sum(additional), else: high_val
            avg = if low_val && high_val, do: (low_val + high_val) / 2, else: low_val || high_val
            {avg, low_val, high_val}

          _ ->
            val = parse_single_quantity(range_str)
            {val, val, val}
        end
    end
  end

  @doc false
  def parse_single_quantity(str) do
    str = String.trim(str)
    cond do
      # Written number: "one", "two", etc.
      written_val = Tokenizer.written_number_value(str) ->
        written_val * 1.0

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
    "sheets" => "sheet", "sheet" => "sheet",
    "leaves" => "leaf", "leaf" => "leaf",
    "pinches" => "pinch", "pinch" => "pinch",
    "dashes" => "dash", "dash" => "dash",
    "cans" => "can", "can" => "can",
    "jars" => "jar", "jar" => "jar",
    "bottles" => "bottle", "bottle" => "bottle",
    "packages" => "package", "package" => "package", "pkg" => "package",
    "bags" => "bag", "bag" => "bag",
    "boxes" => "box", "box" => "box"
  }

  @doc false
  def normalize_unit(nil), do: nil
  def normalize_unit(unit) do
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
    # Try multiple patterns in order of specificity
    find_paren_sequence(tokens) ||
      find_size_container_pattern(tokens) ||
      find_qty_container_pattern(tokens)
  end

  # Pattern 1: (qty unit) container - e.g., "(14 oz) can"
  defp find_paren_sequence(tokens) do
    paren_start = Enum.find_index(tokens, &(&1.text == "("))

    if paren_start do
      rest = Enum.drop(tokens, paren_start + 1)

      with [%{label: :qty, text: qty_text} | rest] <- rest,
           [%{label: :unit, text: unit_text} | rest] <- rest,
           [%{text: ")"} | rest] <- rest,
           [%{label: :container, text: container_text} | _] <- rest do
        %{
          size_value: parse_single_quantity(qty_text),
          size_unit: normalize_unit(unit_text),
          container_type: container_text
        }
      else
        _ -> nil
      end
    else
      nil
    end
  end

  # Pattern 2: size container - e.g., "15-ounce can", "14-oz jar"
  defp find_size_container_pattern(tokens) do
    # Find :size token followed by :container token
    tokens
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn
      [%{label: :size, text: size_text}, %{label: :container, text: container_text}] ->
        case parse_size_string(size_text) do
          {value, unit} ->
            %{
              size_value: value,
              size_unit: unit,
              container_type: container_text
            }
          nil -> nil
        end
      _ -> nil
    end)
  end

  # Pattern 3: qty container - e.g., "2 cans", "1 jar" (no size specified)
  defp find_qty_container_pattern(tokens) do
    # Find :qty token followed by :container token
    tokens
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn
      [%{label: :qty, text: _qty_text}, %{label: :container, text: container_text}] ->
        %{
          size_value: nil,
          size_unit: nil,
          container_type: container_text
        }
      _ -> nil
    end)
  end

  # Parse size strings like "15-ounce", "14-oz" into {value, unit}
  defp parse_size_string(size_text) do
    case Regex.run(~r/^(\d+(?:[.,]\d+)?)-?(oz|ounce|ounces|g|gram|grams|ml|l)\.?$/i, size_text) do
      [_, value_str, unit] ->
        case Float.parse(value_str) do
          {value, _} -> {value, normalize_unit(unit)}
          :error -> nil
        end
      _ -> nil
    end
  end

  # Common preparation words that signal end of choices
  @prep_indicators ~w(
    scaled gutted cleaned peeled minced diced chopped sliced julienned
    grated shredded crushed mashed beaten whisked melted softened
    toasted roasted grilled baked fried sauteed braised steamed
    drained rinsed soaked marinated seasoned trimmed deboned
    thawed frozen chilled warmed heated cooled halved quartered
    cubed cut divided separated packed pressed sifted strained
  )

  # Extract choices from "such as X, Y, or Z" patterns
  # Returns {choices, preparations_found_after_choices}
  defp extract_choices(tokens, lookup) do
    # Find the :example_intro token (e.g., "such", "preferably")
    example_idx = Enum.find_index(tokens, &(&1.label == :example_intro))

    if example_idx do
      # Get tokens after the example_intro
      after_intro = Enum.drop(tokens, example_idx + 1)

      # Skip "as" if present (for "such as")
      after_intro = case after_intro do
        [%{text: "as"} | rest] -> rest
        other -> other
      end

      # Extract choices and preparations
      {choice_names, prep_names} = parse_choices_and_preps(after_intro)

      # Match choices to canonical ingredients
      matched_choices = choice_names
        |> Enum.map(&match_ingredient(&1, lookup))
        |> Enum.reject(&is_nil/1)

      choices = if matched_choices == [], do: nil, else: matched_choices

      {choices, prep_names}
    else
      {nil, []}
    end
  end

  # Parse tokens into choice names and preparation names
  # Choices are words separated by comma/or until we hit a prep indicator
  defp parse_choices_and_preps(tokens) do
    parse_choices_and_preps(tokens, [], [], false)
  end

  defp parse_choices_and_preps([], current_choice, choices, _in_preps) do
    # End of tokens - finalize
    choices = finalize_choice(current_choice, choices)
    {Enum.reverse(choices), []}
  end

  defp parse_choices_and_preps([token | rest], current_choice, choices, in_preps) do
    text = String.downcase(token.text)

    cond do
      # Already in prep section - collect preps
      in_preps ->
        case token.label do
          :word ->
            {Enum.reverse(choices), collect_preps([token | rest])}
          :conj ->
            # "and" in prep section continues preps
            parse_choices_and_preps(rest, [], choices, true)
          _ ->
            parse_choices_and_preps(rest, [], choices, true)
        end

      # Comma followed by prep indicator - switch to prep mode
      token.label == :punct and token.text == "," ->
        # Check if next word is a prep indicator
        next_word = Enum.find(rest, &(&1.label == :word))
        if next_word && String.downcase(next_word.text) in @prep_indicators do
          choices = finalize_choice(current_choice, choices)
          {Enum.reverse(choices), collect_preps(rest)}
        else
          # Just a comma between choices
          choices = finalize_choice(current_choice, choices)
          parse_choices_and_preps(rest, [], choices, false)
        end

      # Conjunction (or, and) - finalize current choice
      token.label == :conj ->
        choices = finalize_choice(current_choice, choices)
        parse_choices_and_preps(rest, [], choices, false)

      # Word token - could be choice or prep
      token.label == :word ->
        if text in @prep_indicators do
          # This is a prep - finalize choices and collect preps
          choices = finalize_choice(current_choice, choices)
          {Enum.reverse(choices), collect_preps([token | rest])}
        else
          # Add to current choice
          parse_choices_and_preps(rest, [token.text | current_choice], choices, false)
        end

      # Other tokens - skip
      true ->
        parse_choices_and_preps(rest, current_choice, choices, false)
    end
  end

  defp finalize_choice([], choices), do: choices
  defp finalize_choice(words, choices) do
    name = words |> Enum.reverse() |> Enum.join(" ") |> String.trim()
    if name == "", do: choices, else: [name | choices]
  end

  # Collect prep words from remaining tokens
  defp collect_preps(tokens) do
    tokens
    |> Enum.filter(&(&1.label == :word))
    |> Enum.map(&String.downcase(&1.text))
    |> Enum.filter(&(&1 in @prep_indicators))
  end

  @ingredient_stop_words ~w(
    with into from above below use sub well off dry fire cool
    about generous divided whole preferred natural if
    inch inches slices pieces sprigs ends chunks chips
    dutch-process warmed heated cooled reserved broken
    crusts cubed shaved pressed packed medium scoops
    lumpy soaked overnight mild-flavored cut you
    inch\ slices cut\ into butt fat woody fronds
    deboned butterflied spatchcocked peeling any color
    temp room gluten\ free needed packet recipe
  )

  # Clean ingredient names (remove asterisks, extra whitespace, stop words, etc.)
  defp clean_ingredient_names(names) do
    names
    |> Enum.map(&clean_name/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.reject(&ingredient_stop_word?/1)
  end

  defp ingredient_stop_word?(name) do
    String.downcase(name) in @ingredient_stop_words
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
  # E.g., "juice", "zest", "juice from", "fresh juice from", "lemon zest from" should be filtered
  defp is_juice_zest_noise?(name) do
    normalized = String.downcase(name)
    words = String.split(normalized)

    "juice" in words or "zest" in words or
      Enum.all?(words, &(&1 in ~w(the from of and about fresh freshly squeezed)))
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

  @doc false
  def match_ingredient(name, lookup) do
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
