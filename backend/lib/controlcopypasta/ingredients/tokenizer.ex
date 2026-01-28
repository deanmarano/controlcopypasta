defmodule Controlcopypasta.Ingredients.Tokenizer do
  @moduledoc """
  Tokenizes and labels ingredient strings.

  Each token is labeled with its likely grammatical/semantic role:
  - :qty       - Quantity (1, 2.5, 1/2, 1-2)
  - :unit      - Measurement unit (cup, tbsp, oz, lb)
  - :size      - Container size modifier (14-oz, 15-ounce)
  - :container - Container type (can, jar, bag)
  - :prep      - Preparation (chopped, diced, minced)
  - :mod       - Modifier (fresh, large, boneless)
  - :conj      - Conjunction (or, and)
  - :punct     - Punctuation (, ; ( ))
  - :note      - Recipe note (optional, divided, to taste)
  - :word      - Unclassified word (likely ingredient or adjective)
  """

  defmodule Token do
    defstruct [:text, :label, :position]

    @type t :: %__MODULE__{
            text: String.t(),
            label: atom(),
            position: non_neg_integer()
          }
  end

  # Units - order matters (longer first for matching)
  @units ~w(
    tablespoons tablespoon tbsp tbs tb
    teaspoons teaspoon tsp ts
    fluid\ ounces fluid\ ounce fl\ oz
    ounces ounce oz
    pounds pound lbs lb
    cups cup c
    pints pint pt
    quarts quart qt
    gallons gallon gal
    liters liter litres litre l
    milliliters milliliter ml
    kilograms kilogram kg
    grams gram g
    pinches pinch
    dashes dash
    bunches bunch
    sprigs sprig
    cloves clove
    slices slice
    pieces piece
    heads head
    stalks stalk
  )

  # Container types
  @containers ~w(can cans jar jars bottle bottles bag bags box boxes package packages pkg container containers carton cartons)

  # Preparations
  @preparations ~w(
    chopped diced minced sliced cubed julienned shredded grated
    crushed smashed halved quartered torn crumbled
    melted softened chilled cooled thawed frozen
    drained rinsed strained peeled seeded cored pitted trimmed deveined
    mashed pureed beaten whisked sifted
    toasted roasted
    removed packed divided
    lengthwise crosswise diagonally horizontally vertically
    bruised separated
    juiced zested
  )

  # Modifiers (adjectives that describe ingredient state/size/type)
  @modifiers ~w(
    fresh dried frozen canned raw cooked
    large small medium extra-large
    boneless skinless bone-in skin-on
    whole ground
    light dark
    unsalted salted
    organic
    ripe unripe
    hot cold warm
    thin thick
    fine coarse
    packed heaping scant level
    lightly firmly loosely tightly
    finely roughly coarsely thinly thickly
  )

  # Notes/instructions that aren't part of the ingredient
  @notes ~w(optional divided)
  @note_phrases [
    "to taste", "as needed", "for serving", "for garnish", "for topping",
    "for sprinkling", "for dusting", "for dipping", "for drizzling", "for coating",
    "for brushing", "for frying", "for greasing", "for finishing",
    "plus more", "or more", "or less", "or to taste", "if desired"
  ]

  # Parts of ingredients that are often removed (seeds, ribs, stems, etc.)
  # When these appear after a comma, they're usually prep instructions
  @removable_parts ~w(seeds ribs stems skin skins peel core pit pits veins membranes)

  # Conjunctions
  @conjunctions ~w(or and)

  @doc """
  Tokenizes and labels an ingredient string.

  Returns a list of Token structs with text, label, and position.

  ## Examples

      iex> Tokenizer.tokenize("1 cup diced tomatoes")
      [
        %Token{text: "1", label: :qty, position: 0},
        %Token{text: "cup", label: :unit, position: 1},
        %Token{text: "diced", label: :prep, position: 2},
        %Token{text: "tomatoes", label: :word, position: 3}
      ]
  """
  def tokenize(text) when is_binary(text) do
    text
    |> normalize()
    |> split_tokens()
    |> Enum.with_index()
    |> Enum.map(fn {text, idx} -> label_token(text, idx) end)
    |> fix_ambiguous_labels()
  end

  # Fix tokens that are context-dependent:
  # - "cloves" can be unit ("2 cloves garlic") or ingredient ("whole cloves")
  # - "seeds" can be part ("seeds removed") or ingredient ("sesame seeds")
  # - "of" after a unit should be skipped ("dashes of bitters")
  defp fix_ambiguous_labels(tokens) do
    tokens
    |> Enum.with_index()
    |> Enum.map(fn {token, idx} ->
      cond do
        should_relabel_unit_as_word?(token, tokens, idx) ->
          %{token | label: :word}

        should_relabel_part_as_word?(token, tokens, idx) ->
          %{token | label: :word}

        should_label_as_unit_connector?(token, tokens, idx) ->
          %{token | label: :unit_connector}

        true ->
          token
      end
    end)
  end

  # "cloves" etc. at end without word after, preceded by modifier or another unit
  defp should_relabel_unit_as_word?(%Token{label: :unit}, tokens, idx) do
    tokens_after = Enum.drop(tokens, idx + 1)
    has_word_after = Enum.any?(tokens_after, &(&1.label == :word))

    if has_word_after do
      false
    else
      tokens_before = Enum.take(tokens, idx)

      has_modifier_before = tokens_before
        |> Enum.reverse()
        |> Enum.take_while(&(&1.label in [:mod, :qty]))
        |> Enum.any?(&(&1.label == :mod))

      has_unit_before = Enum.any?(tokens_before, &(&1.label == :unit))

      has_modifier_before or has_unit_before
    end
  end

  defp should_relabel_unit_as_word?(_token, _tokens, _idx), do: false

  # "seeds" after an ingredient word should be part of the name ("poppy seeds", "sesame seeds")
  # But "seeds removed" or "seeds, ribs removed" should keep seeds as :part
  defp should_relabel_part_as_word?(%Token{label: :part, text: text}, tokens, idx) when text in ["seeds", "peel"] do
    # Check what comes before
    tokens_before = Enum.take(tokens, idx)
    prev_token = List.last(tokens_before)

    # Check what comes after
    tokens_after = Enum.drop(tokens, idx + 1)
    next_token = List.first(tokens_after)

    # If preceded by a word (like "poppy", "sesame"), it's part of ingredient name
    # Unless followed by prep/conj/removed (like "seeds removed", "seeds and ribs")
    preceded_by_word = prev_token != nil and prev_token.label == :word
    followed_by_prep_or_removal = next_token != nil and next_token.label in [:prep, :conj]

    preceded_by_word and not followed_by_prep_or_removal
  end

  defp should_relabel_part_as_word?(_token, _tokens, _idx), do: false

  # "of" immediately after a unit ("dashes of", "cups of")
  defp should_label_as_unit_connector?(%Token{label: :word, text: "of"}, tokens, idx) do
    tokens_before = Enum.take(tokens, idx)
    prev_token = List.last(tokens_before)
    prev_token && prev_token.label == :unit
  end

  defp should_label_as_unit_connector?(_token, _tokens, _idx), do: false

  @doc """
  Returns a compact string representation of labeled tokens.

  ## Examples

      iex> Tokenizer.tokenize("1 cup diced tomatoes") |> Tokenizer.format()
      "[1:qty] [cup:unit] [diced:prep] [tomatoes:word]"
  """
  def format(tokens) when is_list(tokens) do
    tokens
    |> Enum.map(fn %Token{text: t, label: l} -> "[#{t}:#{l}]" end)
    |> Enum.join(" ")
  end

  @doc """
  Analyzes tokens and returns structured groupings.

  Groups consecutive :word tokens that likely form ingredient names,
  identifies alternatives (or patterns), etc.
  """
  def analyze(tokens) when is_list(tokens) do
    # Get tokens before "in" or "such as" for ingredient extraction
    # These introduce storage medium or examples, not ingredient names
    stop_labels = [:prep_in, :example_intro]
    main_tokens = case Enum.find_index(tokens, &(&1.label in stop_labels)) do
      nil -> tokens
      idx -> Enum.take(tokens, idx)
    end

    # Identify and expand "or" patterns only in main tokens (not in examples/storage)
    expanded_tokens = expand_or_patterns(main_tokens)

    %{
      tokens: tokens,
      expanded_tokens: expanded_tokens,
      quantity: extract_quantity(tokens),
      unit: extract_unit(tokens),
      preparations: extract_preparations(tokens),
      modifiers: extract_modifiers(tokens),
      word_groups: extract_word_groups(main_tokens),
      ingredients: extract_ingredients(expanded_tokens, main_tokens),
      storage_medium: extract_storage_medium(tokens),
      has_alternatives: has_alternatives?(main_tokens)
    }
  end

  @doc """
  Expands "or" patterns to identify alternative ingredients.

  Handles patterns like:
  - "avocado oil or coconut oil" -> [{["avocado", "oil"]}, {:or}, {["coconut", "oil"]}]
  - "white or yellow corn tortillas" -> detects shared suffix "corn tortillas"
  """
  def expand_or_patterns(tokens) do
    case find_or_pattern(tokens) do
      nil -> tokens
      pattern -> pattern
    end
  end

  # Find and analyze "or" patterns in tokens
  defp find_or_pattern(tokens) do
    # Find position of "or" conjunction
    or_positions = tokens
      |> Enum.with_index()
      |> Enum.filter(fn {t, _} -> t.label == :conj and t.text == "or" end)
      |> Enum.map(fn {_, idx} -> idx end)

    case or_positions do
      [] -> nil
      [or_idx | _] -> analyze_or_pattern(tokens, or_idx)
    end
  end

  # Analyze the structure around an "or" conjunction
  defp analyze_or_pattern(tokens, or_idx) do
    before_or = Enum.take(tokens, or_idx)
    after_or = Enum.drop(tokens, or_idx + 1)

    # Get word sequences before and after "or"
    words_before = get_trailing_words(before_or)
    words_after = get_leading_words(after_or)

    cond do
      # If no ingredient words on either side of "or", it's not an ingredient alternative
      # e.g., "bottles or cans Mexican beer" - the "or" is between containers
      length(words_before) == 0 or length(words_after) == 0 ->
        nil

      # Pattern: "X or Y Z" where Z is shared (e.g., "avocado oil or coconut oil")
      # Both sides end with the same word(s)
      length(words_before) >= 2 and length(words_after) >= 2 and
        List.last(words_before) == List.last(words_after) ->
        shared_suffix = find_shared_suffix(words_before, words_after)
        %{
          type: :shared_suffix,
          alternatives: [
            Enum.join(words_before, " "),
            Enum.join(words_after, " ")
          ],
          shared: Enum.join(shared_suffix, " ")
        }

      # Pattern: "X or Y Z+" where X is single word and Y Z+ has multiple
      # e.g., "white or yellow corn tortillas" - X modifies the same noun as Y
      length(words_before) == 1 and length(words_after) >= 2 ->
        [adj | rest] = words_after
        noun = Enum.join(rest, " ")
        %{
          type: :shared_noun,
          alternatives: [
            "#{hd(words_before)} #{noun}",
            "#{adj} #{noun}"
          ],
          shared: noun
        }

      # Simple alternatives: "X or Y"
      true ->
        %{
          type: :simple,
          alternatives: [
            Enum.join(words_before, " "),
            Enum.join(words_after, " ")
          ]
        }
    end
  end

  # Labels that can be part of ingredient name/alternative
  @ingredient_labels [:word, :mod]

  # Get trailing :word/:mod tokens from a list
  defp get_trailing_words(tokens) do
    tokens
    |> Enum.reverse()
    |> Enum.take_while(&(&1.label in @ingredient_labels))
    |> Enum.reverse()
    |> Enum.map(& &1.text)
  end

  # Get leading :word/:mod tokens from a list
  defp get_leading_words(tokens) do
    tokens
    |> Enum.take_while(&(&1.label in @ingredient_labels))
    |> Enum.map(& &1.text)
  end

  # Find shared suffix between two word lists
  defp find_shared_suffix(words1, words2) do
    words1
    |> Enum.reverse()
    |> Enum.zip(Enum.reverse(words2))
    |> Enum.take_while(fn {a, b} -> a == b end)
    |> Enum.map(fn {a, _} -> a end)
    |> Enum.reverse()
  end

  # Extract ingredient names from expanded tokens
  defp extract_ingredients(expanded, _main_tokens) when is_map(expanded) do
    expanded.alternatives
  end

  defp extract_ingredients(_expanded, main_tokens) when is_list(main_tokens) do
    extract_word_groups(main_tokens)
  end

  # Normalization
  defp normalize(text) do
    text
    |> String.trim()
    |> String.downcase()
    |> normalize_unicode_fractions()
    |> String.replace("–", "-")  # Normalize en-dash
    |> String.replace("—", "-")  # Normalize em-dash
    |> mark_note_phrases()
    |> String.replace(~r/\s+/, " ")
  end

  # Replace multi-word note phrases with a single marker token
  # The marker format is __NOTE_n__ where n is the phrase index
  defp mark_note_phrases(text) do
    @note_phrases
    |> Enum.with_index()
    |> Enum.reduce(text, fn {phrase, idx}, acc ->
      String.replace(acc, phrase, "__NOTE_#{idx}__")
    end)
  end

  @unicode_fractions %{
    "½" => "1/2", "⅓" => "1/3", "⅔" => "2/3",
    "¼" => "1/4", "¾" => "3/4",
    "⅕" => "1/5", "⅖" => "2/5", "⅗" => "3/5", "⅘" => "4/5",
    "⅙" => "1/6", "⅚" => "5/6",
    "⅛" => "1/8", "⅜" => "3/8", "⅝" => "5/8", "⅞" => "7/8"
  }

  defp normalize_unicode_fractions(text) do
    Enum.reduce(@unicode_fractions, text, fn {char, replacement}, acc ->
      # Add space before fraction if preceded by a digit (e.g., "1½" -> "1 1/2")
      acc
      |> String.replace(~r/(\d)#{Regex.escape(char)}/, "\\1 #{replacement}")
      |> String.replace(char, replacement)
    end)
  end

  # Tokenization - split on whitespace but keep some punctuation as separate tokens
  defp split_tokens(text) do
    # First, add spaces around punctuation we want as separate tokens
    text
    |> String.replace(~r/([,;()])/, " \\1 ")
    |> String.split(~r/\s+/, trim: true)
  end

  # Token labeling
  defp label_token(text, position) do
    # Check for note phrase markers and restore original text
    case Regex.run(~r/^__NOTE_(\d+)__$/, text) do
      [_, idx_str] ->
        idx = String.to_integer(idx_str)
        original_phrase = Enum.at(@note_phrases, idx)
        %Token{text: original_phrase, label: :note, position: position}

      nil ->
        label = classify_token(text)
        %Token{text: text, label: label, position: position}
    end
  end

  @punctuation [",", ";", "(", ")", "+"]
  @qty_connectors ["plus"]  # Words that connect quantities (like "+")

  defp classify_token(text) do
    # Strip trailing period for unit matching
    text_clean = String.replace(text, ~r/\.+$/, "")

    cond do
      # Punctuation (including + for compound quantities)
      text in @punctuation -> :punct

      # Quantity connectors (words that act like + between quantities)
      String.downcase(text) in @qty_connectors -> :punct

      # Note phrase markers (shouldn't reach here normally, but just in case)
      String.starts_with?(text, "__NOTE_") -> :note

      # Quantity patterns
      is_quantity?(text) -> :qty

      # Size pattern (e.g., "14-oz", "15-ounce")
      is_size?(text) -> :size

      # Units (check both with and without trailing period)
      String.downcase(text) in @units -> :unit
      String.downcase(text_clean) in @units -> :unit

      # Containers
      String.downcase(text) in @containers -> :container

      # Preparations
      String.downcase(text) in @preparations -> :prep

      # Modifiers
      String.downcase(text) in @modifiers -> :mod

      # Conjunctions
      String.downcase(text) in @conjunctions -> :conj

      # Notes (single-word notes)
      String.downcase(text) in @notes -> :note

      # "in" is a preposition that often starts a storage/packing phrase
      String.downcase(text) == "in" -> :prep_in

      # "such" and "preferably" start example phrases - these aren't ingredient names
      String.downcase(text) in ["such", "preferably"] -> :example_intro

      # Removable parts (seeds, ribs, etc.) - usually part of prep instructions
      String.downcase(text) in @removable_parts -> :part

      # Metric weights like "113g", "30ml" - these appear in parentheses as
      # metric equivalents (e.g., "1 cup (113g) flour") and should not be
      # extracted as ingredient names
      is_metric_weight?(text) -> :metric_weight

      # Default - likely part of ingredient name
      true -> :word
    end
  end

  # Quantity detection
  defp is_quantity?(text) do
    # Matches: 1, 2.5, 1/2, 1-2, 2-3
    Regex.match?(~r/^\d+([.,]\d+)?(\/\d+)?(-\d+([.,]\d+)?(\/\d+)?)?$/, text)
  end

  # Size detection (container size like "14-oz" or "14-oz.")
  defp is_size?(text) do
    Regex.match?(~r/^\d+([.,]\d+)?-(oz|ounce|ounces|g|gram|grams|ml|l)\.?$/i, text)
  end

  # Metric weight detection (like "113g", "30ml", "1.5kg")
  # These appear in parentheses as metric equivalents: "1 cup (113g) flour"
  # Matches: 113g, 30ml, 1.5kg, 240ml, 454g, etc.
  defp is_metric_weight?(text) do
    Regex.match?(~r/^\d+([.,]\d+)?(g|kg|ml|l)$/i, text)
  end

  # Analysis helpers
  defp extract_quantity(tokens) do
    tokens
    |> Enum.filter(&(&1.label == :qty))
    |> Enum.map(& &1.text)
  end

  defp extract_unit(tokens) do
    tokens
    |> Enum.find(&(&1.label == :unit))
    |> case do
      nil -> nil
      token -> token.text
    end
  end

  defp extract_preparations(tokens) do
    tokens
    |> Enum.filter(&(&1.label == :prep))
    |> Enum.map(& &1.text)
  end

  defp extract_modifiers(tokens) do
    tokens
    |> Enum.filter(&(&1.label == :mod))
    |> Enum.map(& &1.text)
  end

  # Extract groups of consecutive :word tokens
  # Splits on conjunctions, punctuation, "in" preposition, and part labels
  # Groups must contain at least one :word token (not just modifiers)
  defp extract_word_groups(tokens) do
    tokens
    |> Enum.chunk_by(fn t -> t.label in [:word, :mod] end)
    |> Enum.filter(fn chunk ->
      # Must have at least one :word token (not just modifiers)
      Enum.any?(chunk, &(&1.label == :word))
    end)
    |> Enum.map(fn chunk ->
      Enum.map(chunk, & &1.text) |> Enum.join(" ")
    end)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Extract storage/packing medium (e.g., "in adobo sauce", "in oil", "in water")
  """
  def extract_storage_medium(tokens) do
    # Find "in" token and get words after it
    case Enum.find_index(tokens, &(&1.label == :prep_in)) do
      nil -> nil
      idx ->
        tokens
        |> Enum.drop(idx + 1)
        |> Enum.take_while(&(&1.label == :word))
        |> Enum.map(& &1.text)
        |> Enum.join(" ")
        |> case do
          "" -> nil
          medium -> "in #{medium}"
        end
    end
  end

  defp has_alternatives?(tokens) do
    Enum.any?(tokens, &(&1.label == :conj and &1.text == "or"))
  end
end
