defmodule Controlcopypasta.Import.ComparisonTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Import.Comparison

  describe "compare/2" do
    test "returns :match for identical titles" do
      parsed = %{title: "Chocolate Chip Cookies"}
      cmt = %{"name" => "Chocolate Chip Cookies"}

      result = Comparison.compare(parsed, cmt)
      assert result.title == :match
    end

    test "returns :match for titles differing only in case/whitespace" do
      parsed = %{title: "chocolate chip cookies"}
      cmt = %{"name" => "Chocolate Chip  Cookies"}

      result = Comparison.compare(parsed, cmt)
      assert result.title == :match
    end

    test "returns :mismatch with details for different titles" do
      parsed = %{title: "Chocolate Cookies"}
      cmt = %{"name" => "Chocolate Chip Cookies"}

      result = Comparison.compare(parsed, cmt)
      assert {:mismatch, details} = result.title
      assert details.parsed == "Chocolate Cookies"
      assert details.expected == "Chocolate Chip Cookies"
      assert details.similarity > 0
    end

    test "returns :both_nil when both values are nil" do
      parsed = %{description: nil}
      cmt = %{"description" => nil}

      result = Comparison.compare(parsed, cmt)
      assert result.description == :both_nil
    end

    test "compares ingredients as lists" do
      parsed = %{
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 cup sugar"}
        ]
      }

      cmt = %{
        "ingredients" => ["2 cups flour", "1 cup sugar"]
      }

      result = Comparison.compare(parsed, cmt)
      assert result.ingredients == :match
    end

    test "identifies missing and extra ingredients" do
      parsed = %{
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 tsp vanilla"}
        ]
      }

      cmt = %{
        "ingredients" => ["2 cups flour", "1 cup sugar"]
      }

      result = Comparison.compare(parsed, cmt)
      assert {:mismatch, details} = result.ingredients
      assert "1 cup sugar" in details.missing
      assert "1 tsp vanilla" in details.extra
    end

    test "compares instructions" do
      parsed = %{
        instructions: [
          %{"step" => 1, "text" => "Preheat oven to 350F"},
          %{"step" => 2, "text" => "Mix ingredients"}
        ]
      }

      cmt = %{
        "instructions" => "Preheat oven to 350F\nMix ingredients"
      }

      result = Comparison.compare(parsed, cmt)
      assert result.instructions == :match
    end

    test "compares time values" do
      parsed = %{prep_time_minutes: 15}
      cmt = %{"prepTime" => "15 mins"}

      result = Comparison.compare(parsed, cmt)
      assert result.prep_time_minutes == :match
    end

    test "handles hour time formats" do
      parsed = %{cook_time_minutes: 90}
      cmt = %{"cookTime" => "1 hour 30 mins"}

      result = Comparison.compare(parsed, cmt)
      assert result.cook_time_minutes == :match
    end

    test "strips HTML tags from parsed text" do
      parsed = %{title: "<b>Chocolate Chip</b> Cookies"}
      cmt = %{"name" => "Chocolate Chip Cookies"}

      result = Comparison.compare(parsed, cmt)
      assert result.title == :match
    end

    test "handles instructions with step prefixes in expected" do
      parsed = %{
        instructions: [
          %{"text" => "Preheat oven"},
          %{"text" => "Mix dry ingredients"}
        ]
      }

      cmt = %{
        "instructions" => "Step 1. Preheat oven\nStep 2. Mix dry ingredients"
      }

      result = Comparison.compare(parsed, cmt)
      assert result.instructions == :match
    end

    test "handles hours-only time format" do
      parsed = %{cook_time_minutes: 120}
      cmt = %{"cookTime" => "2 hours"}

      result = Comparison.compare(parsed, cmt)
      assert result.cook_time_minutes == :match
    end

    test "handles empty ingredient lists" do
      parsed = %{ingredients: []}
      cmt = %{"ingredients" => []}

      result = Comparison.compare(parsed, cmt)
      assert result.ingredients == :match
    end

    test "handles ingredients as newline-separated string" do
      parsed = %{
        ingredients: [
          %{"text" => "2 cups flour"},
          %{"text" => "1 cup sugar"}
        ]
      }

      cmt = %{
        "ingredients" => "2 cups flour\n1 cup sugar"
      }

      result = Comparison.compare(parsed, cmt)
      assert result.ingredients == :match
    end
  end

  describe "summary/1" do
    test "calculates match statistics" do
      comparison = %{
        title: :match,
        description: :both_nil,
        ingredients: :match,
        instructions: {:mismatch, %{}},
        prep_time_minutes: :match
      }

      summary = Comparison.summary(comparison)
      assert summary.matches == 4
      assert summary.mismatches == 1
      assert summary.total == 5
      assert summary.score == 0.8
    end
  end

  describe "mismatches/1" do
    test "returns only mismatched fields" do
      comparison = %{
        title: :match,
        description: {:mismatch, %{parsed: "A", expected: "B"}},
        ingredients: :match
      }

      result = Comparison.mismatches(comparison)
      assert map_size(result) == 1
      assert {:mismatch, _} = result.description
    end
  end
end
