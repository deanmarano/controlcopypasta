defmodule Controlcopypasta.Ingredients.Matching.IngredientScorerTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Matching.IngredientScorer

  # Tolerance for floating point comparisons
  @epsilon 0.0001

  describe "score/3 with nil rules" do
    test "returns base score unchanged" do
      result = IngredientScorer.score("fresh tomato", nil, 0.9)

      assert_in_delta result.score, 0.9, @epsilon
      assert result.matched == true
      assert result.details.rules_applied == false
    end

    test "returns matched false when base score is 0" do
      result = IngredientScorer.score("something", nil, 0.0)

      assert_in_delta result.score, 0.0, @epsilon
      assert result.matched == false
    end
  end

  describe "score/3 with boost_words" do
    test "increases score for matching boost words" do
      rules = %{
        "boost_words" => ["fresh", "ripe"],
        "boost_amount" => 0.05
      }

      result = IngredientScorer.score("fresh tomato", rules, 0.9)

      assert_in_delta result.score, 0.95, @epsilon
      assert result.matched == true
      assert result.details.boost_count == 1
      assert_in_delta result.details.boost_adjustment, 0.05, @epsilon
    end

    test "increases score for multiple boost words" do
      rules = %{
        "boost_words" => ["boneless", "skinless"],
        "boost_amount" => 0.05
      }

      result = IngredientScorer.score("boneless skinless chicken breast", rules, 0.9)

      assert_in_delta result.score, 1.0, @epsilon  # clamped to max 1.0
      assert result.details.boost_count == 2
      assert_in_delta result.details.boost_adjustment, 0.1, @epsilon
    end

    test "uses default boost_amount when not specified" do
      rules = %{"boost_words" => ["fresh"]}

      result = IngredientScorer.score("fresh tomato", rules, 0.9)

      # Default is 0.05
      assert_in_delta result.score, 0.95, @epsilon
    end

    test "is case insensitive" do
      rules = %{"boost_words" => ["FRESH"]}

      result = IngredientScorer.score("Fresh Tomato", rules, 0.9)

      assert result.details.boost_count == 1
    end
  end

  describe "score/3 with anti_patterns" do
    test "decreases score for matching anti-patterns" do
      rules = %{
        "anti_patterns" => ["sauce", "paste"],
        "anti_penalty" => 0.15
      }

      result = IngredientScorer.score("tomato sauce", rules, 0.9)

      assert_in_delta result.score, 0.75, @epsilon
      assert result.matched == true
      assert result.details.anti_count == 1
      assert_in_delta result.details.anti_adjustment, 0.15, @epsilon
    end

    test "decreases score for multiple anti-patterns" do
      rules = %{
        "anti_patterns" => ["powder", "granulated"],
        "anti_penalty" => 0.2
      }

      result = IngredientScorer.score("granulated garlic powder", rules, 0.9)

      assert_in_delta result.score, 0.5, @epsilon
      assert result.details.anti_count == 2
      assert_in_delta result.details.anti_adjustment, 0.4, @epsilon
    end

    test "clamps score to minimum 0.0" do
      rules = %{
        "anti_patterns" => ["sauce", "paste", "puree", "canned"],
        "anti_penalty" => 0.3
      }

      result = IngredientScorer.score("canned tomato sauce", rules, 0.5)

      assert_in_delta result.score, 0.0, @epsilon
      assert result.details.anti_count == 2
    end

    test "uses default anti_penalty when not specified" do
      rules = %{"anti_patterns" => ["sauce"]}

      result = IngredientScorer.score("tomato sauce", rules, 0.9)

      # Default is 0.15
      assert_in_delta result.score, 0.75, @epsilon
    end
  end

  describe "score/3 with combined boost and anti" do
    test "applies both boost and anti adjustments" do
      rules = %{
        "boost_words" => ["fresh"],
        "anti_patterns" => ["dried"],
        "boost_amount" => 0.05,
        "anti_penalty" => 0.15
      }

      # Fresh tomato: base 0.9 + boost 0.05 = 0.95
      result = IngredientScorer.score("fresh tomato", rules, 0.9)
      assert_in_delta result.score, 0.95, @epsilon

      # Dried tomato: base 0.9 - anti 0.15 = 0.75
      result = IngredientScorer.score("dried tomato", rules, 0.9)
      assert_in_delta result.score, 0.75, @epsilon
    end
  end

  describe "score/3 with exclude_patterns" do
    test "returns 0 score when exclude pattern matches" do
      rules = %{
        "exclude_patterns" => ["\\btomato\\s+sauce\\b"]
      }

      result = IngredientScorer.score("tomato sauce", rules, 0.9)

      assert_in_delta result.score, 0.0, @epsilon
      assert result.matched == false
      assert result.details.excluded == true
      assert result.details.reason == :exclude_pattern_matched
    end

    test "does not exclude when pattern does not match" do
      rules = %{
        "exclude_patterns" => ["\\btomato\\s+sauce\\b"]
      }

      result = IngredientScorer.score("fresh tomato", rules, 0.9)

      assert_in_delta result.score, 0.9, @epsilon
      assert result.matched == true
      assert result.details.excluded == false
    end

    test "handles invalid regex gracefully" do
      rules = %{
        "exclude_patterns" => ["[invalid regex"]
      }

      result = IngredientScorer.score("fresh tomato", rules, 0.9)

      # Invalid regex should be ignored, not crash
      assert_in_delta result.score, 0.9, @epsilon
      assert result.matched == true
    end
  end

  describe "score/3 with required_words" do
    test "returns 0 score when required word is missing" do
      rules = %{
        "required_words" => ["sauce"]
      }

      result = IngredientScorer.score("fresh tomato", rules, 0.9)

      assert_in_delta result.score, 0.0, @epsilon
      assert result.matched == false
      assert result.details.excluded == true
      assert result.details.reason == :missing_required_word
    end

    test "allows match when required word is present" do
      rules = %{
        "required_words" => ["sauce"]
      }

      result = IngredientScorer.score("tomato sauce", rules, 0.9)

      assert_in_delta result.score, 0.9, @epsilon
      assert result.matched == true
      assert result.details.excluded == false
    end

    test "requires all words to be present" do
      rules = %{
        "required_words" => ["cream", "cheese"]
      }

      # Missing "cheese"
      result = IngredientScorer.score("cream", rules, 0.9)
      assert_in_delta result.score, 0.0, @epsilon

      # Has both
      result = IngredientScorer.score("cream cheese", rules, 0.9)
      assert_in_delta result.score, 0.9, @epsilon
    end
  end

  describe "score_against_all/3" do
    test "scores multiple ingredients and sorts by score" do
      ingredients = [
        {"tomato_id", %{"anti_patterns" => ["sauce"], "anti_penalty" => 0.15}},
        {"tomato_sauce_id", %{"boost_words" => ["sauce"], "boost_amount" => 0.1}}
      ]

      results = IngredientScorer.score_against_all("tomato sauce", ingredients, 0.9)

      # tomato_sauce should score higher
      [{first_id, first_result}, {second_id, second_result}] = results

      assert first_id == "tomato_sauce_id"
      assert_in_delta first_result.score, 1.0, @epsilon  # 0.9 + 0.1

      assert second_id == "tomato_id"
      assert_in_delta second_result.score, 0.75, @epsilon  # 0.9 - 0.15
    end

    test "accepts a function for base score" do
      ingredients = [
        {"high_usage_id", nil},
        {"low_usage_id", nil}
      ]

      base_score_fn = fn
        "high_usage_id" -> 0.95
        "low_usage_id" -> 0.8
      end

      results = IngredientScorer.score_against_all("some ingredient", ingredients, base_score_fn)

      [{first_id, first_result}, {second_id, second_result}] = results

      assert first_id == "high_usage_id"
      assert_in_delta first_result.score, 0.95, @epsilon

      assert second_id == "low_usage_id"
      assert_in_delta second_result.score, 0.8, @epsilon
    end

    test "accepts a constant base score" do
      ingredients = [
        {"id1", %{"boost_words" => ["fresh"]}},
        {"id2", nil}
      ]

      results = IngredientScorer.score_against_all("fresh tomato", ingredients, 0.9)

      # Check that we have the expected scores (with floating point tolerance)
      [{_id1, result1}, {_id2, result2}] = results
      scores = [result1.score, result2.score]

      assert Enum.any?(scores, &(abs(&1 - 0.95) < @epsilon))
      assert Enum.any?(scores, &(abs(&1 - 0.9) < @epsilon))
    end
  end
end
