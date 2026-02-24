defmodule Controlcopypasta.Import.ParserComparisonTest do
  @moduledoc """
  Tests that compare our parser output against Copy Me That reference data.

  This is the main driver for parser improvements. When a test fails,
  it means our parser isn't extracting data as well as CMT did.

  Workflow:
  1. Run `mix run scripts/generate_fixture.exs` to update baseline
  2. Run tests - they will fetch and parse URLs from fixture
  3. If a test fails, either:
     a. Fix the parser (if parser regressed)
     b. Regenerate fixture (if website changed)
  """
  use ExUnit.Case, async: false

  alias Controlcopypasta.Parser
  alias Controlcopypasta.Import.{Comparison, CmtFixture}

  # Set to true to run live HTTP tests (requires internet)
  # Set to false for CI/offline testing
  @live_tests System.get_env("LIVE_PARSER_TESTS") == "true"

  # Load recipes from fixture file
  @cmt_recipes CmtFixture.load!() |> Enum.filter(&(&1["url"] && &1["url"] != ""))

  describe "parser vs CMT comparison" do
    @tag :live
    test "parser extracts data matching CMT reference" do
      unless @live_tests do
        IO.puts("\nSkipping live parser tests. Set LIVE_PARSER_TESTS=true to enable.")
        assert true
      else
        results =
          @cmt_recipes
          |> Enum.filter(&(&1["url"] && &1["url"] != ""))
          |> Enum.map(&compare_recipe/1)

        # Print summary
        IO.puts("\n=== Parser Comparison Results ===")

        for {cmt, comparison, summary} <- results do
          IO.puts("\n#{cmt["name"]}")
          IO.puts("  URL: #{cmt["url"]}")
          IO.puts("  Score: #{Float.round(summary.score * 100, 1)}%")
          IO.puts("  Matches: #{summary.matches}/#{summary.total}")

          mismatches = Comparison.mismatches(comparison)

          if map_size(mismatches) > 0 do
            IO.puts("  Mismatches:")

            for {field, {:mismatch, details}} <- mismatches do
              IO.puts("    - #{field}:")
              IO.puts("      Parsed: #{inspect(details[:parsed], limit: 50)}")
              IO.puts("      Expected: #{inspect(details[:expected], limit: 50)}")
            end
          end
        end

        # Assert all recipes have good match rate
        for {cmt, _comparison, summary} <- results do
          assert summary.score >= 0.7,
                 "Parser score for '#{cmt["name"]}' is #{summary.score}, expected >= 0.7"
        end
      end
    end
  end

  describe "parser with mock HTML" do
    test "extracts recipe from standard JSON-LD" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {
          "@type": "Recipe",
          "name": "Test Recipe",
          "description": "A test description",
          "image": "https://example.com/image.jpg",
          "recipeIngredient": ["1 cup flour", "2 eggs"],
          "recipeInstructions": [
            {"@type": "HowToStep", "text": "Mix ingredients"},
            {"@type": "HowToStep", "text": "Bake at 350F"}
          ],
          "prepTime": "PT15M",
          "cookTime": "PT30M",
          "totalTime": "PT45M",
          "recipeYield": "4 servings"
        }
        </script>
      </head>
      <body></body>
      </html>
      """

      cmt = %{
        "name" => "Test Recipe",
        "description" => "A test description",
        "image" => "https://example.com/image.jpg",
        "ingredients" => ["1 cup flour", "2 eggs"],
        "instructions" => "Mix ingredients\nBake at 350F",
        "prepTime" => "15 mins",
        "cookTime" => "30 mins",
        "totalTime" => "45 mins",
        "yield" => "4 servings"
      }

      {:ok, parsed, _raw} = Controlcopypasta.Parser.JsonLd.extract(html)
      comparison = Comparison.compare(parsed, cmt)
      summary = Comparison.summary(comparison)

      assert summary.score == 1.0, "Expected perfect match, got: #{inspect(comparison)}"
    end

    test "handles AllRecipes-style JSON-LD with @graph" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@graph": [
            {"@type": "WebPage", "name": "Page"},
            {
              "@type": "Recipe",
              "name": "Pasta Carbonara",
              "description": "Classic Italian pasta",
              "recipeIngredient": ["400g spaghetti", "200g guanciale", "4 eggs"],
              "recipeInstructions": [
                {"@type": "HowToStep", "text": "Cook pasta"},
                {"@type": "HowToStep", "text": "Fry guanciale"},
                {"@type": "HowToStep", "text": "Mix eggs and cheese"},
                {"@type": "HowToStep", "text": "Combine all"}
              ],
              "prepTime": "PT10M",
              "cookTime": "PT20M"
            }
          ]
        }
        </script>
      </head>
      <body></body>
      </html>
      """

      cmt = %{
        "name" => "Pasta Carbonara",
        "description" => "Classic Italian pasta",
        "ingredients" => ["400g spaghetti", "200g guanciale", "4 eggs"],
        "instructions" => "Cook pasta\nFry guanciale\nMix eggs and cheese\nCombine all",
        "prepTime" => "10 mins",
        "cookTime" => "20 mins"
      }

      {:ok, parsed, _raw} = Controlcopypasta.Parser.JsonLd.extract(html)
      comparison = Comparison.compare(parsed, cmt)
      summary = Comparison.summary(comparison)

      # Allow some flexibility for format differences
      assert summary.score >= 0.8,
             "Score #{summary.score} below threshold. Mismatches: #{inspect(Comparison.mismatches(comparison))}"
    end

    test "handles instructions as plain strings" do
      html = """
      <html>
      <head>
        <script type="application/ld+json">
        {
          "@type": "Recipe",
          "name": "Simple Recipe",
          "recipeInstructions": ["Step one", "Step two", "Step three"]
        }
        </script>
      </head>
      <body></body>
      </html>
      """

      cmt = %{
        "name" => "Simple Recipe",
        "instructions" => "Step one\nStep two\nStep three"
      }

      {:ok, parsed, _raw} = Controlcopypasta.Parser.JsonLd.extract(html)
      comparison = Comparison.compare(parsed, cmt)

      assert comparison.instructions == :match
    end
  end

  # Helper to compare a single recipe
  defp compare_recipe(cmt) do
    case Parser.parse_url(cmt["url"]) do
      {:ok, parsed} ->
        comparison = Comparison.compare(parsed, cmt)
        summary = Comparison.summary(comparison)
        {cmt, comparison, summary}

      {:error, reason} ->
        IO.puts("Failed to parse #{cmt["url"]}: #{inspect(reason)}")
        # Return a failing comparison
        comparison = %{error: {:mismatch, %{reason: reason}}}
        {cmt, comparison, %{matches: 0, mismatches: 1, total: 1, score: 0.0}}
    end
  end
end
