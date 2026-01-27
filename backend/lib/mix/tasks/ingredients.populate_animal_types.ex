defmodule Mix.Tasks.Ingredients.PopulateAnimalTypes do
  @moduledoc """
  Populates the animal_type field on canonical ingredients based on existing data.

  Uses subcategory, tags, and name to infer the animal type.

  ## Usage

      mix ingredients.populate_animal_types
      mix ingredients.populate_animal_types --dry-run
  """
  use Mix.Task
  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @valid_animal_types CanonicalIngredient.valid_animal_types()

  @shortdoc "Populate animal_type field on canonical ingredients"
  def run(args) do
    dry_run = "--dry-run" in args

    Mix.Task.run("app.start")

    if dry_run do
      IO.puts("=== DRY RUN MODE ===\n")
    end

    # Get all ingredients in protein category without animal_type
    ingredients =
      CanonicalIngredient
      |> where([i], i.category == "protein" and is_nil(i.animal_type))
      |> Repo.all()

    IO.puts("Found #{length(ingredients)} protein ingredients without animal_type\n")

    updates =
      ingredients
      |> Enum.map(fn ing ->
        animal_type = infer_animal_type(ing)
        {ing, animal_type}
      end)
      |> Enum.filter(fn {_ing, animal_type} -> animal_type != nil end)

    IO.puts("Will update #{length(updates)} ingredients:\n")

    # Group by animal type for display
    updates
    |> Enum.group_by(fn {_ing, animal_type} -> animal_type end)
    |> Enum.sort_by(fn {animal_type, _} -> animal_type end)
    |> Enum.each(fn {animal_type, items} ->
      IO.puts("  #{animal_type}: #{length(items)} ingredients")
      items
      |> Enum.take(5)
      |> Enum.each(fn {ing, _} ->
        IO.puts("    - #{ing.display_name}")
      end)
      if length(items) > 5 do
        IO.puts("    ... and #{length(items) - 5} more")
      end
    end)

    unless dry_run do
      IO.puts("\nUpdating database...")

      Enum.each(updates, fn {ing, animal_type} ->
        ing
        |> Ecto.Changeset.change(animal_type: animal_type)
        |> Repo.update!()
      end)

      IO.puts("Done! Updated #{length(updates)} ingredients.")
    else
      IO.puts("\n=== DRY RUN - No changes made ===")
    end
  end

  defp infer_animal_type(ingredient) do
    case ingredient.subcategory do
      "beef" -> "beef"
      "pork" -> "pork"
      "lamb" -> "lamb"
      "poultry" -> infer_poultry_type(ingredient)
      "fish" -> infer_fish_type(ingredient)
      "shellfish" -> infer_shellfish_type(ingredient)
      _ -> nil
    end
  end

  defp infer_poultry_type(ingredient) do
    name = String.downcase(ingredient.name)
    tags = ingredient.tags || []

    cond do
      String.contains?(name, "chicken") or "chicken" in tags -> "chicken"
      String.contains?(name, "turkey") or "turkey" in tags -> "turkey"
      String.contains?(name, "duck") or "duck" in tags -> "duck"
      # Default poultry to chicken if unspecified
      true -> nil
    end
  end

  defp infer_fish_type(ingredient) do
    name = String.downcase(ingredient.name)

    # Check each valid fish type
    fish_types = ~w(salmon tuna cod anchovy sardine mackerel trout tilapia halibut bass)

    Enum.find(fish_types, fn fish ->
      String.contains?(name, fish) and fish in @valid_animal_types
    end)
  end

  defp infer_shellfish_type(ingredient) do
    name = String.downcase(ingredient.name)

    # Check each valid shellfish type
    shellfish_types = ~w(shrimp crab lobster scallop clam mussel oyster)

    Enum.find(shellfish_types, fn shellfish ->
      String.contains?(name, shellfish) and shellfish in @valid_animal_types
    end)
  end
end
