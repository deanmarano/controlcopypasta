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
  alias Controlcopypasta.Ingredients.Detection.RoleDetector
  alias Controlcopypasta.Ingredients.Detection.StatedWeight
  alias Controlcopypasta.Ingredients.Parsing.{Singularizer, QuantityParser}
  alias Controlcopypasta.Ingredients.Matching.Matcher

  @sub_parsers [
    # Check for recipe references first
    SubParsers.RecipeReference,
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
      # List of matched ingredients (for alternatives)
      :ingredients,
      # The first/main ingredient
      :primary_ingredient,
      :preparations,
      :modifiers,
      :storage_medium,
      # Role phrases matched on the ORIGINAL line ("for serving", "(optional)").
      # Recorded rather than only stripped -- see RoleDetector.
      :notes,
      # What the line is for: :ingredient | :serving | :garnish | :to_taste |
      # :cooking_medium. Detected from the original text, never from the match.
      :role,
      # Orthogonal to role: "sherry (for serving; optional)" is both.
      :optional,
      # true if "or" pattern detected
      :is_alternative,
      # "such as X, Y, or Z" - specific options to choose from
      :choices,
      # Reference to another recipe (sub-recipe)
      :recipe_reference,
      # Why the line was deliberately dropped: :equipment | :section_header |
      # :salt_and_pepper, or nil when the line is a real ingredient. A nil
      # canonical with a skip_reason set is a decision, not a parse failure --
      # consumers must not report it as one.
      :skip_reason,
      # ParseDiagnostics struct when enabled
      :diagnostics
    ]

    @type recipe_reference :: %{
            type: :below | :above | :notes | :link | :inline,
            text: String.t() | nil,
            name: String.t() | nil,
            is_optional: boolean()
          }

    @type skip_reason :: :equipment | :section_header | :salt_and_pepper | nil

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
            role: RoleDetector.role(),
            optional: boolean(),
            is_alternative: boolean(),
            choices: [ingredient_match()] | nil,
            recipe_reference: recipe_reference() | nil,
            skip_reason: skip_reason(),
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

    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)
    opts = Keyword.put(opts, :lookup, lookup)

    # The role is read from the ORIGINAL text, before preprocessing strips the
    # phrases that carry it. Applied to whichever branch below produces the
    # result, so the sub-parsers get it without each having to know about it.
    role = RoleDetector.detect(text)

    # Preprocess text to normalize problematic patterns
    parsed =
      case preprocess_text(text, lookup) do
        {:skip, reason} ->
          # Deliberately not an ingredient (equipment, a section header, or a
          # bare "salt and pepper"). The line is dropped on purpose, so a nil
          # canonical here is a decision rather than a parse failure -- record
          # which rule dropped it so diagnostics can tell the two apart.
          skipped = %ParsedIngredient{
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
            choices: nil,
            skip_reason: reason
          }

          if include_diagnostics do
            %{skipped | diagnostics: skip_diagnostics(text, reason, start_time)}
          else
            skipped
          end

        preprocessed_text ->
          parse_preprocessed(preprocessed_text, text, opts, start_time, include_diagnostics)
      end

    parsed
    |> put_role(role)
    |> put_stated_weight(text)
  end

  # A weight the recipe states in parentheses, when the parse found no weight
  # or volume of its own.
  #
  # Read from the original line because preprocessing deletes the parenthetical
  # before tokenizing -- `normalize_parenthetical_notes/1` strips "(about
  # <number> ...)" as a descriptive note, and that has to keep happening for
  # the remainder to match the catalog. See Detection.StatedWeight.
  defp put_stated_weight(%ParsedIngredient{} = parsed, text) do
    cond do
      # The line already measures itself.
      not is_nil(parsed.unit) and not count_unit?(parsed.unit) ->
        parsed

      # A sized container already accounts for the parenthetical, and
      # Calculator.resolve_effective_unit/1 multiplies quantity by that size.
      not is_nil(parsed.container) and not is_nil(parsed.container.size_value) ->
        parsed

      # Nothing was matched, so there is nothing to weigh.
      is_nil(parsed.primary_ingredient) ->
        parsed

      true ->
        apply_stated_weight(parsed, StatedWeight.detect(text))
    end
  end

  defp apply_stated_weight(parsed, nil), do: parsed

  defp apply_stated_weight(parsed, %{scope: :total} = weight) do
    %{
      parsed
      | quantity: weight.quantity,
        quantity_min: weight.quantity_min,
        quantity_max: weight.quantity_max,
        unit: weight.unit
    }
  end

  # "2 rib-eye steaks (about 1 lb. each)" is 2 lb: the stated weight is per
  # item, so it is multiplied by the count.
  #
  # This is the one reading that depends on the count being right, which is why
  # it was left out when `:total` shipped -- a thickness used to be absorbed
  # into the count ("2 1 1/4\"-thick steaks" read as 3) and "4 or 5" was summed
  # to 9. Both are fixed now (`strip_thickness/1` and the "or" range in
  # `normalize_to_range/1`), so multiplying by the count no longer multiplies a
  # known error.
  #
  # With no count at all the weight is taken as written, which is the same
  # reading as one item.
  defp apply_stated_weight(parsed, %{scope: :each} = weight) do
    count = parsed.quantity || 1.0

    # Each bound is multiplied by its own end of the count, so a range stays a
    # range: "4 or 5 small red potatoes (about 3 ounces each)" is 12-15 oz, not
    # 13.5 either way.
    %{
      parsed
      | quantity: weight.quantity * count,
        quantity_min: weight.quantity_min * (parsed.quantity_min || count),
        quantity_max: weight.quantity_max * (parsed.quantity_max || count),
        unit: weight.unit
    }
  end

  # Units that count things rather than measure them, so a stated weight is the
  # only real measurement on the line: "4 thin slices ham (about 4 oz. total)"
  # is 4 oz of ham, while "4 slice" converts to grams only for an ingredient
  # that happens to have a per-slice record.
  @counting_units ~w(each whole piece pieces slice slices head heads bunch
                     bunches sprig sprigs stalk stalks leaf leaves clove cloves
                     block blocks fillet fillets)

  defp count_unit?(unit), do: String.downcase(unit) in @counting_units

  # Role and optionality are additive: they never influence the match, the
  # quantity or the unit, so they are stamped on at the end rather than threaded
  # through the parse.
  defp put_role(%ParsedIngredient{} = parsed, role) do
    %{parsed | role: role.role, optional: role.optional, notes: role.markers}
  end

  defp parse_preprocessed(preprocessed_text, original_text, opts, start_time, include_diagnostics) do
    tokens = Tokenizer.tokenize(preprocessed_text)
    lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)

    {result, parser_used} =
      case try_sub_parsers(tokens, original_text, lookup) do
        {:ok, parsed, parser_name} -> {parsed, parser_name}
        {:ok, parsed} -> {parsed, :sub_parser}
        :skip -> {parse_standard(tokens, original_text, lookup), :standard}
      end

    if include_diagnostics do
      diagnostics = build_diagnostics(tokens, parser_used, result, start_time, lookup)
      %{result | diagnostics: diagnostics}
    else
      result
    end
  end

  # Preprocess ingredient text to normalize problematic patterns
  # Returns :skip for non-ingredients, or the preprocessed text
  defp preprocess_text(text, lookup) do
    cond do
      # Filter out kitchen equipment (using centralized detector). The lookup
      # lets a canonical ingredient override the equipment heuristics.
      EquipmentDetector.is_equipment?(text, lookup: lookup) ->
        {:skip, :equipment}

      # Filter out section headers (FILLING, For the pastry:, etc.)
      is_section_header?(text) ->
        {:skip, :section_header}

      # "Salt and pepper" / "Kosher salt and freshly ground black pepper, to taste" - skip
      Regex.match?(
        ~r/^\s*(?:kosher\s+|sea\s+)?salt\s+and\s+(?:freshly\s+ground\s+)?(?:black\s+)?pepper\b/i,
        text
      ) ->
        {:skip, :salt_and_pepper}

      true ->
        text
        |> strip_leading_optional()
        |> normalize_smart_quotes()
        |> normalize_british_spelling()
        |> normalize_to_range()
        |> strip_thickness()
        |> normalize_slash_measurements()
        |> truncate_semicolon_parentheticals()
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

  # The dimension's unit and the word itself: `1/2"-thick`, `2-inch-thick`,
  # `1 1/2 inch thick`.
  @thickness "\\s*(?:\"|''|\\s*-?\\s*inch(?:es)?)\\s*-?\\s*thick(?:ly)?\\b"

  # Remove a stated thickness, which is a dimension rather than an amount.
  #
  #     2 1 1/4"-thick New York strip steaks  -> 2 New York strip steaks
  #     3 1 1/2-inch-thick boneless rib eyes  -> 3 boneless rib eyes
  #     4 1/2-inch-thick slices country bread -> 4 slices country bread
  #
  # Left in place, the dimension's own number sits next to the count as a bare
  # quantity token. `QuantityParser` adds a proper fraction to the number before
  # it to read a mixed number, so "2" followed by "1" became three steaks; and
  # the leftover `1/4"` stayed glued to the front of the ingredient name, where
  # nothing in the catalog matches it.
  #
  # Only "thick" is matched, not every dimension: a length or a diameter is
  # usually the whole description of the piece ("1 2-inch piece ginger"), which
  # `normalize_ginger_size/1` handles by turning it into a unit instead.
  defp strip_thickness(text) do
    text
    # A count, then the thickness. The count is kept and only the dimension
    # removed, because "4 1/2\"-thick slices" is ambiguous on its face -- four
    # half-inch slices, or four and a half inches? -- and the corpus means the
    # first. Taking the leading number into the dimension lost the count.
    |> String.replace(~r/^(\d+)\s+(?:\d+\s+)?\d+(?:\/\d+|[.,]\d+)?#{@thickness}/i, "\\1 ")
    # No count in front: the whole dimension goes.
    |> String.replace(~r/\s*\b\d+(?:\/\d+|[.,]\d+)?#{@thickness}/i, "")
    |> String.trim()
  end

  # Normalize slash measurements: "1/2 cup/100 grams sugar" -> "1/2 cup sugar"
  # Pattern: X unit/Y grams -> X unit
  defp normalize_slash_measurements(text) do
    # Match: unit/number followed by grams/g
    # E.g., "cup/100 grams", "cups/256 grams", "cup/100g"
    text
    |> String.replace(
      ~r/(\b(?:cups?|tablespoons?|tbsp?|teaspoons?|tsp)\s*)\/\s*\d+\s*(?:grams?|g)\b/i,
      "\\1"
    )
  end

  # `normalize_semicolon_notes/1` truncates the line at its first semicolon, to
  # drop a trailing note. That is right for a semicolon between clauses of the
  # line, but destructive for one *inside* a parenthetical, because everything
  # after it went too -- including the food:
  #
  #     "1/2 cup (packed; 100 g) light brown sugar"  ->  "1/2 cup (packed"
  #
  # So apply the same truncation one level down first: keep a parenthetical's
  # leading clause and drop the rest, leaving a balanced paren the existing
  # rules can recognise ("(packed)", "(2 sticks)", "(240 g)"). The dropped
  # clauses are secondary either way -- a gram equivalent of the volume already
  # given, a sleeve count, a "see Tip" pointer.
  #
  # Dropping them rather than re-parenthesising them also keeps a clause from
  # being read as the line's unit: "4 chicken legs (thigh and drumstick; 2-3
  # lb. total)" is four legs weighing 2-3 lb between them, and "4 lb." would
  # overstate it nearly 3x.
  defp truncate_semicolon_parentheticals(text) do
    Regex.replace(~r/\(([^()]*;[^()]*)\)/, text, fn _full, inner ->
      inner
      |> String.split(";", parts: 2)
      |> hd()
      |> String.trim()
      |> case do
        "" -> ""
        kept -> "(#{kept})"
      end
    end)
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
    "½" => "1/2",
    "⅓" => "1/3",
    "⅔" => "2/3",
    "¼" => "1/4",
    "¾" => "3/4",
    "⅕" => "1/5",
    "⅖" => "2/5",
    "⅗" => "3/5",
    "⅘" => "4/5",
    "⅙" => "1/6",
    "⅚" => "5/6",
    "⅛" => "1/8",
    "⅜" => "3/8",
    "⅝" => "5/8",
    "⅞" => "7/8"
  }

  defp normalize_smart_quotes(text) do
    text
    # non-breaking space
    |> String.replace("\u00A0", " ")
    # unicode fraction slash
    |> String.replace("\u2044", "/")
    # left double smart quote
    |> String.replace("\u201C", "\"")
    # right double smart quote
    |> String.replace("\u201D", "\"")
    # left single smart quote
    |> String.replace("\u2018", "'")
    # right single smart quote
    |> String.replace("\u2019", "'")
    # double prime
    |> String.replace("\u2033", "\"")
    # en-dash (used in ranges: "1–2")
    |> String.replace("\u2013", "-")
    # em-dash
    |> String.replace("\u2014", "-")
    |> normalize_superscript_subscript_digits()
    |> normalize_unicode_fraction_chars()
  end

  # Normalize Unicode superscript/subscript digits to ASCII
  # ²/₃ → 2/3, ¹/₄ → 1/4, etc.
  @superscript_digits %{
    "⁰" => "0",
    "¹" => "1",
    "²" => "2",
    "³" => "3",
    "⁴" => "4",
    "⁵" => "5",
    "⁶" => "6",
    "⁷" => "7",
    "⁸" => "8",
    "⁹" => "9"
  }
  @subscript_digits %{
    "₀" => "0",
    "₁" => "1",
    "₂" => "2",
    "₃" => "3",
    "₄" => "4",
    "₅" => "5",
    "₆" => "6",
    "₇" => "7",
    "₈" => "8",
    "₉" => "9"
  }

  defp normalize_superscript_subscript_digits(text) do
    Enum.reduce(Map.merge(@superscript_digits, @subscript_digits), text, fn {char, replacement},
                                                                            acc ->
      String.replace(acc, char, replacement)
    end)
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
    |> String.replace(
      ~r/(\d+)\s+(cans?|tins?|jars?|bottles?|cartons?)\s+\(\s*(\d+(?:\.\d+)?)\s*(oz|ounces?|g|grams?|ml|l)\s+/i,
      "\\1 (\\3-\\4) \\2 "
    )
    # "(10 ounces/283 grams)" weight conversions after standard units (cups, tbsp, etc.)
    # Only strip when preceded by a standard measurement, NOT after "can/tin" (which need the size)
    # Number pattern allows fractions: "8 3/4", "1.5", "10"
    # Allow modifiers like "packed" between unit and parens: "1 cup packed (7 oz/198g)"
    |> String.replace(
      ~r/(\d+(?:\s+\d+\/\d+)?\s+(?:cups?|tablespoons?|tbsp|teaspoons?|tsp)(?:\s+packed)?)\s*\(\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:ounces?|oz)\s*\/\s*\d+\s*(?:grams?|g)\s*\)/i,
      "\\1"
    )
    # "(283 grams/10 ounces)" metric-first variant, same restriction
    |> String.replace(
      ~r/(\d+(?:\s+\d+\/\d+)?\s+(?:cups?|tablespoons?|tbsp|teaspoons?|tsp)(?:\s+packed)?)\s*\(\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:grams?|g)\s*\/\s*\d+(?:\s+\d+\/\d+)?(?:\.\d+)?\s*(?:ounces?|oz)\s*\)/i,
      "\\1"
    )
    # Parens containing "store bought", "homemade", "or sub", "see note", "if needed"
    # and aliasing lead-ins like "(also called quick-rising ...)", which only give
    # the ingredient another name -- left in place, the "or" inside them gets read
    # as an ingredient alternative and the real head noun is lost.
    |> String.replace(
      ~r/\(\s*(?:store\s*bought|homemade|or\s+sub|see\s+note|if\s+needed|approximately|about\s+\d|also\s+called|also\s+known\s+as|a\.?k\.?a\.?|sometimes\s+called|labell?ed)[^)]*\)/i,
      ""
    )
    # Parens starting with "or" suggesting alternatives we don't parse: "(or other protein)"
    |> String.replace(~r/\(\s*or\s+(?:other|sub|substitute|[\d])[^)]*\)/i, "")
    # Cost annotations from budget-recipe sites: "salsa ($0.50)" -> "salsa".
    # Left in, the "$0.50" becomes its own ingredient group.
    |> String.replace(~r/\(\s*[$£€]\s*\d[^)]*\)/, "")
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
    case Regex.run(
           ~r/^(.+?\b(?:teaspoons?|tsp|tablespoons?|tbsp|cups?|oz|ounces?|pounds?|lb)\s+)each\s+(.+?)\s+and\s+(.+)$/i,
           text
         ) do
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
    |> String.replace(
      ~r/^\s*\d+(?:\.\d+)?\s*(?:ml|g|kg|l)\s*\/\s*(\d+(?:\s+\d+\/\d+)?(?:\.\d+)?)\s*(fl\s*oz|fluid\s+ounces?|ounces?|oz|cups?|tablespoons?|tbsp|teaspoons?|tsp)\b/i,
      "\\1 \\2"
    )
    # "8.5 fluid ounces/250 ml water" -> "8.5 fluid ounces water"
    |> String.replace(
      ~r/(\b\d+(?:\.\d+)?\s+(?:fluid\s+)?(?:ounces?|oz|cups?|tablespoons?|tbsp|teaspoons?|tsp))\s*\/\s*\d+(?:\.\d+)?\s*(?:ml|g|l|kg)\b/i,
      "\\1"
    )
    # "1 cup/8 ounces (226 grams) ricotta" -> "1 cup ricotta"
    |> String.replace(
      ~r/(\b\d+(?:[\/\.]\d+)?\s+(?:cups?|c)\s*)\/\s*\d+\s+(?:ounces?|oz)\b/i,
      "\\1"
    )
    # "8 ounces (1 cup; 225g) X" -> "8 ounces X" (strip parenthetical with cup;g alternative)
    |> String.replace(
      ~r/\(\s*\d+(?:[\/\.]\d+)?\s+(?:cups?|c)\s*;\s*\d+(?:\.\d+)?\s*(?:g|grams?)\s*\)/i,
      ""
    )
    # "7/8 cup to 1 cup (198g to 227g)" → "7/8 cup" (strip range and gram parens)
    |> String.replace(
      ~r/(\b\d+(?:\/\d+)?\s+(?:cups?|c))\s+to\s+\d+(?:\/\d+)?\s+(?:cups?|c)\s*\([^)]*\)/i,
      "\\1"
    )
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

  # Normalize "X to Y" and "X or Y" quantity ranges to dash notation
  # "3 to 4 green onions" -> "3-4 green onions"
  # "1 to 2 teaspoons sesame oil" -> "1-2 teaspoons sesame oil"
  # "4 or 5 small red potatoes" -> "4-5 small red potatoes"
  # Only matches when X and Y are numbers at the beginning of the string
  #
  # "or" is here because the tokenizer labels it a conjunction and drops it,
  # leaving two bare quantities that used to be added together -- "4 or 5"
  # became nine potatoes. Written as a range it means what the recipe says.
  defp normalize_to_range(text) do
    text
    |> String.replace(~r/^(\d+(?:\/\d+)?)\s+(?:to|or)\s+(\d+(?:\/\d+)?)\b/i, "\\1-\\2")
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
    # "mint for serving" -> "mint", "parsley for garnish" -> "parsley"
    |> String.replace(
      ~r/,?\s+for\s+(?:serving|garnish|garnishing|topping|drizzling|dipping|finishing)\b.*$/i,
      ""
    )
    # "dill and/or thinly sliced chives" -> "dill" (take first before and/or)
    |> normalize_and_or()
  end

  # Handle "and/or" splits: take the first ingredient
  # "dill and/or thinly sliced chives" -> "dill"
  defp normalize_and_or(text) do
    case String.split(text, ~r/\s+and\/or\s+/i, parts: 2) do
      [first, _rest] -> String.trim(first)
      _ -> text
    end
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
    |> String.replace(~r/\byoghurt\b/i, "yogurt")
    # ".5 teaspoon" -> "0.5 teaspoon"
    |> String.replace(~r/^\.(\d)/, "0.\\1")
  end

  # Detect section headers that aren't ingredients
  # Returns true for: ALL CAPS single words, "For the X:", "Dry ingredients:", advertising, etc.
  defp is_section_header?(text) do
    trimmed = String.trim(text)

    cond do
      # Blank or whitespace-only
      trimmed == "" ->
        true

      # Ends with colon (section labels): "For the pastry:", "Dry ingredients:", "FILLING:"
      String.ends_with?(trimmed, ":") ->
        true

      # "For the X" section headers: "For the Toast", "For the Poolish", "For the Dough"
      Regex.match?(~r/^for\s+the\s+\w/i, trimmed) ->
        true

      # ALL CAPS single or two words with no digits: "FILLING", "TO SERVE", "GARNISH"
      Regex.match?(~r/^[A-Z][A-Z\s]{0,30}$/, trimmed) and not Regex.match?(~r/\d/, trimmed) ->
        true

      # Advertising / non-ingredient lines
      Regex.match?(~r/^\s*(?:SHOP|BUY|ORDER|SPONSORED|ADVERTISEMENT|AD)\b/i, trimmed) ->
        true

      true ->
        false
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
    case Regex.run(
           ~r/^(.+?\s)(white|yellow|red|orange|green|purple|black|brown)\s+or\s+(white|yellow|red|orange|green|purple|black|brown)\s+(.+)$/i,
           text
         ) do
      [_, prefix, _first_adj, _second_adj, rest] ->
        String.trim(prefix <> rest)

      _ ->
        # Also handle comma-separated lists ending in "chiles/peppers"
        # "green Indian, Thai, or serrano chiles" -> "serrano chiles"
        # Take the last alternative before the shared noun
        case Regex.run(
               ~r/^(\d\S*)\s+(?:\w+\s+)?(?:\w+,\s*)+(?:or\s+)?(\w+\s+(?:chiles?|peppers?|chilis?|chilies?))\b(.*)$/i,
               text
             ) do
          [_, qty, last_alternative, rest] ->
            String.trim("#{qty} #{last_alternative}#{rest}")

          _ ->
            text
        end
    end
  end

  # Diagnostics for a line the preprocessor dropped before parsing began.
  defp skip_diagnostics(text, reason, start_time) do
    tokens = Tokenizer.tokenize(text)

    %ParseDiagnostics{
      tokens: tokens,
      token_string: Tokenizer.format(tokens),
      parser_used: :preprocessor_skip,
      match_candidates: [],
      selected_match: nil,
      match_strategy: :skipped,
      warnings: [skip_warning(reason)],
      parse_time_us: System.monotonic_time(:microsecond) - start_time
    }
  end

  defp skip_warning(:equipment), do: "Skipped: detected as kitchen equipment, not a food"
  defp skip_warning(:section_header), do: "Skipped: detected as a section header"

  defp skip_warning(:salt_and_pepper),
    do: "Skipped: bare \"salt and pepper\" is dropped by design"

  defp build_diagnostics(tokens, parser_used, result, start_time, lookup) do
    parse_time = System.monotonic_time(:microsecond) - start_time

    # The Matcher records which cascade branch produced the match. Never infer
    # it from the confidence: two branches share 0.9, and the IngredientScorer
    # overwrites the confidence with its own score afterwards.
    match_strategy = match_strategy(result.primary_ingredient)

    %ParseDiagnostics{
      tokens: tokens,
      token_string: Tokenizer.format(tokens),
      parser_used: parser_used,
      match_candidates: build_match_candidates(result),
      match_trail: build_match_trail(result.primary_ingredient, lookup),
      selected_match: summarize_selected_match(result.primary_ingredient),
      match_strategy: match_strategy,
      warnings: ParseDiagnostics.detect_warnings(tokens, result),
      parse_time_us: parse_time
    }
  end

  # NOTE: these are the other ingredients found on the *same line* (the "salt"
  # and "pepper" of one entry), not near-miss canonicals that lost the match.
  # Tracking rejected candidates needs the Matcher to report what it considered.
  defp build_match_candidates(result) do
    result.ingredients
    |> Enum.map(fn ing ->
      %{
        name: ing.name,
        canonical_name: ing.canonical_name,
        confidence: ing.confidence,
        strategy: match_strategy(ing)
      }
    end)
  end

  # Sub-parsers and the no-match fallback can build ingredient maps that never
  # went through the Matcher, so the key is not guaranteed to be present.
  defp match_strategy(nil), do: nil
  defp match_strategy(ingredient), do: Map.get(ingredient, :strategy, :unknown)

  # The attempt trail is obtained by re-running the match for the primary
  # ingredient with tracing on, rather than threading a trace flag through
  # every parsing path. `primary.name` is the exact string that was handed to
  # the Matcher, and matching is pure, so the replay reproduces the original
  # decision. If it somehow does not, the trail is dropped rather than shown
  # next to a strategy it does not explain.
  defp build_match_trail(nil, _lookup), do: nil

  defp build_match_trail(primary, lookup) do
    case Map.get(primary, :name) do
      name when is_binary(name) ->
        replay = Matcher.match(name, lookup, trace: true)

        if Map.get(replay, :strategy) == Map.get(primary, :strategy) do
          Map.get(replay, :match_trail)
        end

      _ ->
        nil
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
            parser_name =
              parser
              |> Module.split()
              |> List.last()
              |> String.downcase()
              |> String.to_atom()

            {:ok, parsed, parser_name}

          :skip ->
            nil
        end
      end
    end)
  end

  @doc false
  def parse_standard(tokens, original, lookup) do
    analysis = Tokenizer.analyze(tokens)

    # Parse quantity (handle ranges)
    {quantity, quantity_min, quantity_max} = parse_quantity(analysis.quantity)

    # Extract container info if present
    container = extract_container(tokens)

    # Parse unit
    unit = normalize_unit(effective_unit(analysis, container))

    # "Pinch of sugar" states an amount without a number. Supply the 1 the
    # author elided -- "a pinch of sugar" already parses as 1.0, so this just
    # covers the spelling where the article is dropped too.
    quantity = implicit_quantity(quantity, unit)

    # Get ingredient names, applying juice/zest transformations
    raw_ingredient_names = clean_ingredient_names(analysis.ingredients)

    ingredient_names =
      transform_juice_zest_patterns(raw_ingredient_names, analysis.preparations, tokens)

    matched_ingredients =
      Enum.map(ingredient_names, fn name ->
        match = match_ingredient(name, lookup)
        # If no match, retry with prep words prepended (e.g., "sauce" -> "hot sauce")
        if is_nil(match.canonical_id) and length(analysis.preparations) > 0 do
          retry_with_preps(name, analysis.preparations, lookup) || match
        else
          match
        end
      end)

    # Get primary ingredient (prefer canonical match over measurement fragments)
    primary = select_primary_ingredient(matched_ingredients)

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

  # Units whose bare appearance can only mean one of them.
  #
  # Deliberately NOT general. Measured over the stored corpus, the units that
  # turn up with a unit but no number are: leaf (5,990), pinch (4,515), sprig
  # (405), cup (95), slice (60), piece (47). Only the pinch family is safe:
  #
  #   - "leaf" is almost always "leaf lettuce" or "cilantro leaves with tender
  #     stems", where the word is part of the ingredient, not a count of one.
  #     Inventing "1 leaf" would report a confident, badly wrong weight in
  #     place of an honest gap.
  #   - a bare "cup" or "slice" is a parse artefact, and 1 is a guess.
  #
  # A pinch has no plausible reading other than one pinch, which is why it is
  # the only family here.
  @implicit_single_units ~w(pinch dash smidgen)

  defp implicit_quantity(nil, unit) when unit in @implicit_single_units, do: 1.0
  defp implicit_quantity(quantity, _unit), do: quantity

  # Select the best primary ingredient from matched_ingredients.
  # Prefers an ingredient with a canonical match over one that looks like a measurement fragment.
  defp select_primary_ingredient([]), do: nil

  defp select_primary_ingredient(ingredients) do
    # Prefer ingredient with canonical match that isn't a measurement fragment
    # Then any canonical match
    # Then prefer ingredient that doesn't look like a measurement fragment
    # Fall back to first
    Enum.find(ingredients, fn i -> i.canonical_id != nil and not measurement_fragment?(i.name) end) ||
      Enum.find(ingredients, fn i -> i.canonical_id != nil end) ||
      Enum.find(ingredients, fn i -> not measurement_fragment?(i.name) end) ||
      List.first(ingredients)
  end

  defp measurement_fragment?(name) do
    Regex.match?(~r/^\d|^oz\.|^lb\.|inch|^²|^¼|^½|^¾|^⅓|^⅔/i, name)
  end

  @doc """
  Converts a ParsedIngredient to a map suitable for JSONB storage.
  Uses the primary ingredient for backward compatibility.
  """
  def to_jsonb_map(%ParsedIngredient{} = parsed) do
    primary =
      parsed.primary_ingredient || %{canonical_name: nil, canonical_id: nil, confidence: 0.5}

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

    # Role and optionality are only emitted when they say something. The corpus
    # is over a million rows and the overwhelming majority are plain
    # `:ingredient` / not-optional, so writing the defaults would grow every
    # recipe's JSONB to record the absence of news.
    base =
      if parsed.role && parsed.role != :ingredient do
        Map.put(base, "role", Atom.to_string(parsed.role))
      else
        base
      end

    base = if parsed.optional, do: Map.put(base, "optional", true), else: base

    base =
      case parsed.notes do
        [_ | _] = markers -> Map.put(base, "role_markers", markers)
        _ -> base
      end

    # Mark skipped ingredients (equipment, section headers, salt-and-pepper, etc.)
    base =
      if is_nil(parsed.primary_ingredient) and parsed.ingredients == [] do
        Map.put(base, "skipped", true)
      else
        base
      end

    # Which rule dropped it, so a stored line can be told apart from one that
    # simply failed to match. "skipped" above is true for both.
    base =
      if parsed.skip_reason do
        Map.put(base, "skip_reason", Atom.to_string(parsed.skip_reason))
      else
        base
      end

    # Add container if present
    base =
      if parsed.container do
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
    base =
      if parsed.storage_medium do
        Map.put(base, "storage_medium", parsed.storage_medium)
      else
        base
      end

    # Add alternatives if present
    base =
      if parsed.is_alternative and length(parsed.ingredients) > 1 do
        alternatives =
          parsed.ingredients
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
    base =
      if parsed.recipe_reference do
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
    base =
      if parsed.choices && parsed.choices != [] do
        choices =
          Enum.map(parsed.choices, fn choice ->
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

    base =
      if pre_steps != [] do
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

  # Choose between the unit as tokenized and the unit ignoring parentheticals.
  #
  # When the container already captured a size ("1 (15 oz) can black beans"),
  # the parenthesised unit has been accounted for and must not be reused as the
  # quantity's unit: Calculator.resolve_effective_unit/1 takes a present unit
  # as-is and skips the container multiplication, so "1 (15 oz) can" would be
  # costed as a single ounce instead of fifteen.
  #
  # When the container captured no size, the parenthesised weight is the only
  # measurement on the line ("20 jumbo shells (6-7 ounces)"), and discarding it
  # leaves a bare count with no density -- no nutrition at all.
  defp effective_unit(analysis, %{size_value: size_value, size_unit: size_unit})
       when not is_nil(size_value) and not is_nil(size_unit) do
    Map.get(analysis, :unit_outside_parens)
  end

  defp effective_unit(analysis, _container), do: analysis.unit

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
      result =
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

      # Fallback: try (size) container - e.g., "(15-ounce) cans"
      result ||
        with [%{label: :size, text: size_text} | rest] <- rest,
             [%{text: ")"} | rest] <- rest,
             [%{label: label, text: container_text} | _] <- rest,
             true <- container_noun?(label, container_text) do
          case parse_size_string(size_text) do
            {value, unit} ->
              %{
                size_value: value,
                size_unit: unit,
                container_type: String.downcase(container_text)
              }

            nil ->
              nil
          end
        else
          _ -> nil
        end
    else
      nil
    end
  end

  # Package nouns that are not in @containers, because the bare word is also an
  # ordinary descriptor: "short tube pasta", "envelope" in a non-food sense.
  # Matched only directly after a :size token, where it can only be a package:
  # "1 (4.5-oz.) tube tomato paste", "1 1/4-oz. envelope instant yeast".
  #
  # Labelling them :container in the tokenizer instead would reach every
  # occurrence, and it cost "12 ounces tubetti or other short tube pasta" its
  # match -- "tube" stopped being part of the ingredient name.
  @sized_package_nouns ~w(tube tubes envelope envelopes)

  defp container_noun?(:container, _text), do: true
  defp container_noun?(:word, text), do: String.downcase(text) in @sized_package_nouns
  defp container_noun?(_label, _text), do: false

  # Pattern 2: size container - e.g., "15-ounce can", "14-oz jar"
  defp find_size_container_pattern(tokens) do
    # Find :size token followed by :container token
    tokens
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn
      [%{label: :size, text: size_text}, %{label: label, text: word_text}]
      when label == :word ->
        if container_noun?(label, word_text) do
          case parse_size_string(size_text) do
            {value, unit} ->
              %{size_value: value, size_unit: unit, container_type: String.downcase(word_text)}

            nil ->
              nil
          end
        end

      [%{label: :size, text: size_text}, %{label: :container, text: container_text}] ->
        case parse_size_string(size_text) do
          {value, unit} ->
            %{
              size_value: value,
              size_unit: unit,
              container_type: container_text
            }

          nil ->
            nil
        end

      _ ->
        nil
    end)
  end

  # Pattern 3: qty unit container - e.g., "400 g tin", "200 ml bottle"
  # Matches metric-sized containers where size is qty+unit before container type
  # Only matches metric units (g, kg, ml, l) to avoid false positives
  defp find_metric_container_pattern(tokens) do
    tokens
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.find_value(fn
      [
        %{label: :qty, text: qty_text},
        %{label: :unit, text: unit_text},
        %{label: :container, text: container_text}
      ] ->
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

      _ ->
        nil
    end)
  end

  # Parse size strings like "15-ounce", "14-oz" into {value, unit}
  # Must stay in step with `Tokenizer.is_size?/1`: that decides what becomes a
  # :size token, and this decides whether the token yields a usable value. A
  # pattern accepted there but not here produces a :size token that silently
  # drops the weight, which is how "1 1/4-oz. envelope instant yeast" ended up
  # a bare count.
  defp parse_size_string(size_text) do
    case Regex.run(
           ~r/^(\d+(?:[.,]\d+)?|\d+\/\d+)-?(oz|ounce|ounces|lb|lbs|pound|pounds|g|gram|grams|kg|ml|l)\.?$/i,
           size_text
         ) do
      [_, value_str, unit] ->
        case parse_size_value(value_str) do
          nil -> nil
          value -> {value, normalize_unit(unit)}
        end

      _ ->
        nil
    end
  end

  defp parse_size_value(value_str) do
    case String.split(value_str, "/") do
      [num, denom] ->
        with {n, _} <- Float.parse(num),
             {d, _} when d != 0.0 <- Float.parse(denom) do
          n / d
        else
          _ -> nil
        end

      _ ->
        case Float.parse(String.replace(value_str, ",", ".")) do
          {value, _} -> value
          :error -> nil
        end
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
      after_intro =
        case after_intro do
          [%{text: "as"} | rest] -> rest
          other -> other
        end

      # Extract choices and preparations
      {choice_names, prep_names} = parse_choices_and_preps(after_intro)

      # Match choices to canonical ingredients
      matched_choices =
        choice_names
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

        if next_word &&
             MapSet.member?(ParserCache.preparations(), String.downcase(next_word.text)) do
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
    # Remove trailing asterisks
    |> String.replace(~r/\*+$/, "")
    # Remove leading asterisks
    |> String.replace(~r/^\*+/, "")
    # Normalize whitespace
    |> String.replace(~r/\s+/, " ")
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
    has_juice_and_zest =
      String.contains?(text, "juice and zest") or
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
