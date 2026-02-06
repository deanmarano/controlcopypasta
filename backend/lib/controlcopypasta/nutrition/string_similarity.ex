defmodule Controlcopypasta.Nutrition.StringSimilarity do
  @moduledoc """
  String similarity functions for matching ingredient names to API results.

  Provides Jaro-Winkler similarity and other matching utilities to improve
  the accuracy of nutrition data lookups.
  """

  @doc """
  Calculates Jaro-Winkler similarity between two strings.

  Returns a value between 0.0 (no similarity) and 1.0 (identical).
  Jaro-Winkler gives higher scores to strings that match from the beginning.

  ## Examples

      iex> StringSimilarity.jaro_winkler("apple", "apple")
      1.0

      iex> StringSimilarity.jaro_winkler("apple", "apples")
      0.97...

      iex> StringSimilarity.jaro_winkler("apple", "orange")
      0.5...
  """
  def jaro_winkler(s1, s2) when is_binary(s1) and is_binary(s2) do
    s1 = String.downcase(s1)
    s2 = String.downcase(s2)

    if s1 == s2 do
      1.0
    else
      jaro = jaro_distance(s1, s2)
      # Winkler modification: boost score for common prefix
      prefix_len = common_prefix_length(s1, s2, 4)
      # Standard Winkler scaling factor is 0.1
      jaro + prefix_len * 0.1 * (1 - jaro)
    end
  end

  @doc """
  Calculates basic Jaro distance between two strings.

  Returns a value between 0.0 and 1.0.
  """
  def jaro_distance(s1, s2) when is_binary(s1) and is_binary(s2) do
    s1 = String.downcase(s1)
    s2 = String.downcase(s2)

    len1 = String.length(s1)
    len2 = String.length(s2)

    cond do
      len1 == 0 and len2 == 0 -> 1.0
      len1 == 0 or len2 == 0 -> 0.0
      true -> calculate_jaro(s1, s2, len1, len2)
    end
  end

  defp calculate_jaro(s1, s2, len1, len2) do
    # Match window
    match_distance = max(div(max(len1, len2), 2) - 1, 0)

    s1_chars = String.graphemes(s1)
    s2_chars = String.graphemes(s2)

    s1_matches = List.duplicate(false, len1)
    s2_matches = List.duplicate(false, len2)

    # Find matches
    {matches, s1_matches, s2_matches} =
      s1_chars
      |> Enum.with_index()
      |> Enum.reduce({0, s1_matches, s2_matches}, fn {c1, i}, {m, s1m, s2m} ->
        start = max(0, i - match_distance)
        finish = min(i + match_distance + 1, len2)

        {found, _j, s2m} =
          if start < finish do
            Enum.reduce_while(start..(finish - 1), {false, -1, s2m}, fn j, {_, _, s2m_acc} ->
              if Enum.at(s2m_acc, j) == false and Enum.at(s2_chars, j) == c1 do
                {:halt, {true, j, List.replace_at(s2m_acc, j, true)}}
              else
                {:cont, {false, -1, s2m_acc}}
              end
            end)
          else
            {false, -1, s2m}
          end

        if found do
          {m + 1, List.replace_at(s1m, i, true), s2m}
        else
          {m, s1m, s2m}
        end
      end)

    if matches == 0 do
      0.0
    else
      # Count transpositions
      s1_matched = for {c, i} <- Enum.with_index(s1_chars), Enum.at(s1_matches, i), do: c
      s2_matched = for {c, i} <- Enum.with_index(s2_chars), Enum.at(s2_matches, i), do: c

      transpositions =
        Enum.zip(s1_matched, s2_matched)
        |> Enum.count(fn {a, b} -> a != b end)
        |> div(2)

      # Jaro formula
      (matches / len1 + matches / len2 + (matches - transpositions) / matches) / 3.0
    end
  end

  defp common_prefix_length(s1, s2, max_len) do
    s1_chars = String.graphemes(s1)
    s2_chars = String.graphemes(s2)

    s1_chars
    |> Enum.zip(s2_chars)
    |> Enum.take(max_len)
    |> Enum.take_while(fn {a, b} -> a == b end)
    |> length()
  end

  @doc """
  Checks if the query is a meaningful substring of the target.

  Returns true if query appears in target as a complete word or phrase.

  ## Examples

      iex> StringSimilarity.meaningful_substring?("chicken", "chicken breast, raw")
      true

      iex> StringSimilarity.meaningful_substring?("apple cider vinegar", "apple")
      false  # query is not IN target
  """
  def meaningful_substring?(query, target) when is_binary(query) and is_binary(target) do
    query = String.downcase(query)
    target = String.downcase(target)

    # Query should be contained in target as a word boundary
    String.contains?(target, query) or
      word_boundary_match?(query, target)
  end

  defp word_boundary_match?(query, target) do
    # Check if query matches at word boundaries
    pattern = ~r/\b#{Regex.escape(query)}\b/
    Regex.match?(pattern, target)
  end

  @doc """
  Calculates word overlap score between query and target.

  Returns {matched_words, total_query_words, coverage_ratio}.

  ## Examples

      iex> StringSimilarity.word_overlap("apple cider vinegar", "vinegar, apple cider")
      {3, 3, 1.0}

      iex> StringSimilarity.word_overlap("apple cider vinegar", "apple, raw")
      {1, 3, 0.333...}
  """
  def word_overlap(query, target) when is_binary(query) and is_binary(target) do
    query_words = query |> String.downcase() |> String.split(~r/\s+/) |> MapSet.new()
    target_words = target |> String.downcase() |> String.split(~r/[\s,]+/) |> MapSet.new()

    matched = MapSet.intersection(query_words, target_words) |> MapSet.size()
    total = MapSet.size(query_words)
    coverage = if total > 0, do: matched / total, else: 0.0

    {matched, total, coverage}
  end

  @doc """
  Detects if target contains unrelated major words that suggest a bad match.

  Returns true if the target likely refers to something different.

  ## Examples

      iex> StringSimilarity.has_unrelated_words?("apple cider vinegar", "apple, raw, with skin")
      true  # "raw" and "skin" are unrelated to vinegar

      iex> StringSimilarity.has_unrelated_words?("chicken breast", "chicken, breast, meat only")
      false  # all words are related
  """
  def has_unrelated_words?(query, target) when is_binary(query) and is_binary(target) do
    query_words = query |> String.downcase() |> String.split(~r/\s+/) |> MapSet.new()
    target_words = target |> String.downcase() |> String.split(~r/[\s,]+/) |> MapSet.new()

    # Words in target that aren't in query
    extra_words = MapSet.difference(target_words, query_words)

    # Filter out common filler words
    filler_words = MapSet.new(~w(raw cooked fresh with without and or the a an of per
      from for in on by to as is are was be been being have has had
      only all not no also plus including includes included))

    significant_extra = MapSet.difference(extra_words, filler_words)

    # Check for unrelated food categories
    unrelated_indicators = MapSet.new(~w(
      raw skin seeds peel rind core pit bone shell husk pod stem
      meat flesh juice pulp extract oil butter flour powder ground
      whole sliced diced chopped minced crushed grated shredded
      dried frozen canned pickled roasted baked fried steamed
    ))

    # If target has indicator words not related to query, might be wrong
    has_indicators = not MapSet.disjoint?(significant_extra, unrelated_indicators)

    # More than 2 significant extra words is suspicious for simple ingredients
    too_many_extra = MapSet.size(significant_extra) > 2 and MapSet.size(query_words) <= 2

    has_indicators and too_many_extra
  end

  @doc """
  Comprehensive match score combining multiple signals.

  Returns a score from 0.0 to 1.0 where higher is better.

  Considers:
  - Jaro-Winkler similarity
  - Word overlap coverage
  - Substring match bonus
  - Penalty for unrelated words
  - Penalty for partial multi-word matches
  """
  def match_score(query, target) when is_binary(query) and is_binary(target) do
    query = String.downcase(String.trim(query))
    target = String.downcase(String.trim(target))

    # Base Jaro-Winkler
    jw = jaro_winkler(query, target)

    # Word overlap
    {matched, total, coverage} = word_overlap(query, target)

    # Substring bonus
    substring_bonus = if meaningful_substring?(query, target), do: 0.2, else: 0.0

    # Unrelated words penalty
    unrelated_penalty = if has_unrelated_words?(query, target), do: 0.3, else: 0.0

    # Partial match penalty: if query has multiple words but only some match,
    # this is likely a wrong match (e.g., "rice vinegar" matching "rice")
    partial_match_penalty =
      cond do
        total <= 1 -> 0.0  # Single word queries don't get this penalty
        coverage >= 0.9 -> 0.0  # Almost all words match
        matched <= 1 and total >= 2 -> 0.3  # Only 1 word matched out of 2+
        coverage < 0.5 -> 0.2  # Less than half the words matched
        true -> 0.0
      end

    # Combine scores
    score = jw * 0.4 + coverage * 0.4 + substring_bonus - unrelated_penalty - partial_match_penalty

    # Clamp to 0.0-1.0
    max(0.0, min(1.0, score))
  end

  @doc """
  Detects if a food name appears to be a prepared/processed product rather than
  a raw ingredient.

  Returns true for things like "Mushroom Ravioli", "Pasta Sauce", "Chicken Soup"
  that are prepared foods containing the ingredient rather than the ingredient itself.

  ## Examples

      iex> StringSimilarity.is_prepared_product?("Crimini Mushroom Ravioli")
      true

      iex> StringSimilarity.is_prepared_product?("Brown Mushrooms (Crimini Italian)")
      false

      iex> StringSimilarity.is_prepared_product?("Portobello Mushroom Pasta Sauce")
      true
  """
  @prepared_product_indicators ~w(
    sauce pasta ravioli lasagna pizza soup stew casserole
    sandwich wrap burrito taco quesadilla
    salad slaw coleslaw
    chips crackers cookies biscuits bread muffin cake pie
    cereal granola bar
    frozen dinner meal entree
    dip spread hummus
    juice drink smoothie shake
    ice cream yogurt pudding
    seasoning mix blend spice rub
    broth stock bouillon
    dressing marinade glaze
    jam jelly preserve marmalade
    syrup topping
    candy chocolate
    snack trail mix
  )

  def is_prepared_product?(food_name) when is_binary(food_name) do
    name = String.downcase(food_name)
    words = String.split(name, ~r/[\s,\-–—]+/)

    Enum.any?(@prepared_product_indicators, fn indicator ->
      indicator in words or String.contains?(name, indicator)
    end)
  end

  @doc """
  Detects if a query appears to be a raw/simple ingredient (not a branded product query).

  Returns true for queries like "crimini mushroom", "olive oil", "chicken breast"
  Returns false for queries like "Cheerios", "Classico Pasta Sauce"

  ## Examples

      iex> StringSimilarity.is_raw_ingredient_query?("crimini mushroom")
      true

      iex> StringSimilarity.is_raw_ingredient_query?("olive oil")
      true

      iex> StringSimilarity.is_raw_ingredient_query?("cheerios cereal")
      false
  """
  @raw_ingredient_patterns [
    # Simple ingredient patterns (1-3 words, no brand indicators)
    ~r/^[a-z]+(\s+[a-z]+){0,2}$/,
    # Ingredient with descriptor: "fresh basil", "dried oregano"
    ~r/^(fresh|dried|frozen|raw|cooked|ground|whole|organic|boneless|skinless)\s+[a-z]+/,
    # Ingredient with type: "olive oil", "sesame oil", "chicken breast"
    ~r/^[a-z]+\s+(oil|breast|thigh|leg|wing|fillet|steak|chop|roast|flour|sugar|salt|pepper|vinegar|juice|zest)$/
  ]

  def is_raw_ingredient_query?(query) when is_binary(query) do
    q = String.downcase(String.trim(query))

    # Short queries (1-3 words) without numbers are likely raw ingredients
    word_count = length(String.split(q))
    has_numbers = Regex.match?(~r/\d/, q)

    cond do
      # Contains numbers (likely a branded product or serving size)
      has_numbers -> false

      # Very short queries are likely raw ingredients
      word_count <= 2 -> true

      # Check for raw ingredient patterns
      Enum.any?(@raw_ingredient_patterns, &Regex.match?(&1, q)) -> true

      # Longer queries might be branded
      word_count > 3 -> false

      # Default to true for simple queries
      true -> true
    end
  end
end
