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
  alias Controlcopypasta.Ingredients.ReferenceData.Units
  alias Controlcopypasta.Ingredients.Detection.EquipmentDetector
  alias Controlcopypasta.Ingredients.Parsing.{Singularizer, QuantityParser}
  alias Controlcopypasta.Ingredients.Matching.Matcher

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

  # Preprocess ingredient text to normalize problematic patterns
  # Returns :skip for non-ingredients, or the preprocessed text
  defp preprocess_text(text) do
    cond do
      # Filter out kitchen equipment (using centralized detector)
      EquipmentDetector.is_equipment?(text) -> :skip

      # Filter out section headers (FILLING, For the pastry:, etc.)
      is_section_header?(text) -> :skip

      # "Salt and pepper" / "Kosher salt and freshly ground black pepper, to taste" - skip
      Regex.match?(~r/^\s*(?:kosher\s+|sea\s+)?salt\s+and\s+(?:freshly\s+ground\s+)?(?:black\s+)?pepper\b/i, text) -> :skip

      true ->
        text
        |> strip_leading_optional()
        |> normalize_smart_quotes()
        |> normalize_british_spelling()
        |> normalize_to_range()
        |> normalize_slash_measurements()
        |> normalize_gram_measurements()
        |> normalize_parenthetical_notes()
        |> normalize_stick_butter()
        |> normalize_ginger_size()
        |> normalize_each_and_pattern()
        |> normalize_british_x_format()
        |> normalize_dual_measurements()
        |> normalize_semicolon_notes()
        |> strip_trailing_flavor_notes()
        |> normalize_hard_boiled()
        |> normalize_handful()
        |> strip_heaped_modifier()
        |> normalize_multi_or_adjective()
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
        String.contains?(String.downcase(text), "piece") or
        Regex.match?(~r/\d+\s*cm\b/i, text) or
        String.contains?(String.downcase(text), "thumb")) do

      text
      # Pattern: X (size") piece -> X piece (with parenthesized inch notation)
      |> String.replace(~r/(\d+)\s*\(\s*\d+(?:\/\d+)?["″]\s*\)\s*piece/i, "\\1 piece")
      # Pattern: X size" piece -> X piece (without parentheses)
      |> String.replace(~r/(\d+)\s+\d+(?:\/\d+)?["″]\s*piece/i, "\\1 piece")
      # Pattern: X Y-inch piece -> X piece
      |> String.replace(~r/(\d+)\s+\d+(?:\/\d+)?(?:-|\s)?inch(?:es)?\s*piece/i, "\\1 piece")
      # Pattern: X inch piece -> X piece
      |> String.replace(~r/(\d+)\s*(?:-|\s)?inch(?:es)?\s*piece/i, "\\1 piece")
      # Pattern: X-inch piece without leading qty -> 1 piece
      |> String.replace(~r/^\s*\d+(?:\/\d+)?(?:-|\s)?inch(?:es)?\s*piece/i, "1 piece")
      # Pattern: Xcm piece -> 1 piece (metric size notation)
      |> String.replace(~r/^\s*\d+(?:\.\d+)?\s*cm\s+piece\s+(?:of\s+)?/i, "1 piece ")
      # Pattern: thumb-sized piece -> 1 piece
      |> String.replace(~r/^\s*(?:a\s+)?thumb[- ]?sized\s+piece\s+(?:of\s+)?/i, "1 piece ")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
    else
      text
    end
  end

  # Strip leading "optional:" or "optional -" prefix
  # "optional: 1/4 teaspoon cayenne" -> "1/4 teaspoon cayenne"
  defp strip_leading_optional(text) do
    text
    |> String.replace(~r/^\s*optional\s*[:–\-]\s*/i, "")
  end

  # Normalize smart quotes and special whitespace to regular ASCII equivalents
  # "1 (1\u201D) piece" -> "1 (1\") piece"
  # Non-breaking spaces (\u00A0) -> regular spaces
  @unicode_fractions %{
    "½" => "1/2", "⅓" => "1/3", "⅔" => "2/3",
    "¼" => "1/4", "¾" => "3/4",
    "⅕" => "1/5", "⅖" => "2/5", "⅗" => "3/5", "⅘" => "4/5",
    "⅙" => "1/6", "⅚" => "5/6",
    "⅛" => "1/8", "⅜" => "3/8", "⅝" => "5/8", "⅞" => "7/8"
  }

  defp normalize_smart_quotes(text) do
    text
    |> String.replace("\u00A0", " ")   # non-breaking space
    |> String.replace("\u2044", "/")   # unicode fraction slash
    |> String.replace("\u201C", "\"")  # left double smart quote
    |> String.replace("\u201D", "\"")  # right double smart quote
    |> String.replace("\u2018", "'")   # left single smart quote
    |> String.replace("\u2019", "'")   # right single smart quote
    |> String.replace("\u2033", "\"")  # double prime
    |> normalize_unicode_fraction_chars()
  end

  # Convert unicode fraction characters (½ ¼ ¾ etc.) to ASCII fractions early
  # so downstream regexes can work with them. Adds space when preceded by digit: "3½" -> "3 1/2"
  defp normalize_unicode_fraction_chars(text) do
    Enum.reduce(@unicode_fractions, text, fn {char, replacement}, acc ->
      acc
      |> String.replace(~r/(\d)#{Regex.escape(char)}/, "\\1 #{replacement}")
      |> String.replace(char, replacement)
    end)
  end

  # Remove parenthetical notes that contain only descriptive text (not measurements)
  # Handles double parens: "((fine or medium grind))" -> ""
  # Handles notes: "(store bought or homemade)" -> ""
  # Handles conversions: "(about 2 tablespoons)" -> ""
  # Handles per-container sizes: "(15 ounces each)" -> convert to container pattern
  # Preserves measurement parens: "(14 oz) can" stays
  defp normalize_parenthetical_notes(text) do
    text
    # Double parens first: "((anything))" -> ""
    |> String.replace(~r/\(\((?:(?!\)\)).)*\)\)/, "")
    # "(15 ounces each)" -> "(15-ounce)" to create a size token for container extraction
    |> String.replace(~r/\(\s*(\d+(?:\.\d+)?)\s*(?:ounces?|oz)\s+each\s*\)/i, "(\\1-ounce)")
    # "(15oz)" -> "(15-oz)" insert hyphen between digits and unit for tokenizer
    |> String.replace(~r/\((\d+(?:\.\d+)?)(oz|ounces?|g|grams?|ml|l)\)/i, "(\\1-\\2)")
    # "1 can (28 oz crushed tomatoes)" -> "1 (28-oz) can crushed tomatoes"
    # Rearrange: container (size unit ingredients) -> (size-unit) container ingredients
    |> String.replace(~r/(\d+)\s+(cans?|tins?|jars?|bottles?|cartons?)\s+\(\s*(\d+(?:\.\d+)?)\s*(oz|ounces?|g|grams?|ml|l)\s+/i, "\\1 (\\3-\\4) \\2 ")
    # "(10 ounces/283 grams)" weight conversions after standard units (cups, tbsp, etc.)
    # Only strip when preceded by a standard measurement, NOT after "can/tin" (which need the size)
    # Number pattern allows fractions: "8 3/4", "1.5", "10"
    # Allow modifiers like "packed" between unit and parens: "1 cup packed (7 oz/198g)"
    |> String.replace(~r/(\d+(?:\s+\d+\/\d+)?\s+(?:cups?|tablespoons?|tbsp|teaspoons?|tsp)(?:\s+packed)?)\s*\(\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:ounces?|oz)\s*\/\s*\d+\s*(?:grams?|g)\s*\)/i, "\\1")
    # "(283 grams/10 ounces)" metric-first variant, same restriction
    |> String.replace(~r/(\d+(?:\s+\d+\/\d+)?\s+(?:cups?|tablespoons?|tbsp|teaspoons?|tsp)(?:\s+packed)?)\s*\(\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:grams?|g)\s*\/\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:ounces?|oz)\s*\)/i, "\\1")
    # Parens containing "store bought", "homemade", "or sub", "see note", "if needed"
    |> String.replace(~r/\(\s*(?:store\s*bought|homemade|or\s+sub|see\s+note|if\s+needed|approximately|about\s+\d)[^)]*\)/i, "")
    # Parens starting with "or" suggesting alternatives we don't parse: "(or other protein)"
    |> String.replace(~r/\(\s*or\s+(?:other|sub|substitute|[\d])[^)]*\)/i, "")
    # Parens containing recipe instructions: "(no curry powder // ...)"
    |> String.replace(~r/\(\s*no\s+[^)]*\)/i, "")
    # Parens with just descriptive text after main content: "(such as ...)" already handled by choices
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Normalize "1/2 teaspoon each onion powder and garlic powder"
  # Split into just "onion powder" (the "each X and Y" means X amount of each)
  # We take the first ingredient since the parser handles one ingredient per line
  defp normalize_each_and_pattern(text) do
    # Pattern: "each X and Y" where X and Y are ingredient names after a unit
    case Regex.run(~r/^(.+?\b(?:teaspoons?|tsp|tablespoons?|tbsp|cups?|oz|ounces?|pounds?|lb)\s+)each\s+(.+?)\s+and\s+(.+)$/i, text) do
      [_, prefix, first_ingredient, _second_ingredient] ->
        # Return just the first ingredient (both get the same amount)
        String.trim(prefix <> first_ingredient)
      _ ->
        text
    end
  end

  # Normalize dual measurements like "8 ounces (1 cup; 225g)" or "1 cup/8 ounces (226 grams)"
  # Takes the first measurement and strips the rest
  defp normalize_dual_measurements(text) do
    text
    # "200ml/7fl oz double cream" -> "7 fl oz double cream" (metric-first dual: keep imperial)
    # Unicode fractions already normalized: "100ml/3½fl oz" -> "100ml/3 1/2fl oz"
    |> String.replace(~r/^\s*\d+(?:\.\d+)?\s*(?:ml|g|kg|l)\s*\/\s*(\d+(?:\s+\d+\/\d+)?(?:\.\d+)?)\s*(fl\s*oz|fluid\s+ounces?|ounces?|oz|cups?|tablespoons?|tbsp|teaspoons?|tsp)\b/i, "\\1 \\2")
    # "8.5 fluid ounces/250 ml water" -> "8.5 fluid ounces water"
    |> String.replace(~r/(\b\d+(?:\.\d+)?\s+(?:fluid\s+)?(?:ounces?|oz|cups?|tablespoons?|tbsp|teaspoons?|tsp))\s*\/\s*\d+(?:\.\d+)?\s*(?:ml|g|l|kg)\b/i, "\\1")
    # "1 cup/8 ounces (226 grams) ricotta" -> "1 cup ricotta"
    |> String.replace(~r/(\b\d+(?:[\/\.]\d+)?\s+(?:cups?|c)\s*)\/\s*\d+\s+(?:ounces?|oz)\b/i, "\\1")
    # "8 ounces (1 cup; 225g) X" -> "8 ounces X" (strip parenthetical with cup;g alternative)
    |> String.replace(~r/\(\s*\d+(?:[\/\.]\d+)?\s+(?:cups?|c)\s*;\s*\d+(?:\.\d+)?\s*(?:g|grams?)\s*\)/i, "")
    # "7/8 cup to 1 cup (198g to 227g)" → "7/8 cup" (strip range and gram parens)
    |> String.replace(~r/(\b\d+(?:\/\d+)?\s+(?:cups?|c))\s+to\s+\d+(?:\/\d+)?\s+(?:cups?|c)\s*\([^)]*\)/i, "\\1")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Strip everything after a semicolon (usually conversion notes)
  # "1/2 tsp Diamond Crystal kosher salt; for table salt, use half as much" -> "1/2 tsp Diamond Crystal kosher salt"
  defp normalize_semicolon_notes(text) do
    case String.split(text, ";", parts: 2) do
      [before, _after] -> String.trim(before)
      _ -> text
    end
  end

  # Normalize "X to Y" quantity ranges to dash notation
  # "3 to 4 green onions" -> "3-4 green onions"
  # "1 to 2 teaspoons sesame oil" -> "1-2 teaspoons sesame oil"
  # Only matches when X and Y are numbers at the beginning of the string
  defp normalize_to_range(text) do
    text
    |> String.replace(~r/^(\d+(?:\/\d+)?)\s+to\s+(\d+(?:\/\d+)?)\b/i, "\\1-\\2")
  end

  # Strip trailing "for X flavor" or "for X curry flavor!" noise
  # "cayenne for spicy curry flavor!" -> "cayenne"
  # Also strip "of choice" and "of your choice"
  defp strip_trailing_flavor_notes(text) do
    text
    |> String.replace(~r/\s+for\s+(?:spicy|mild|extra|a)\s+.*$/i, "")
    |> String.replace(~r/\s+of\s+(?:your\s+)?choice\b/i, "")
    # "crusty bread to serve" -> "crusty bread", "ice cream to serve (optional)" -> "ice cream"
    |> String.replace(~r/,?\s+to\s+serve\b.*$/i, "")
    # "icing sugar to dust" -> "icing sugar"
    |> String.replace(~r/,?\s+to\s+dust\b.*$/i, "")
    # "oil for deep-frying" -> "oil", "vegetable oil for frying" -> "vegetable oil"
    |> String.replace(~r/,?\s+for\s+(?:deep[- ]?)?frying\b.*$/i, "")
  end

  # Normalize "hard boiled eggs" -> "hard-boiled eggs" so tokenizer sees it as a prep
  # Also handle "soft boiled"
  defp normalize_hard_boiled(text) do
    text
    |> String.replace(~r/\bhard\s+boiled\b/i, "hard-boiled")
    |> String.replace(~r/\bsoft\s+boiled\b/i, "soft-boiled")
  end

  # Normalize "handful" to a small quantity
  # "handful chopped fresh parsley" -> "1/4 cup chopped fresh parsley"
  defp normalize_handful(text) do
    text
    |> String.replace(~r/^\s*(?:a\s+)?handful(?:\s+of)?\s+/i, "1/4 cup ")
    # "a few sprigs of fresh thyme" -> "2 sprigs fresh thyme"
    |> String.replace(~r/^\s*(?:a\s+)?few\s+sprigs?\s+(?:of\s+)?/i, "2 sprigs ")
    # "a sprig of thyme" -> "1 sprig thyme"
    |> String.replace(~r/^\s*a\s+sprig\s+(?:of\s+)?/i, "1 sprig ")
  end

  # Strip "heaped" modifier before measurement units
  # "1 heaped tablespoon flour" -> "1 tablespoon flour"
  defp strip_heaped_modifier(text) do
    String.replace(text, ~r/\bheaped\s+/i, "")
  end

  # Normalize British spelling variants to American English
  # "chilli" -> "chili", "chillies" -> "chilies", "coriander" stays (handled by aliases)
  defp normalize_british_spelling(text) do
    text
    |> String.replace(~r/\bchillies\b/i, "chilies")
    |> String.replace(~r/\bchilli\b/i, "chili")
  end

  # Detect section headers that aren't ingredients
  # Returns true for: ALL CAPS single words, "For the X:", "Dry ingredients:", advertising, etc.
  defp is_section_header?(text) do
    trimmed = String.trim(text)
    cond do
      # Blank or whitespace-only
      trimmed == "" -> true
      # Ends with colon (section labels): "For the pastry:", "Dry ingredients:", "FILLING:"
      String.ends_with?(trimmed, ":") -> true
      # ALL CAPS single or two words with no digits: "FILLING", "TO SERVE", "GARNISH"
      Regex.match?(~r/^[A-Z][A-Z\s]{0,30}$/, trimmed) and not Regex.match?(~r/\d/, trimmed) -> true
      # Advertising / non-ingredient lines
      Regex.match?(~r/^\s*(?:SHOP|BUY|ORDER|SPONSORED|ADVERTISEMENT|AD)\b/i, trimmed) -> true
      true -> false
    end
  end

  # Normalize British "X x Yg tin/can of Z" format
  # "1 x 400g tin of chopped tomatoes" -> "1 (400-g) tin chopped tomatoes"
  # "2 x 400g tins of chickpeas" -> "2 (400-g) tins chickpeas"
  defp normalize_british_x_format(text) do
    text
    |> String.replace(
      ~r/^(\d+)\s*x\s*(\d+(?:\.\d+)?)\s*(g|ml|l|kg)\s+(tins?|cans?|bottles?|sachets?|packets?|jars?|cartons?)\s+of\s+/i,
      "\\1 (\\2-\\3) \\4 "
    )
    |> String.replace(
      ~r/^(\d+)\s*x\s*(\d+(?:\.\d+)?)\s*(g|ml|l|kg)\s+(tins?|cans?|bottles?|sachets?|packets?|jars?|cartons?)\s+/i,
      "\\1 (\\2-\\3) \\4 "
    )
    # Also handle "1 x 400g of chopped tomatoes" (no container word)
    |> String.replace(
      ~r/^(\d+)\s*x\s*(\d+(?:\.\d+)?)\s*(g|ml|l|kg)\s+of\s+/i,
      "\\1 \\2 \\3 "
    )
    # "7g sachet fast-action dried yeast" -> "1 (7-g) sachet dried yeast"
    # No "X x" prefix, just "Yunit container [of] Z"
    |> String.replace(
      ~r/^(\d+(?:\.\d+)?)\s*(g|ml|l|kg)\s+(sachets?|packets?|tins?|cans?|bottles?|jars?|cartons?)\s+(?:of\s+)?/i,
      "1 (\\1-\\2) \\3 "
    )
    # Strip yeast-specific modifiers: "fast-action", "easy-bake", "easy-blend", "fast-acting"
    |> String.replace(~r/\b(?:fast-action|fast-acting|easy-bake|easy-blend)\s+/i, "")
  end

  # Normalize "1 medium X or Y Z" patterns where color modifiers are before "or"
  # "1 medium white or yellow onion" -> "1 medium onion"
  # "1 medium red or orange bell pepper" -> "1 medium bell pepper"
  # Strips the color modifiers entirely so the ingredient name (onion, bell pepper) matches
  defp normalize_multi_or_adjective(text) do
    case Regex.run(~r/^(.+?\s)(white|yellow|red|orange|green|purple|black|brown)\s+or\s+(white|yellow|red|orange|green|purple|black|brown)\s+(.+)$/i, text) do
      [_, prefix, _first_adj, _second_adj, rest] ->
        String.trim(prefix <> rest)
      _ ->
        # Also handle comma-separated lists ending in "chiles/peppers"
        # "green Indian, Thai, or serrano chiles" -> "serrano chiles"
        # Take the last alternative before the shared noun
        case Regex.run(~r/^(\d\S*)\s+(?:\w+\s+)?(?:\w+,\s*)+(?:or\s+)?(\w+\s+(?:chiles?|peppers?|chilis?|chilies?))\b(.*)$/i, text) do
          [_, qty, last_alternative, rest] ->
            String.trim("#{qty} #{last_alternative}#{rest}")
          _ ->
            text
        end
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
    matched_ingredients = Enum.map(ingredient_names, fn name ->
      match = match_ingredient(name, lookup)
      # If no match, retry with prep words prepended (e.g., "sauce" -> "hot sauce")
      if is_nil(match.canonical_id) and length(analysis.preparations) > 0 do
        retry_with_preps(name, analysis.preparations, lookup) || match
      else
        match
      end
    end)

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

    # Mark skipped ingredients (equipment, section headers, salt-and-pepper, etc.)
    base = if is_nil(parsed.primary_ingredient) and parsed.ingredients == [] do
      Map.put(base, "skipped", true)
    else
      base
    end

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
  # Delegate to centralized QuantityParser module
  def parse_quantity(qty_list), do: QuantityParser.parse(qty_list)

  @doc false
  def parse_single_quantity(str), do: QuantityParser.parse_single(str)

  @doc false
  # Delegate to centralized Units module
  def normalize_unit(unit), do: Units.normalize(unit)

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
      find_metric_container_pattern(tokens) ||
      find_qty_container_pattern(tokens)
  end

  # Pattern 1: (qty unit) container - e.g., "(14 oz) can"
  # Also handles: (size) container - e.g., "(15-ounce) cans"
  defp find_paren_sequence(tokens) do
    paren_start = Enum.find_index(tokens, &(&1.text == "("))

    if paren_start do
      rest = Enum.drop(tokens, paren_start + 1)

      # Try (qty unit) container first
      result = with [%{label: :qty, text: qty_text} | rest] <- rest,
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

      # Fallback: try (size) container - e.g., "(15-ounce) cans"
      result || with [%{label: :size, text: size_text} | rest] <- rest,
           [%{text: ")"} | rest] <- rest,
           [%{label: :container, text: container_text} | _] <- rest do
        case parse_size_string(size_text) do
          {value, unit} ->
            %{
              size_value: value,
              size_unit: unit,
              container_type: container_text
            }
          nil -> nil
        end
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

  # Pattern 3: qty unit container - e.g., "400 g tin", "200 ml bottle"
  # Matches metric-sized containers where size is qty+unit before container type
  # Only matches metric units (g, kg, ml, l) to avoid false positives
  defp find_metric_container_pattern(tokens) do
    tokens
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.find_value(fn
      [%{label: :qty, text: qty_text}, %{label: :unit, text: unit_text}, %{label: :container, text: container_text}] ->
        normalized_unit = normalize_unit(unit_text)

        if normalized_unit in ~w(g kg ml l) do
          %{
            size_value: parse_single_quantity(qty_text),
            size_unit: normalized_unit,
            container_type: container_text
          }
        else
          nil
        end

      _ ->
        nil
    end)
  end

  # Pattern 4: qty container - e.g., "2 cans", "1 jar" (no size specified)
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

  alias Controlcopypasta.Ingredients.ParserCache

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
        if next_word && MapSet.member?(ParserCache.preparations(), String.downcase(next_word.text)) do
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
        if MapSet.member?(ParserCache.preparations(), text) do
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
    |> Enum.filter(&MapSet.member?(ParserCache.preparations(), &1))
  end

  @ingredient_stop_words ~w(
    with into from above below use sub well off dry fire cool
    about generous divided whole preferred natural if
    inch inches slices pieces sprigs ends chunks chips
    dutch-process warmed heated cooled reserved broken
    crusts cubed shaved pressed packed medium scoops
    lumpy soaked overnight mild-flavored cut you
    inch\ slices cut\ into butt fat woody fronds heads
    deboned butterflied spatchcocked peeling any color
    temp room gluten\ free needed packet recipe
    thick\ slices thin\ slices have them using
    shaken\ well well\ shaken
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
  # Delegate to centralized Matcher module
  def match_ingredient(name, lookup), do: Matcher.match(name, lookup)

  # When the base ingredient name doesn't match, try prepending each prep word.
  # E.g., "sauce" fails -> try "hot sauce" (since "hot" was labeled as :prep)
  defp retry_with_preps(name, preparations, lookup) do
    Enum.find_value(preparations, fn prep ->
      candidate = "#{prep} #{name}"
      match = Matcher.match(candidate, lookup)
      if match.canonical_id, do: match
    end)
  end

  @doc """
  Attempts to singularize an English word.

  Uses conservative rules to avoid breaking words that naturally end in 's'.
  Returns the word unchanged if it's in the exception list or doesn't match
  any known plural pattern.
  """
  # Delegate to centralized Singularizer module
  def singularize(word), do: Singularizer.singularize(word)
end
