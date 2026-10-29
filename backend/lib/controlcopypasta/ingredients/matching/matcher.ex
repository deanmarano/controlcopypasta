defmodule Controlcopypasta.Ingredients.Matching.Matcher do
  @moduledoc """
  Ingredient matching with cascading strategies.

  Attempts to match an ingredient name to a canonical ingredient using
  multiple strategies in order of confidence:

  1. Exact match (1.0)
  2. Singularized exact match (0.98)
  3. Stripped modifiers match (0.95)
  4. Singularized stripped match (0.93)
  5. Progressively shorter matches (0.9)
  6. Single word match (0.8)
  7. Fuzzy prefix match (0.7)

  When the lookup includes matching_rules (3-tuple values), the IngredientScorer
  is applied to adjust confidence based on boost words, anti-patterns, etc.
  """

  alias Controlcopypasta.Ingredients.Parsing.Singularizer
  alias Controlcopypasta.Ingredients.Matching.IngredientScorer

  @doc """
  Matches an ingredient name to a canonical ingredient.

  Supports two lookup formats:
  - Legacy: `%{name => {canonical_name, canonical_id}}`
  - With rules: `%{name => {canonical_name, canonical_id, matching_rules}}`

  Returns a map with:
  - `name`: Original input name
  - `canonical_name`: Matched canonical name (or nil)
  - `canonical_id`: Matched canonical ID (or nil)
  - `confidence`: Match confidence (0.0-1.0)
  - `scoring_details`: Optional map with scoring breakdown (when rules applied)

  ## Examples

      iex> lookup = %{"olive oil" => {"olive oil", "id123"}}
      iex> Matcher.match("olive oil", lookup)
      %{name: "olive oil", canonical_name: "olive oil", canonical_id: "id123", confidence: 1.0}

      iex> Matcher.match("fresh basil", %{"basil" => {"basil", "id456"}})
      %{name: "fresh basil", canonical_name: "basil", canonical_id: "id456", confidence: 0.95}

      iex> rules = %{"boost_words" => ["boneless", "skinless"]}
      iex> lookup = %{"chicken breast" => {"chicken breast", "id789", rules}}
      iex> Matcher.match("boneless skinless chicken breast", lookup)
      %{name: "...", canonical_name: "chicken breast", canonical_id: "id789",
        confidence: 1.0, scoring_details: %{boost_count: 2, ...}}
  """
  def match(name, lookup) do
    normalized = String.downcase(name) |> String.trim()

    # Try original form first, then with hyphens replaced by spaces
    case find_canonical_match(normalized, lookup) do
      nil ->
        dehyphenated = String.replace(normalized, "-", " ")

        if dehyphenated != normalized do
          case find_canonical_match(dehyphenated, lookup) do
            nil -> %{name: name, canonical_name: nil, canonical_id: nil, confidence: 0.5}
            result -> format_match_result(name, result)
          end
        else
          %{name: name, canonical_name: nil, canonical_id: nil, confidence: 0.5}
        end

      result ->
        format_match_result(name, result)
    end
  end

  # Format a successful match result (always a 4-tuple from find_canonical_match)
  defp format_match_result(name, {canonical_name, canonical_id, base_confidence, matching_rules}) do
    apply_scoring(name, canonical_name, canonical_id, base_confidence, matching_rules)
  end

  # Apply IngredientScorer when matching_rules exist
  defp apply_scoring(name, canonical_name, canonical_id, base_confidence, nil) do
    %{
      name: name,
      canonical_name: canonical_name,
      canonical_id: canonical_id,
      confidence: base_confidence
    }
  end

  defp apply_scoring(name, canonical_name, canonical_id, base_confidence, matching_rules) do
    score_result = IngredientScorer.score(name, matching_rules, base_confidence)

    result = %{
      name: name,
      canonical_name: canonical_name,
      canonical_id: canonical_id,
      confidence: score_result.score
    }

    # Only include scoring_details if rules were actually applied
    if score_result.details[:rules_applied] do
      Map.put(result, :scoring_details, score_result.details)
    else
      result
    end
  end

  @doc """
  Find canonical match using various strategies.

  Returns one of:
  - `{canonical_name, canonical_id, confidence, matching_rules}` (with rules)
  - `{canonical_name, canonical_id, confidence}` (legacy)
  - `nil` (no match)
  """
  def find_canonical_match(name, lookup) do
    # Strategy 1: Exact match
    case lookup_get(lookup, name) do
      {:found, result, confidence_override} ->
        with_confidence(result, confidence_override || 1.0)

      :not_found ->
        # Strategy 1b: Try singularized form
        singular = singularize_phrase(name)

        if singular != name do
          case lookup_get(lookup, singular) do
            {:found, result, _} -> with_confidence(result, 0.98)
            :not_found -> try_partial_match(name, lookup)
          end
        else
          try_partial_match(name, lookup)
        end
    end
  end

  # Normalize lookup results to handle both 2-tuple and 3-tuple values
  defp lookup_get(lookup, key) do
    case Map.get(lookup, key) do
      nil -> :not_found
      {name, id} -> {:found, {name, id, nil}, nil}
      {name, id, rules} -> {:found, {name, id, rules}, nil}
    end
  end

  # Convert normalized result to return tuple with confidence
  defp with_confidence({name, id, rules}, confidence) do
    {name, id, confidence, rules}
  end

  # Leading modifiers to strip (adjectives that describe ingredient state/size)
  @leading_modifiers ~w(fresh dried frozen canned raw cooked large small medium
                        extra-large whole ground light dark unsalted salted organic
                        ripe unripe hot cold warm thin thick fine coarse
                        italian japanese chinese mexican thai french indian korean
                        greek spanish american english swedish turkish vietnamese
                        baby mini jumbo tiny
                        sweet spicy mild sharp aged smoked roasted toasted pickled
                        good-quality store-bought homemade prepared
                        red green yellow golden brown white black pure
                        plain boneless skinless lean low-fat nonfat full-fat
                        regular instant quick old-fashioned)

  # Try partial matching strategies (strip modifiers, shorten)
  defp try_partial_match(name, lookup) do
    words = String.split(name, " ")

    # Strategy 2: Remove leading adjectives (fresh, large, etc.)
    stripped = strip_leading_modifiers(words)

    case lookup_get(lookup, stripped) do
      {:found, result, _} ->
        with_confidence(result, 0.95)

      :not_found ->
        # Strategy 2b: Try singularized stripped form
        singular_stripped = singularize_phrase(stripped)

        if singular_stripped != stripped do
          case lookup_get(lookup, singular_stripped) do
            {:found, result, _} -> with_confidence(result, 0.93)
            :not_found -> try_shorter_matches(words, lookup)
          end
        else
          try_shorter_matches(words, lookup)
        end
    end
  end

  defp strip_leading_modifiers(words) do
    words
    |> Enum.drop_while(&(String.downcase(&1) in @leading_modifiers))
    |> Enum.join(" ")
  end

  # Try progressively shorter versions
  defp try_shorter_matches(words, lookup) when length(words) > 1 do
    # Try removing first word
    shorter_front = words |> tl() |> Enum.join(" ")

    case lookup_get(lookup, shorter_front) do
      {:found, result, _} ->
        with_confidence(result, 0.9)

      :not_found ->
        # Try removing last word
        shorter_back = words |> Enum.take(length(words) - 1) |> Enum.join(" ")

        case lookup_get(lookup, shorter_back) do
          {:found, result, _} -> with_confidence(result, 0.9)
          :not_found -> try_shorter_matches(tl(words), lookup)
        end
    end
  end

  defp try_shorter_matches([single_word], lookup) do
    case lookup_get(lookup, single_word) do
      {:found, result, _} ->
        with_confidence(result, 0.8)

      :not_found ->
        # Try splitting compound words (e.g., "almondmilk" → "almond milk")
        try_compound_split(single_word, lookup) || try_fuzzy_match(single_word, lookup)
    end
  end

  defp try_shorter_matches([], _lookup), do: nil

  # Try splitting a compound word at each position to find a match
  # e.g., "almondmilk" → tries "a lmondmilk", "al mondmilk", ... "almond milk", ...
  defp try_compound_split(word, lookup) when byte_size(word) >= 6 do
    1..max(String.length(word) - 2, 0)//1
    |> Enum.find_value(fn i ->
      {left, right} = String.split_at(word, i)
      spaced = "#{left} #{right}"

      case lookup_get(lookup, spaced) do
        {:found, result, _} ->
          with_confidence(result, 0.85)

        :not_found ->
          singular = singularize_phrase(spaced)

          if singular != spaced do
            case lookup_get(lookup, singular) do
              {:found, result, _} -> with_confidence(result, 0.83)
              :not_found -> nil
            end
          end
      end
    end)
  end

  defp try_compound_split(_word, _lookup), do: nil

  # Words that can never be a head noun on their own. The tokenizer can orphan
  # one of these into its own ingredient group (splitting "freshly grated nutmeg"
  # on the prep verb leaves a bare "freshly"), and without this guard the prefix
  # search below happily resolves the orphan to whatever canonical shares its
  # prefix -- "freshly" became "freshly ground black pepper" on ~1,000 lines.
  @never_head_nouns ~w(freshly finely thinly coarsely roughly lightly thickly
                       evenly firmly loosely very extra more less about
                       plus optional divided reserved)

  # Conservative fuzzy matching.
  #
  # This is the last resort in the cascade, so it must decline rather than guess:
  # a wrong answer here outranks a correct 1.0 match elsewhere in the same line
  # when the bogus group happens to come first. It therefore matches only when
  # the input can plausibly be a food and exactly one canonical is a prefix
  # neighbour. Anything ambiguous returns nil and surfaces for review instead.
  defp try_fuzzy_match(name, lookup) do
    if fuzzy_candidate?(name) do
      lookup
      # Only the direction where a canonical is a leading fragment of the input
      # ("olive oil" inside "olive oil blend"). The reverse -- treating the input
      # as the first word of a longer canonical -- is not evidence: it turned
      # "cream" into "cream cheese", "short" into "short rib" and "chilli" into
      # "chilli sauce" across ~41,000 lines.
      |> Enum.filter(fn {key, _} -> String.starts_with?(name, key <> " ") end)
      # Sorted so the result never depends on map iteration order.
      |> Enum.sort_by(fn {key, _} -> {String.length(key), key} end)
      |> unique_fuzzy_match()
    end
  end

  defp fuzzy_candidate?(name) do
    String.length(name) >= 4 and
      name not in @never_head_nouns and
      name not in @leading_modifiers and
      not String.ends_with?(name, "ly")
  end

  # Only a single, unambiguous neighbour is accepted. Several candidates means we
  # cannot tell "cream" -> "cream cheese" from "cream" -> "heavy cream", and
  # picking either one invents data.
  defp unique_fuzzy_match([{_key, value}]), do: fuzzy_result(value)

  defp unique_fuzzy_match([{_key, value} | [_ | _] = rest]) do
    if Enum.all?(rest, fn {_, other} -> canonical_id(other) == canonical_id(value) end) do
      # Every candidate is an alias of the same canonical, so there is no ambiguity.
      fuzzy_result(value)
    end
  end

  defp unique_fuzzy_match([]), do: nil

  defp fuzzy_result({canonical_name, id}), do: {canonical_name, id, 0.7, nil}
  defp fuzzy_result({canonical_name, id, rules}), do: {canonical_name, id, 0.7, rules}

  defp canonical_id({_name, id}), do: id
  defp canonical_id({_name, id, _rules}), do: id

  @doc """
  Singularize a multi-word phrase by singularizing the last word.

  ## Examples

      iex> Matcher.singularize_phrase("red peppers")
      "red pepper"

      iex> Matcher.singularize_phrase("cherry tomatoes")
      "cherry tomato"
  """
  def singularize_phrase(phrase) do
    words = String.split(phrase, " ")

    case words do
      [] ->
        phrase

      [single] ->
        Singularizer.singularize(single)

      multiple ->
        last = List.last(multiple)
        rest = Enum.take(multiple, length(multiple) - 1)
        singular_last = Singularizer.singularize(last)
        Enum.join(rest ++ [singular_last], " ")
    end
  end
end
