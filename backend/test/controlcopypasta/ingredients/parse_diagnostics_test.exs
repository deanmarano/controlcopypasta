defmodule Controlcopypasta.Ingredients.ParseDiagnosticsTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Matching.Matcher
  alias Controlcopypasta.Ingredients.{ParseDiagnostics, TokenParser}

  @lookup %{
    "flour" => {"flour", "id-flour"},
    "tomato" => {"tomato", "id-tomato"},
    "olive oil" => {"olive oil", "id-olive-oil"},
    "almond milk" => {"almond milk", "id-almond-milk"},
    "chicken broth" => {"chicken broth", "id-chicken-broth"}
  }

  defp parse(text), do: TokenParser.parse(text, lookup: @lookup, diagnostics: true)

  describe "the Matcher records which strategy matched" do
    test "each cascade branch reports its own strategy" do
      cases = [
        {"flour", :exact},
        {"tomatoes", :singularized},
        {"fresh olive oil", :stripped_modifiers},
        {"almondmilk", :compound_split},
        {"definitelynotafood", :none}
      ]

      for {input, expected} <- cases do
        assert Matcher.match(input, @lookup).strategy == expected,
               "expected #{inspect(input)} to match via #{inspect(expected)}"
      end
    end

    test "the two branches that share confidence 0.9 stay distinguishable" do
      # Deliberately not a @leading_modifiers word, which would be stripped at
      # 0.95 before the shorter-match branch is ever reached.
      leading = Matcher.match("grandmas chicken broth", @lookup)
      trailing = Matcher.match("chicken broth powder", @lookup)

      assert leading.confidence == 0.9
      assert trailing.confidence == 0.9
      assert leading.strategy == :dropped_leading_word
      assert trailing.strategy == :dropped_trailing_word
    end

    test "strategy comes from the matcher, not from the final confidence" do
      # The IngredientScorer rewrites confidence using matching rules, so the
      # number no longer equals the branch constant. The strategy must survive.
      rules = %{"boost_words" => ["organic"]}
      lookup = %{"flour" => {"flour", "id-flour", rules}}

      match = Matcher.match("organic flour", lookup)

      assert match.canonical_id == "id-flour"
      assert match.strategy == :stripped_modifiers
    end
  end

  describe "the attempt trail" do
    test "is only collected when tracing is asked for" do
      refute Map.has_key?(Matcher.match("flour", @lookup), :match_trail)
      assert Map.has_key?(Matcher.match("flour", @lookup, trace: true), :match_trail)
    end

    test "an exact hit records a single successful attempt" do
      assert [%{strategy: :exact, tried: "flour", hit: true, canonical_name: "flour"}] =
               Matcher.match("flour", @lookup, trace: true).match_trail
    end

    test "records the keys that missed before the one that hit, in order" do
      trail = Matcher.match("grandmas chicken broth", @lookup, trace: true).match_trail

      assert Enum.map(trail, & &1.strategy) == [
               :exact,
               :stripped_modifiers,
               :dropped_leading_word
             ]

      assert Enum.map(trail, & &1.tried) == [
               "grandmas chicken broth",
               "grandmas chicken broth",
               "chicken broth"
             ]

      assert Enum.map(trail, & &1.hit) == [false, false, true]
    end

    test "exactly one attempt hits, and it is the last one" do
      trail = Matcher.match("almondmilk", @lookup, trace: true).match_trail

      assert Enum.count(trail, & &1.hit) == 1
      assert List.last(trail).hit
      assert List.last(trail).strategy == :compound_split
    end

    test "an unmatched name records every strategy tried and no hit" do
      trail = Matcher.match("lovage", @lookup, trace: true).match_trail

      assert Enum.all?(trail, &(&1.hit == false))
      assert :fuzzy_prefix in Enum.map(trail, & &1.strategy)
    end

    test "compound split is summarised rather than logged per split position" do
      trail = Matcher.match("lovage", @lookup, trace: true).match_trail
      attempt = Enum.find(trail, &(&1.strategy == :compound_split))

      assert attempt.tried =~ "split positions"
    end

    test "fuzzy matching records why it declined" do
      trail = Matcher.match("freshly", @lookup, trace: true).match_trail
      attempt = Enum.find(trail, &(&1.strategy == :fuzzy_prefix))

      assert attempt.declined =~ "head noun"
    end

    test "the trail reaches the diagnostics map" do
      map = parse("1 cup grandmas chicken broth").diagnostics |> ParseDiagnostics.to_map()

      strategies = Enum.map(map["match_trail"], & &1["strategy"])

      assert "exact" in strategies
      assert List.last(map["match_trail"])["hit"]
      assert List.last(map["match_trail"])["canonical_name"] == "chicken broth"
    end

    test "the trail agrees with the strategy it is shown next to" do
      diag = parse("1 cup grandmas chicken broth").diagnostics
      hit = Enum.find(diag.match_trail, & &1.hit)

      assert hit.strategy == diag.match_strategy
    end

    test "a line dropped by the preprocessor has no trail to show" do
      assert parse("A deep-fry thermometer").diagnostics.match_trail == nil
    end
  end

  describe "diagnostics on a parsed line" do
    test "reports tokens, parser and the recorded strategy" do
      diag = parse("2 cups flour").diagnostics

      assert diag.parser_used == :standard
      assert diag.match_strategy == :exact
      assert diag.token_string =~ "flour"
      assert is_integer(diag.parse_time_us)
    end

    test "to_map/1 is JSON-friendly" do
      map = parse("2 cups flour").diagnostics |> ParseDiagnostics.to_map()

      assert map["parser"] == "standard"
      assert map["match_strategy"] == "exact"
      assert is_list(map["warnings"])
    end
  end

  describe "lines the preprocessor drops" do
    test "equipment, section headers and salt-and-pepper each explain themselves" do
      cases = [
        {"A deep-fry thermometer", "kitchen equipment"},
        {"For the sauce:", "section header"},
        {"salt and pepper", "salt and pepper"}
      ]

      for {text, fragment} <- cases do
        diag = parse(text).diagnostics

        assert diag, "expected diagnostics for the skipped line #{inspect(text)}"
        assert diag.parser_used == :preprocessor_skip
        assert diag.match_strategy == :skipped

        assert Enum.any?(diag.warnings, &String.contains?(&1, fragment)),
               "expected a warning naming #{inspect(fragment)}, got #{inspect(diag.warnings)}"
      end
    end

    test "a skipped line still returns no ingredient" do
      parsed = parse("A 9-inch springform pan")

      assert parsed.primary_ingredient == nil
      assert parsed.ingredients == []
    end
  end

  describe "detect_warnings/2" do
    test "does not raise when there is no primary ingredient" do
      tokens = Controlcopypasta.Ingredients.Tokenizer.tokenize("some unmatched long phrase here")
      result = %{primary_ingredient: nil, is_alternative: false}

      warnings = ParseDiagnostics.detect_warnings(tokens, result)

      assert Enum.any?(warnings, &String.contains?(&1, "no match"))
    end

    test "flags an unmatched multi-word phrase" do
      diag = parse("3 sprigs of something nobody stocks").diagnostics

      assert diag.warnings != []
    end
  end

  describe "diagnostics are opt-in" do
    test "omitted unless asked for" do
      assert TokenParser.parse("2 cups flour", lookup: @lookup).diagnostics == nil
      assert TokenParser.parse("A deep-fry thermometer", lookup: @lookup).diagnostics == nil
    end
  end
end
