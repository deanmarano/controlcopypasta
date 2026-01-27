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
    # First try subcategory
    result = case ingredient.subcategory do
      "beef" -> "beef"
      "pork" -> "pork"
      "lamb" -> "lamb"
      "eggs" -> "egg"
      "poultry" -> infer_poultry_type(ingredient)
      "fish" -> infer_fish_type(ingredient, valid_animal_types)
      "shellfish" -> infer_shellfish_type(ingredient, valid_animal_types)
      _ -> nil
    end

    # If subcategory didn't match, try name and tags
    result || infer_from_name_and_tags(ingredient, valid_animal_types)
  end

  defp infer_from_name_and_tags(ingredient, valid_animal_types) do
    name = String.downcase(ingredient.name)
    tags = ingredient.tags || []

    # Check each valid animal type against name and tags
    Enum.find(valid_animal_types, fn animal_type ->
      String.contains?(name, animal_type) or animal_type in tags
    end)
    |> case do
      nil ->
        # Special cases not covered by direct matching
        cond do
          String.contains?(name, "oxtail") -> "beef"
          "pork" in tags -> "pork"
          "beef" in tags -> "beef"
          "chicken" in tags -> "chicken"
          "anchovy" in tags -> "anchovy"
          true -> nil
        end
      match -> match
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
    fish_types = ~w(salmon tuna cod sole anchovy sardine mackerel trout tilapia halibut bass)

    Enum.find(fish_types, fn fish ->
      String.contains?(name, fish) and fish in valid_animal_types
    end)
  end

  defp infer_shellfish_type(ingredient, valid_animal_types) do
    name = String.downcase(ingredient.name)
    # Include cephalopods (octopus, squid) with shellfish
    shellfish_types = ~w(shrimp crab lobster scallop clam mussel oyster octopus squid)

    Enum.find(shellfish_types, fn shellfish ->
      String.contains?(name, shellfish) and shellfish in valid_animal_types
    end)
  end

  @doc """
  Adds a new domain to the scraping queue with seed URLs.
  """
  def add_scrape_domain(domain, seed_urls) when is_list(seed_urls) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Controlcopypasta.Repo, fn _repo ->
        {:ok, result} = Controlcopypasta.Scraper.enqueue_domain(domain, seed_urls)
        IO.puts("Enqueued #{result.enqueued} URLs for domain: #{result.domain}")
        result
      end)
  end

  @doc """
  Adds halfbakedharvest.com and minimalistbaker.com to the scraping queue.
  """
  def add_new_domains do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Controlcopypasta.Repo, fn _repo ->
        # Half Baked Harvest
        {:ok, hbh} = Controlcopypasta.Scraper.enqueue_domain("halfbakedharvest.com", [
          "https://www.halfbakedharvest.com/category/recipes/"
        ])
        IO.puts("Half Baked Harvest: enqueued #{hbh.enqueued} URLs")

        # Minimalist Baker
        {:ok, mb} = Controlcopypasta.Scraper.enqueue_domain("minimalistbaker.com", [
          "https://minimalistbaker.com/recipes/"
        ])
        IO.puts("Minimalist Baker: enqueued #{mb.enqueued} URLs")

        :ok
      end)
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
