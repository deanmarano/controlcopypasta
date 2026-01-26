defmodule Mix.Tasks.ParserCompare do
  @moduledoc """
  Compares parser output against Copy Me That reference data.

  Usage:
    mix parser_compare                    # Compare all CMT recipes with URLs
    mix parser_compare --limit 5          # Compare first 5 recipes
    mix parser_compare --url URL          # Compare single URL against CMT data
    mix parser_compare --sample           # Generate sample CMT export file

  The CMT export should be placed at test/fixtures/cmt_export.json
  or set CMT_EXPORT_PATH environment variable.
  """
  use Mix.Task

  alias Controlcopypasta.Parser
  alias Controlcopypasta.Import.{Comparison, CmtFixture}

  @shortdoc "Compare parser output against CMT reference data"

  def run(args) do
    Application.ensure_all_started(:req)

    {opts, _, _} =
      OptionParser.parse(args,
        switches: [limit: :integer, url: :string, sample: :boolean, verbose: :boolean]
      )

    cond do
      opts[:sample] ->
        generate_sample()

      opts[:url] ->
        compare_url(opts[:url], opts)

      true ->
        compare_all(opts)
    end
  end

  defp generate_sample do
    {:ok, path} = CmtFixture.save_sample()
    Mix.shell().info("Sample CMT export saved to: #{path}")
    Mix.shell().info("Edit this file with your actual CMT export data.")
  end

  defp compare_url(url, opts) do
    Mix.shell().info("Parsing: #{url}")

    case Parser.parse_url(url) do
      {:ok, parsed} ->
        Mix.shell().info("\nParsed data:")
        print_recipe(parsed, opts[:verbose])

        # Try to find matching CMT recipe
        cmt_recipe =
          CmtFixture.with_urls()
          |> Enum.find(fn r -> r["url"] == url end)

        if cmt_recipe do
          Mix.shell().info("\nFound matching CMT recipe!")
          comparison = Comparison.compare(parsed, cmt_recipe)
          print_comparison(cmt_recipe["name"], comparison)
        else
          Mix.shell().info("\nNo matching CMT recipe found for comparison.")
        end

      {:error, reason} ->
        Mix.shell().error("Failed to parse: #{inspect(reason)}")
    end
  end

  defp compare_all(opts) do
    recipes = CmtFixture.with_urls()

    if recipes == [] do
      Mix.shell().error("""
      No CMT recipes with URLs found.

      To get started:
        1. Run: mix parser_compare --sample
        2. Edit test/fixtures/cmt_export.json with your CMT export data
        3. Run: mix parser_compare
      """)

      System.halt(1)
    end

    limit = opts[:limit] || length(recipes)
    recipes = Enum.take(recipes, limit)

    Mix.shell().info("Comparing #{length(recipes)} recipes...\n")

    results =
      recipes
      |> Enum.with_index(1)
      |> Enum.map(fn {recipe, idx} ->
        Mix.shell().info("[#{idx}/#{length(recipes)}] #{recipe["name"]}")
        compare_single(recipe, opts)
      end)

    # Print summary
    print_summary(results)
  end

  defp compare_single(cmt_recipe, opts) do
    url = cmt_recipe["url"]

    case Parser.parse_url(url) do
      {:ok, parsed} ->
        comparison = Comparison.compare(parsed, cmt_recipe)
        summary = Comparison.summary(comparison)

        if opts[:verbose] do
          print_comparison(cmt_recipe["name"], comparison)
        else
          status =
            cond do
              summary.score == 1.0 -> "✓"
              summary.score >= 0.7 -> "~"
              true -> "✗"
            end

          Mix.shell().info(
            "  #{status} Score: #{Float.round(summary.score * 100, 1)}% (#{summary.matches}/#{summary.total})"
          )
        end

        {:ok, cmt_recipe["name"], summary}

      {:error, reason} ->
        Mix.shell().info("  ✗ Failed: #{inspect(reason)}")
        {:error, cmt_recipe["name"], reason}
    end
  end

  defp print_comparison(name, comparison) do
    summary = Comparison.summary(comparison)
    mismatches = Comparison.mismatches(comparison)

    Mix.shell().info("\n#{name}")
    Mix.shell().info("Score: #{Float.round(summary.score * 100, 1)}%")

    if map_size(mismatches) > 0 do
      Mix.shell().info("Mismatches:")

      for {field, {:mismatch, details}} <- mismatches do
        Mix.shell().info("  #{field}:")
        Mix.shell().info("    Parsed:   #{truncate(inspect(details[:parsed]))}")
        Mix.shell().info("    Expected: #{truncate(inspect(details[:expected]))}")

        if details[:similarity] do
          Mix.shell().info("    Similarity: #{Float.round(details[:similarity] * 100, 1)}%")
        end

        if details[:missing] && details[:missing] != [] do
          Mix.shell().info("    Missing: #{truncate(inspect(details[:missing]))}")
        end

        if details[:extra] && details[:extra] != [] do
          Mix.shell().info("    Extra: #{truncate(inspect(details[:extra]))}")
        end
      end
    end
  end

  defp print_summary(results) do
    {successful, failed} = Enum.split_with(results, &match?({:ok, _, _}, &1))

    total = length(results)
    perfect = Enum.count(successful, fn {:ok, _, s} -> s.score == 1.0 end)
    good = Enum.count(successful, fn {:ok, _, s} -> s.score >= 0.7 and s.score < 1.0 end)
    poor = Enum.count(successful, fn {:ok, _, s} -> s.score < 0.7 end)

    avg_score =
      if length(successful) > 0 do
        successful
        |> Enum.map(fn {:ok, _, s} -> s.score end)
        |> Enum.sum()
        |> Kernel./(length(successful))
      else
        0.0
      end

    Mix.shell().info("\n" <> String.duplicate("=", 50))
    Mix.shell().info("Summary")
    Mix.shell().info(String.duplicate("=", 50))
    Mix.shell().info("Total recipes:  #{total}")
    Mix.shell().info("Parse failures: #{length(failed)}")
    Mix.shell().info("Perfect (100%): #{perfect}")
    Mix.shell().info("Good (≥70%):    #{good}")
    Mix.shell().info("Poor (<70%):    #{poor}")
    Mix.shell().info("Average score:  #{Float.round(avg_score * 100, 1)}%")

    if length(failed) > 0 do
      Mix.shell().info("\nFailed to parse:")

      for {:error, name, _reason} <- failed do
        Mix.shell().info("  - #{name}")
      end
    end

    # List recipes needing improvement
    needs_work =
      successful
      |> Enum.filter(fn {:ok, _, s} -> s.score < 1.0 end)
      |> Enum.sort_by(fn {:ok, _, s} -> s.score end)

    if length(needs_work) > 0 do
      Mix.shell().info("\nRecipes needing parser improvements:")

      for {:ok, name, s} <- Enum.take(needs_work, 10) do
        Mix.shell().info("  #{Float.round(s.score * 100, 1)}% - #{name}")
      end
    end
  end

  defp print_recipe(recipe, verbose) do
    fields = [:title, :description, :ingredients, :instructions, :prep_time_minutes, :servings]

    for field <- fields do
      value = Map.get(recipe, field)

      if value && (verbose || field in [:title, :ingredients]) do
        Mix.shell().info("  #{field}: #{truncate(inspect(value))}")
      end
    end
  end

  defp truncate(str, max_len \\ 80) do
    if String.length(str) > max_len do
      String.slice(str, 0, max_len) <> "..."
    else
      str
    end
  end
end
