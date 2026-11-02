defmodule Controlcopypasta.Ingredients.Matching.MatcherTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Matching.Matcher

  # A lookup shaped like the real one, containing the specific collisions that the
  # fuzzy prefix strategy used to resolve incorrectly.
  @lookup %{
    "black pepper" => {"black pepper", "id-pepper"},
    "freshly ground black pepper" => {"black pepper", "id-pepper"},
    "cream cheese" => {"cream cheese", "id-cream-cheese"},
    "heavy cream" => {"heavy cream", "id-heavy-cream"},
    "short rib" => {"beef short rib", "id-short-rib"},
    "chilli sauce" => {"chili sauce", "id-chili-sauce"},
    "breadcrumbs" => {"breadcrumbs", "id-breadcrumbs"},
    "bread crumbs" => {"breadcrumbs", "id-breadcrumbs"},
    "nutmeg" => {"nutmeg", "id-nutmeg"},
    "olive oil" => {"olive oil", "id-olive-oil"}
  }

  describe "exact and modifier-stripping strategies still win" do
    test "exact match scores 1.0" do
      assert %{canonical_id: "id-nutmeg", confidence: 1.0} = Matcher.match("nutmeg", @lookup)
    end

    test "leading modifiers are stripped" do
      assert %{canonical_id: "id-olive-oil"} = Matcher.match("good-quality olive oil", @lookup)
    end

    test "a canonical that is a leading fragment of the input still matches" do
      assert %{canonical_id: "id-olive-oil"} = Matcher.match("olive oil blend", @lookup)
    end
  end

  describe "fuzzy prefix matching declines rather than guesses" do
    # Each of these previously returned a confident-looking 0.7 match to an
    # unrelated food, because the input happened to be the first word of a longer
    # canonical name and `Enum.find` accepted whichever one the map yielded first.
    test "an orphaned adverb does not match a canonical that starts with it" do
      assert %{canonical_id: nil} = Matcher.match("freshly", @lookup)
    end

    test "a single word is not matched to a longer compound canonical" do
      for fragment <- ~w(cream short chilli bread) do
        assert %{canonical_id: nil} = Matcher.match(fragment, @lookup),
               "#{fragment} should not resolve to a compound canonical that merely starts with it"
      end
    end

    test "ambiguous fragments are declined even when only one canonical collides" do
      # "short" collides solely with "short rib", but one leading word is still not
      # evidence that the ingredient is beef short rib.
      assert %{canonical_id: nil} = Matcher.match("short", @lookup)
    end

    test "words shorter than the fuzzy threshold are declined" do
      assert %{canonical_id: nil} = Matcher.match("cre", @lookup)
    end
  end

  describe "determinism" do
    test "match does not depend on map iteration order" do
      shuffled = @lookup |> Enum.shuffle() |> Map.new()

      for name <- ["freshly", "cream", "nutmeg", "olive oil blend", "short"] do
        assert Matcher.match(name, @lookup).canonical_id ==
                 Matcher.match(name, shuffled).canonical_id
      end
    end
  end
end
