defmodule Controlcopypasta.Ingredients.Matching.Matcher do
  @moduledoc """
  Ingredient matching with cascading strategies.

  Attempts to match an ingredient name to a canonical ingredient using
  multiple strategies in order of confidence:

  | Strategy | Confidence |
  |----------|-----------|
  | `:exact` | 1.0 |
  | `:singularized` | 0.98 |
  | `:stripped_modifiers` | 0.95 |
  | `:singularized_stripped` | 0.93 |
  | `:dropped_leading_word` | 0.9 |
  | `:dropped_trailing_word` | 0.9 |
  | `:compound_split` | 0.85 |
  | `:compound_split_singularized` | 0.83 |
  | `:single_word` | 0.8 |
  | `:fuzzy_prefix` | 0.7 |
  | `:none` | 0.5 (no match) |

  Each strategy records which branch produced the match in the `:strategy`
  field. Do not try to recover the strategy from the confidence afterwards:
  `:dropped_leading_word` and `:dropped_trailing_word` share 0.9, and the
  IngredientScorer below overwrites the confidence with its own score, so the
  returned number need not be any of the constants above.

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
  - `strategy`: Which cascade branch produced the match (see table above)
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
  def match(name, lookup, opts \\ []) do
    normalized = String.downcase(name) |> String.trim()

    # `[]` starts collecting the attempt trail; `nil` disables it entirely so
    # the bulk-scan path allocates nothing extra.
    trail = if Keyword.get(opts, :trace, false), do: [], else: nil

    # Try original form first, then with hyphens replaced by spaces
    {result, trail} =
      case find_canonical_match(normalized, lookup, trail) do
        {nil, trail} ->
          dehyphenated = String.replace(normalized, "-", " ")

          if dehyphenated != normalized do
            find_canonical_match(dehyphenated, lookup, trail)
          else
            {nil, trail}
          end

        found ->
          found
      end

    result
    |> format_or_no_match(name)
    |> put_trail(finish_trail(trail))
  end

  defp format_or_no_match(nil, name) do
    %{
      name: name,
      canonical_name: nil,
      canonical_id: nil,
      confidence: 0.5,
      strategy: :none
    }
  end

  defp format_or_no_match(result, name), do: format_match_result(name, result)

  defp put_trail(result, nil), do: result
  defp put_trail(result, trail), do: Map.put(result, :match_trail, trail)

  # Format a successful match result (always a 5-tuple from find_canonical_match)
  defp format_match_result(
         name,
         {canonical_name, canonical_id, base_confidence, matching_rules, strategy}
       ) do
    apply_scoring(name, canonical_name, canonical_id, base_confidence, matching_rules, strategy)
  end

  # Apply IngredientScorer when matching_rules exist
  defp apply_scoring(name, canonical_name, canonical_id, base_confidence, nil, strategy) do
    %{
      name: name,
      canonical_name: canonical_name,
      canonical_id: canonical_id,
      confidence: base_confidence,
      strategy: strategy
    }
  end

  defp apply_scoring(name, canonical_name, canonical_id, base_confidence, rules, strategy) do
    score_result = IngredientScorer.score(name, rules, base_confidence)

    result = %{
      name: name,
      canonical_name: canonical_name,
      canonical_id: canonical_id,
      confidence: score_result.score,
      strategy: strategy
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

  Returns either:
  - `{canonical_name, canonical_id, confidence, matching_rules, strategy}`
  - `nil` (no match)
  """
  def find_canonical_match(name, lookup) do
    {result, _trail} = find_canonical_match(name, lookup, nil)
    result
  end

  @doc """
  Like `find_canonical_match/2`, but also returns the attempt trail.

  Pass `trail` as `[]` to collect attempts, or `nil` to skip collection
  entirely (the hot path -- bulk scans match hundreds of thousands of lines).

  Returns `{result_or_nil, trail}` where the trail is in attempt order.
  """
  def find_canonical_match(name, lookup, trail) do
    # Strategy 1: Exact match
    case try_key(lookup, name, :exact, trail) do
      {{:found, result, confidence_override}, trail} ->
        {with_confidence(result, confidence_override || 1.0, :exact), trail}

      {:not_found, trail} ->
        # Strategy 1b: Try singularized form
        singular = singularize_phrase(name)

        if singular != name do
          case try_key(lookup, singular, :singularized, trail) do
            {{:found, result, _}, trail} ->
              {with_confidence(result, 0.98, :singularized), trail}

            {:not_found, trail} ->
              try_partial_match(name, lookup, trail)
          end
        else
          try_partial_match(name, lookup, trail)
        end
    end
  end

  # Perform one lookup and record the attempt. This is the only place an
  # attempt is recorded, so the trail cannot drift out of step with the
  # control flow that produced it.
  defp try_key(lookup, key, strategy, trail) do
    result = lookup_get(lookup, key)
    {result, record(trail, strategy, key, result)}
  end

  # trail == nil means "not collecting"; every record/4 is then a no-op.
  defp record(nil, _strategy, _key, _result), do: nil

  defp record(trail, strategy, key, :not_found) do
    [%{strategy: strategy, tried: key, hit: false, canonical_name: nil} | trail]
  end

  defp record(trail, strategy, key, {:found, {canonical_name, _id, _rules}, _}) do
    [%{strategy: strategy, tried: key, hit: true, canonical_name: canonical_name} | trail]
  end

  defp note(nil, _entry), do: nil
  defp note(trail, entry), do: [entry | trail]

  @doc false
  # Trail is built by prepending, so callers see it newest-first until reversed.
  def finish_trail(nil), do: nil
  def finish_trail(trail), do: Enum.reverse(trail)

  # Normalize lookup results to handle both 2-tuple and 3-tuple values
  defp lookup_get(lookup, key) do
    case Map.get(lookup, key) do
      nil -> :not_found
      {name, id} -> {:found, {name, id, nil}, nil}
      {name, id, rules} -> {:found, {name, id, rules}, nil}
    end
  end

  # Convert normalized result to return tuple with confidence and the strategy
  # that produced it. The strategy is recorded here, at the branch that matched,
  # because it cannot be reconstructed from the confidence later.
  defp with_confidence({name, id, rules}, confidence, strategy) do
    {name, id, confidence, rules, strategy}
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
  defp try_partial_match(name, lookup, trail) do
    words = String.split(name, " ")

    # Strategy 2: Remove leading adjectives (fresh, large, etc.)
    stripped = strip_leading_modifiers(words)

    case try_key(lookup, stripped, :stripped_modifiers, trail) do
      {{:found, result, _}, trail} ->
        {with_confidence(result, 0.95, :stripped_modifiers), trail}

      {:not_found, trail} ->
        # Strategy 2b: Try singularized stripped form
        singular_stripped = singularize_phrase(stripped)

        if singular_stripped != stripped do
          case try_key(lookup, singular_stripped, :singularized_stripped, trail) do
            {{:found, result, _}, trail} ->
              {with_confidence(result, 0.93, :singularized_stripped), trail}

            {:not_found, trail} ->
              try_shorter_matches(words, lookup, trail)
          end
        else
          try_shorter_matches(words, lookup, trail)
        end
    end
  end

  defp strip_leading_modifiers(words) do
    words
    |> Enum.drop_while(&(String.downcase(&1) in @leading_modifiers))
    |> Enum.join(" ")
  end

  # Try progressively shorter versions
  defp try_shorter_matches(words, lookup, trail) when length(words) > 1 do
    # Try removing first word
    shorter_front = words |> tl() |> Enum.join(" ")

    case try_key(lookup, shorter_front, :dropped_leading_word, trail) do
      {{:found, result, _}, trail} ->
        {with_confidence(result, 0.9, :dropped_leading_word), trail}

      {:not_found, trail} ->
        # Try removing last word
        shorter_back = words |> Enum.take(length(words) - 1) |> Enum.join(" ")

        case try_key(lookup, shorter_back, :dropped_trailing_word, trail) do
          {{:found, result, _}, trail} ->
            {with_confidence(result, 0.9, :dropped_trailing_word), trail}

          {:not_found, trail} ->
            try_shorter_matches(tl(words), lookup, trail)
        end
    end
  end

  defp try_shorter_matches([single_word], lookup, trail) do
    case try_key(lookup, single_word, :single_word, trail) do
      {{:found, result, _}, trail} ->
        {with_confidence(result, 0.8, :single_word), trail}

      {:not_found, trail} ->
        # Try splitting compound words (e.g., "almondmilk" → "almond milk")
        case try_compound_split(single_word, lookup, trail) do
          {nil, trail} -> try_fuzzy_match(single_word, lookup, trail)
          found -> found
        end
    end
  end

  defp try_shorter_matches([], _lookup, trail), do: {nil, trail}

  # Try splitting a compound word at each position to find a match
  # e.g., "almondmilk" → tries "a lmondmilk", "al mondmilk", ... "almond milk", ...
  # This probes every split position, so recording each miss individually would
  # bury the rest of the trail. One summary entry is recorded instead.
  defp try_compound_split(word, lookup, trail) when byte_size(word) >= 6 do
    positions = 1..max(String.length(word) - 2, 0)//1

    found =
      Enum.find_value(positions, fn i ->
        {left, right} = String.split_at(word, i)
        spaced = "#{left} #{right}"

        case lookup_get(lookup, spaced) do
          {:found, result, _} ->
            {with_confidence(result, 0.85, :compound_split), spaced}

          :not_found ->
            singular = singularize_phrase(spaced)

            if singular != spaced do
              case lookup_get(lookup, singular) do
                {:found, result, _} ->
                  {with_confidence(result, 0.83, :compound_split_singularized), singular}

                :not_found ->
                  nil
              end
            end
        end
      end)

    case found do
      {{_name, _id, _conf, _rules, strategy} = result, key} ->
        {result, record(trail, strategy, key, {:found, {canonical_of(result), nil, nil}, nil})}

      nil ->
        {nil,
         note(trail, %{
           strategy: :compound_split,
           tried: "#{Enum.count(positions)} split positions of #{inspect(word)}",
           hit: false,
           canonical_name: nil
         })}
    end
  end

  defp try_compound_split(_word, _lookup, trail), do: {nil, trail}

  defp canonical_of({canonical_name, _id, _conf, _rules, _strategy}), do: canonical_name

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
  defp try_fuzzy_match(name, lookup, trail) do
    if fuzzy_candidate?(name) do
      do_fuzzy_match(name, lookup, trail)
    else
      {nil,
       note(trail, %{
         strategy: :fuzzy_prefix,
         tried: name,
         hit: false,
         canonical_name: nil,
         declined: "not a plausible head noun"
       })}
    end
  end

  defp do_fuzzy_match(name, lookup, trail) do
    candidates =
      lookup
      # Only the direction where a canonical is a leading fragment of the input
      # ("olive oil" inside "olive oil blend"). The reverse -- treating the input
      # as the first word of a longer canonical -- is not evidence: it turned
      # "cream" into "cream cheese", "short" into "short rib" and "chilli" into
      # "chilli sauce" across ~41,000 lines.
      |> Enum.filter(fn {key, _} -> String.starts_with?(name, key <> " ") end)
      # Sorted so the result never depends on map iteration order.
      |> Enum.sort_by(fn {key, _} -> {String.length(key), key} end)

    result = unique_fuzzy_match(candidates)

    entry = %{
      strategy: :fuzzy_prefix,
      tried: name,
      hit: result != nil,
      canonical_name: if(result, do: canonical_of(result)),
      # Several distinct neighbours means the match is declined on purpose.
      prefix_neighbours: Enum.map(candidates, fn {key, _} -> key end)
    }

    {result, note(trail, entry)}
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

  defp fuzzy_result({canonical_name, id}), do: {canonical_name, id, 0.7, nil, :fuzzy_prefix}

  defp fuzzy_result({canonical_name, id, rules}),
    do: {canonical_name, id, 0.7, rules, :fuzzy_prefix}

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
