defmodule Controlcopypasta.Ingredients.Matching.IngredientScorer do
  @moduledoc """
  Per-ingredient scoring for matching recipe ingredient lines to canonical ingredients.

  Each canonical ingredient can store its own matching rules (boost words, anti-patterns,
  required words) in the database. This module uses those rules to calculate a 0-1
  likelihood score for whether an input text refers to that ingredient.

  ## Scoring Algorithm

  1. Check `exclude_patterns` (regex) - if any match, return score 0.0
  2. Check `required_words` - if any are missing, return score 0.0
  3. Start with the base_score provided
  4. Count `boost_words` matches → add (count * boost_amount)
  5. Count `anti_patterns` (string) matches → subtract (count * anti_penalty)
  6. Clamp final score to [0.0, 1.0]

  ## Example Rules

      %{
        "boost_words" => ["fresh", "boneless"],
        "anti_patterns" => ["sauce", "powder"],
        "required_words" => [],
        "exclude_patterns" => ["\\\\bsauce\\\\b"],
        "boost_amount" => 0.05,
        "anti_penalty" => 0.15
      }
  """

  @default_boost_amount 0.05
  @default_anti_penalty 0.15

  @doc """
  Scores input text against an ingredient's matching rules.

  Returns a map with:
  - `score`: Float between 0.0 and 1.0
  - `matched`: Boolean indicating if the ingredient is a plausible match
  - `details`: Map with scoring breakdown (boost_count, anti_count, etc.)

  ## Parameters

  - `input`: The ingredient text to score (e.g., "2 boneless skinless chicken breasts")
  - `rules`: The matching rules map from the canonical ingredient (or nil)
  - `base_score`: The initial confidence score from the matcher (0.0-1.0)

  ## Examples

      iex> rules = %{"boost_words" => ["fresh"], "anti_patterns" => ["sauce"]}
      iex> IngredientScorer.score("fresh tomato", rules, 0.9)
      %{score: 0.95, matched: true, details: %{boost_count: 1, anti_count: 0}}

      iex> IngredientScorer.score("tomato sauce", rules, 0.9)
      %{score: 0.75, matched: true, details: %{boost_count: 0, anti_count: 1}}
  """
  def score(_input, nil, base_score) do
    # No rules defined - return base score unchanged
    %{
      score: base_score,
      matched: base_score > 0.0,
      details: %{
        rules_applied: false
      }
    }
  end

  def score(input, rules, base_score) when is_map(rules) do
    normalized_input = String.downcase(input)
    words = extract_words(normalized_input)

    # Step 1: Check exclude patterns (regex) - instant disqualification
    exclude_patterns = Map.get(rules, "exclude_patterns", [])

    if excluded_by_pattern?(normalized_input, exclude_patterns) do
      %{
        score: 0.0,
        matched: false,
        details: %{
          rules_applied: true,
          excluded: true,
          reason: :exclude_pattern_matched
        }
      }
    else
      # Step 2: Check required words - instant disqualification if missing
      required_words = Map.get(rules, "required_words", [])

      if missing_required_words?(words, required_words) do
        %{
          score: 0.0,
          matched: false,
          details: %{
            rules_applied: true,
            excluded: true,
            reason: :missing_required_word
          }
        }
      else
        # Step 3-5: Calculate score adjustments
        boost_words = Map.get(rules, "boost_words", [])
        anti_patterns = Map.get(rules, "anti_patterns", [])
        boost_amount = Map.get(rules, "boost_amount", @default_boost_amount)
        anti_penalty = Map.get(rules, "anti_penalty", @default_anti_penalty)

        boost_count = count_matches(words, boost_words)
        anti_count = count_matches(words, anti_patterns)

        boost_adjustment = boost_count * boost_amount
        anti_adjustment = anti_count * anti_penalty

        final_score = base_score + boost_adjustment - anti_adjustment
        clamped_score = clamp(final_score, 0.0, 1.0)

        %{
          score: clamped_score,
          matched: clamped_score > 0.0,
          details: %{
            rules_applied: true,
            excluded: false,
            boost_count: boost_count,
            anti_count: anti_count,
            boost_adjustment: boost_adjustment,
            anti_adjustment: anti_adjustment,
            base_score: base_score
          }
        }
      end
    end
  end

  @doc """
  Batch scores input against multiple ingredients.

  Useful when you want to find the best match among several candidate ingredients.

  Returns a list of `{ingredient_id, score_result}` tuples sorted by score descending.

  ## Parameters

  - `input`: The ingredient text to score
  - `ingredients`: List of `{ingredient_id, matching_rules}` tuples
  - `base_score_fn`: Function that takes ingredient_id and returns base score (0.0-1.0)

  ## Examples

      iex> ingredients = [
      ...>   {"tomato_id", %{"anti_patterns" => ["sauce"]}},
      ...>   {"tomato_sauce_id", %{"boost_words" => ["sauce"]}}
      ...> ]
      iex> IngredientScorer.score_against_all("tomato sauce", ingredients, fn _ -> 0.9 end)
      [{"tomato_sauce_id", %{score: 0.95, ...}}, {"tomato_id", %{score: 0.75, ...}}]
  """
  def score_against_all(input, ingredients, base_score_fn) when is_function(base_score_fn, 1) do
    ingredients
    |> Enum.map(fn {ingredient_id, rules} ->
      base_score = base_score_fn.(ingredient_id)
      result = score(input, rules, base_score)
      {ingredient_id, result}
    end)
    |> Enum.sort_by(fn {_id, result} -> -result.score end)
  end

  def score_against_all(input, ingredients, base_score) when is_number(base_score) do
    score_against_all(input, ingredients, fn _ -> base_score end)
  end

  # --- Private functions ---

  defp extract_words(text) do
    text
    |> String.replace(~r/[^\w\s]/, " ")
    |> String.split(~r/\s+/, trim: true)
    |> MapSet.new()
  end

  defp excluded_by_pattern?(_input, []), do: false

  defp excluded_by_pattern?(input, patterns) do
    Enum.any?(patterns, fn pattern ->
      case Regex.compile(pattern, [:caseless]) do
        {:ok, regex} -> Regex.match?(regex, input)
        {:error, _} -> false
      end
    end)
  end

  defp missing_required_words?(_words, []), do: false

  defp missing_required_words?(words, required) do
    required_set = required |> Enum.map(&String.downcase/1) |> MapSet.new()
    not MapSet.subset?(required_set, words)
  end

  defp count_matches(words, patterns) do
    patterns
    |> Enum.map(&String.downcase/1)
    |> Enum.count(&MapSet.member?(words, &1))
  end

  defp clamp(value, min, max) do
    value
    |> max(min)
    |> min(max)
  end
end
