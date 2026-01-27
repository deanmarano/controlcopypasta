defmodule Controlcopypasta.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix installed.
  """
  @app :controlcopypasta

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  @doc """
  Populates animal_type field on canonical ingredients based on existing data.
  """
  def populate_animal_types do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Controlcopypasta.Repo, fn _repo ->
        do_populate_animal_types()
      end)
  end

  defp do_populate_animal_types do
    import Ecto.Query

    alias Controlcopypasta.Repo
    alias Controlcopypasta.Ingredients.CanonicalIngredient

    valid_animal_types = CanonicalIngredient.valid_animal_types()

    # Get all ingredients in protein category without animal_type
    ingredients =
      CanonicalIngredient
      |> where([i], i.category == "protein" and is_nil(i.animal_type))
      |> Repo.all()

    IO.puts("Found #{length(ingredients)} protein ingredients without animal_type")

    updates =
      ingredients
      |> Enum.map(fn ing ->
        animal_type = infer_animal_type(ing, valid_animal_types)
        {ing, animal_type}
      end)
      |> Enum.filter(fn {_ing, animal_type} -> animal_type != nil end)

    IO.puts("Updating #{length(updates)} ingredients...")

    Enum.each(updates, fn {ing, animal_type} ->
      ing
      |> Ecto.Changeset.change(animal_type: animal_type)
      |> Repo.update!()
    end)

    IO.puts("Done! Updated #{length(updates)} ingredients.")
  end

  defp infer_animal_type(ingredient, valid_animal_types) do
    case ingredient.subcategory do
      "beef" -> "beef"
      "pork" -> "pork"
      "lamb" -> "lamb"
      "poultry" -> infer_poultry_type(ingredient)
      "fish" -> infer_fish_type(ingredient, valid_animal_types)
      "shellfish" -> infer_shellfish_type(ingredient, valid_animal_types)
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
      true -> nil
    end
  end

  defp infer_fish_type(ingredient, valid_animal_types) do
    name = String.downcase(ingredient.name)
    fish_types = ~w(salmon tuna cod anchovy sardine mackerel trout tilapia halibut bass)

    Enum.find(fish_types, fn fish ->
      String.contains?(name, fish) and fish in valid_animal_types
    end)
  end

  defp infer_shellfish_type(ingredient, valid_animal_types) do
    name = String.downcase(ingredient.name)
    shellfish_types = ~w(shrimp crab lobster scallop clam mussel oyster)

    Enum.find(shellfish_types, fn shellfish ->
      String.contains?(name, shellfish) and shellfish in valid_animal_types
    end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
