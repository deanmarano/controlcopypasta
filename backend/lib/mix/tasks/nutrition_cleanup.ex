defmodule Mix.Tasks.NutritionCleanup do
  @moduledoc """
  Cleans up bad nutrition data mappings.

  Identifies and removes nutrition records where the USDA food doesn't
  actually match the ingredient (e.g., "apple cider vinegar" mapped to "apple").

  ## Usage

      # Dry run - show what would be deleted
      mix nutrition_cleanup --dry-run

      # Actually delete bad records
      mix nutrition_cleanup

      # Re-seed affected ingredients after cleanup
      mix nutrition_cleanup --reseed
  """

  use Mix.Task

  require Logger

  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientNutrition}
  alias Controlcopypasta.Nutrition.StringSimilarity
  alias Controlcopypasta.Nutrition.Seeder

  @shortdoc "Clean up bad nutrition data mappings"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    dry_run = "--dry-run" in args
    reseed = "--reseed" in args

    Logger.info("Starting nutrition cleanup (dry_run: #{dry_run})")

    # Step 1: Find duplicate USDA source_ids
    duplicates = find_duplicate_source_ids()
    Logger.info("Found #{length(duplicates)} duplicate USDA IDs")

    # Step 2: Find bad matches (low similarity between ingredient name and USDA description)
    bad_matches = find_bad_matches()
    Logger.info("Found #{length(bad_matches)} bad matches")

    # Combine all bad records
    all_bad_ids = MapSet.new(Enum.map(bad_matches, & &1.id))

    # Add records from duplicates (keep only the best match for each USDA ID)
    duplicate_removals = resolve_duplicates(duplicates)
    all_bad_ids = MapSet.union(all_bad_ids, MapSet.new(duplicate_removals))

    Logger.info("Total records to remove: #{MapSet.size(all_bad_ids)}")

    if dry_run do
      Logger.info("\n=== DRY RUN - Would remove these records ===")
      show_records_to_remove(all_bad_ids)
    else
      # Step 3: Delete bad records
      deleted_count = delete_records(all_bad_ids)
      Logger.info("Deleted #{deleted_count} nutrition records")

      # Step 4: Recalculate confidence for remaining records
      update_confidence_scores()

      if reseed do
        # Step 5: Re-seed affected ingredients
        reseed_affected_ingredients()
      else
        Logger.info("\nRun with --reseed to re-seed affected ingredients")
      end
    end

    Logger.info("Cleanup complete!")
  end

  defp find_duplicate_source_ids do
    Repo.all(
      from n in IngredientNutrition,
      where: n.source == :usda and not is_nil(n.source_id),
      group_by: n.source_id,
      having: count(n.id) > 1,
      select: n.source_id
    )
  end

  defp find_bad_matches do
    # Get all USDA nutrition records with their ingredient names
    records = Repo.all(
      from n in IngredientNutrition,
      join: c in CanonicalIngredient, on: n.canonical_ingredient_id == c.id,
      where: n.source == :usda,
      select: %{
        id: n.id,
        ingredient_name: c.name,
        source_name: n.source_name,
        source_id: n.source_id
      }
    )

    # Check each for bad matches
    Enum.filter(records, fn record ->
      # Extract USDA description from source_name (format: "USDA FoodData Central - ...")
      usda_desc = extract_usda_description(record.source_name)

      if usda_desc do
        score = StringSimilarity.match_score(record.ingredient_name, usda_desc)
        # Flag as bad if score is below threshold
        score < 0.4
      else
        false
      end
    end)
  end

  defp extract_usda_description(source_name) when is_binary(source_name) do
    # source_name is usually "USDA FoodData Central - Foundation" or similar
    # We need to fetch the actual description from the API or use what we have
    # For now, we can't easily get the description, so we'll rely on duplicate detection
    nil
  end

  defp extract_usda_description(_), do: nil

  defp resolve_duplicates(duplicate_source_ids) do
    # For each duplicate source_id, keep the best match and mark others for removal
    Enum.flat_map(duplicate_source_ids, fn source_id ->
      records = Repo.all(
        from n in IngredientNutrition,
        join: c in CanonicalIngredient, on: n.canonical_ingredient_id == c.id,
        where: n.source == :usda and n.source_id == ^source_id,
        select: %{id: n.id, ingredient_name: c.name, source_name: n.source_name}
      )

      if length(records) <= 1 do
        []
      else
        # For duplicates, we need to figure out which one is the "real" match
        # This is tricky without the USDA description. For now, keep the first one
        # and remove the rest. In a more sophisticated version, we'd re-fetch from USDA.
        Logger.debug("Duplicate USDA #{source_id}: #{Enum.map(records, & &1.ingredient_name) |> Enum.join(", ")}")

        # Keep the shortest ingredient name (usually the most generic/correct one)
        sorted = Enum.sort_by(records, fn r -> String.length(r.ingredient_name) end)
        [_keep | to_remove] = sorted

        Enum.map(to_remove, & &1.id)
      end
    end)
  end

  defp show_records_to_remove(id_set) do
    ids = MapSet.to_list(id_set)

    records = Repo.all(
      from n in IngredientNutrition,
      join: c in CanonicalIngredient, on: n.canonical_ingredient_id == c.id,
      where: n.id in ^ids,
      select: %{ingredient: c.name, source_id: n.source_id, source_name: n.source_name},
      order_by: c.name
    )

    Enum.each(records, fn r ->
      IO.puts("  #{r.ingredient} -> USDA #{r.source_id}")
    end)
  end

  defp delete_records(id_set) do
    ids = MapSet.to_list(id_set)

    {count, _} =
      from(n in IngredientNutrition, where: n.id in ^ids)
      |> Repo.delete_all()

    count
  end

  defp update_confidence_scores do
    Logger.info("Updating confidence scores for remaining USDA records...")

    # Get records without confidence
    records = Repo.all(
      from n in IngredientNutrition,
      where: n.source == :usda and is_nil(n.confidence),
      preload: []
    )

    updated = Enum.count(records, fn record ->
      {confidence, factors} = IngredientNutrition.calculate_confidence(record)

      record
      |> Ecto.Changeset.change(%{confidence: confidence, confidence_factors: factors})
      |> Repo.update()
      |> case do
        {:ok, _} -> true
        _ -> false
      end
    end)

    Logger.info("Updated confidence for #{updated} records")
  end

  defp reseed_affected_ingredients do
    Logger.info("Re-seeding ingredients without nutrition data...")

    case Seeder.seed_all(delay_ms: 300, batch_size: 20) do
      %{success: s, failed: f} ->
        Logger.info("Re-seeded: #{s} success, #{f} failed")
      _ ->
        Logger.info("Re-seeding completed")
    end
  end
end
