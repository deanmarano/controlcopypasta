#!/usr/bin/env elixir
# Export ingredient data to CSVs for local analysis
#
# Run via: dokku enter controlcopypasta web /app/backend/bin/controlcopypasta eval "Code.eval_file(\"/app/scripts/export_ingredient_data.exs\")"
# Or locally: cd backend && mix run ../scripts/export_ingredient_data.exs
#
# Outputs:
#   - canonical_ingredients.csv - All canonical ingredients with usage stats
#   - ingredient_densities.csv - All density data with sources
#   - ingredients_without_density.csv - Ingredients missing density data
#   - density_enrichment_results.csv - Recent Oban job results for density queue

import Ecto.Query

alias Controlcopypasta.Repo
alias Controlcopypasta.Ingredients.{CanonicalIngredient, IngredientDensity}

defmodule CSVExporter do
  def export_all(output_dir \\ "/tmp") do
    IO.puts("Exporting ingredient data to #{output_dir}...")

    export_canonical_ingredients(output_dir)
    export_ingredient_densities(output_dir)
    export_ingredients_without_density(output_dir)
    export_density_job_results(output_dir)

    IO.puts("\nExport complete!")
  end

  def export_canonical_ingredients(output_dir) do
    IO.puts("\n1. Exporting canonical ingredients...")

    ingredients =
      from(ci in CanonicalIngredient,
        left_join: d in IngredientDensity, on: d.canonical_ingredient_id == ci.id,
        group_by: ci.id,
        select: %{
          id: ci.id,
          name: ci.name,
          display_name: ci.display_name,
          category: ci.category,
          usage_count: ci.usage_count,
          density_count: count(d.id),
          inserted_at: ci.inserted_at
        },
        order_by: [desc: ci.usage_count]
      )
      |> Repo.all()

    path = Path.join(output_dir, "canonical_ingredients.csv")

    csv_content =
      ["id,name,display_name,category,usage_count,density_count,inserted_at"] ++
      Enum.map(ingredients, fn i ->
        [
          i.id,
          escape_csv(i.name),
          escape_csv(i.display_name),
          escape_csv(i.category),
          i.usage_count || 0,
          i.density_count,
          i.inserted_at
        ]
        |> Enum.join(",")
      end)

    File.write!(path, Enum.join(csv_content, "\n"))
    IO.puts("   Wrote #{length(ingredients)} ingredients to #{path}")
  end

  def export_ingredient_densities(output_dir) do
    IO.puts("\n2. Exporting ingredient densities...")

    densities =
      from(d in IngredientDensity,
        join: ci in CanonicalIngredient, on: ci.id == d.canonical_ingredient_id,
        select: %{
          id: d.id,
          ingredient_id: ci.id,
          ingredient_name: ci.name,
          volume_unit: d.volume_unit,
          grams_per_unit: d.grams_per_unit,
          preparation: d.preparation,
          source: d.source,
          source_id: d.source_id,
          source_url: d.source_url,
          confidence: d.confidence,
          notes: d.notes,
          retrieved_at: d.retrieved_at
        },
        order_by: [asc: ci.name, asc: d.volume_unit]
      )
      |> Repo.all()

    path = Path.join(output_dir, "ingredient_densities.csv")

    csv_content =
      ["id,ingredient_id,ingredient_name,volume_unit,grams_per_unit,preparation,source,source_id,source_url,confidence,notes,retrieved_at"] ++
      Enum.map(densities, fn d ->
        [
          d.id,
          d.ingredient_id,
          escape_csv(d.ingredient_name),
          escape_csv(d.volume_unit),
          d.grams_per_unit,
          escape_csv(d.preparation),
          escape_csv(d.source),
          escape_csv(d.source_id),
          escape_csv(d.source_url),
          d.confidence,
          escape_csv(d.notes),
          d.retrieved_at
        ]
        |> Enum.join(",")
      end)

    File.write!(path, Enum.join(csv_content, "\n"))
    IO.puts("   Wrote #{length(densities)} density records to #{path}")
  end

  def export_ingredients_without_density(output_dir) do
    IO.puts("\n3. Exporting ingredients without density data...")

    density_subquery = from(d in IngredientDensity, select: d.canonical_ingredient_id)

    ingredients =
      from(ci in CanonicalIngredient,
        where: ci.id not in subquery(density_subquery),
        select: %{
          id: ci.id,
          name: ci.name,
          display_name: ci.display_name,
          category: ci.category,
          usage_count: ci.usage_count
        },
        order_by: [desc: ci.usage_count]
      )
      |> Repo.all()

    path = Path.join(output_dir, "ingredients_without_density.csv")

    csv_content =
      ["id,name,display_name,category,usage_count"] ++
      Enum.map(ingredients, fn i ->
        [
          i.id,
          escape_csv(i.name),
          escape_csv(i.display_name),
          escape_csv(i.category),
          i.usage_count || 0
        ]
        |> Enum.join(",")
      end)

    File.write!(path, Enum.join(csv_content, "\n"))
    IO.puts("   Wrote #{length(ingredients)} ingredients without density to #{path}")
  end

  def export_density_job_results(output_dir) do
    IO.puts("\n4. Exporting density enrichment job results...")

    # Get recent density jobs with their results
    jobs =
      from(j in Oban.Job,
        where: j.queue == "density",
        select: %{
          id: j.id,
          state: j.state,
          args: j.args,
          attempt: j.attempt,
          max_attempts: j.max_attempts,
          errors: j.errors,
          inserted_at: j.inserted_at,
          completed_at: j.completed_at
        },
        order_by: [desc: j.inserted_at],
        limit: 1000
      )
      |> Repo.all()

    # Enrich with ingredient names
    ingredient_ids = Enum.map(jobs, fn j -> j.args["canonical_ingredient_id"] end) |> Enum.uniq()

    ingredients_map =
      from(ci in CanonicalIngredient,
        where: ci.id in ^ingredient_ids,
        select: {ci.id, ci.name}
      )
      |> Repo.all()
      |> Map.new()

    path = Path.join(output_dir, "density_enrichment_results.csv")

    csv_content =
      ["job_id,ingredient_id,ingredient_name,state,attempt,max_attempts,error_count,last_error,inserted_at,completed_at"] ++
      Enum.map(jobs, fn j ->
        ingredient_id = j.args["canonical_ingredient_id"]
        ingredient_name = Map.get(ingredients_map, ingredient_id, "unknown")
        errors = j.errors || []
        last_error = case List.last(errors) do
          nil -> ""
          err -> err["error"] || ""
        end

        [
          j.id,
          ingredient_id,
          escape_csv(ingredient_name),
          j.state,
          j.attempt,
          j.max_attempts,
          length(errors),
          escape_csv(String.slice(last_error, 0, 200)),
          j.inserted_at,
          j.completed_at
        ]
        |> Enum.join(",")
      end)

    File.write!(path, Enum.join(csv_content, "\n"))
    IO.puts("   Wrote #{length(jobs)} job results to #{path}")
  end

  defp escape_csv(nil), do: ""
  defp escape_csv(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end
  defp escape_csv(value), do: to_string(value)
end

# Run the export
CSVExporter.export_all()
