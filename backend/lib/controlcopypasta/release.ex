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
  Generates matching rules for top canonical ingredients.

  Options:
  - limit: Number of top ingredients to process (default: 200)
  """
  def generate_matching_rules(opts \\ []) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Controlcopypasta.Repo, fn _repo ->
        do_generate_matching_rules(opts)
      end)
  end

  defp do_generate_matching_rules(opts) do
    import Ecto.Query

    alias Controlcopypasta.Repo
    alias Controlcopypasta.Ingredients.CanonicalIngredient

    limit = Keyword.get(opts, :limit, 200)

    # Category-based rule templates
    category_rules = %{
      "protein" => %{
        "boost_words" => ["fresh", "raw"],
        "anti_patterns" => ["sauce", "broth", "stock", "gravy", "seasoning", "flavoring"]
      },
      "produce" => %{
        "boost_words" => ["fresh", "ripe", "raw", "organic"],
        "anti_patterns" => ["sauce", "paste", "puree", "canned", "dried", "juice", "extract"]
      },
      "dairy" => %{
        "boost_words" => ["fresh", "whole", "full-fat"],
        "anti_patterns" => ["free", "substitute", "alternative", "flavored"]
      },
      "grain" => %{
        "boost_words" => ["whole", "fresh"],
        "anti_patterns" => ["flour", "meal", "starch", "syrup"]
      },
      "spice" => %{
        "boost_words" => ["ground", "whole", "fresh"],
        "anti_patterns" => ["extract", "flavoring", "blend", "mix"]
      },
      "herb" => %{
        "boost_words" => ["fresh", "whole"],
        "anti_patterns" => ["dried", "extract", "oil", "paste"]
      },
      "oil" => %{
        "boost_words" => ["extra", "virgin", "pure", "cold-pressed"],
        "anti_patterns" => ["spray", "blend", "flavored"]
      },
      "sweetener" => %{
        "boost_words" => ["pure", "raw", "natural"],
        "anti_patterns" => ["free", "substitute", "flavored", "artificial"]
      },
      "nut" => %{
        "boost_words" => ["raw", "whole", "fresh", "roasted"],
        "anti_patterns" => ["butter", "milk", "flour", "oil", "extract"]
      },
      "legume" => %{
        "boost_words" => ["dried", "fresh", "whole"],
        "anti_patterns" => ["flour", "paste", "canned"]
      }
    }

    # Specific ingredient overrides
    ingredient_overrides = %{
      "chicken breast" => %{
        "boost_words" => ["boneless", "skinless", "breast", "fresh"],
        "anti_patterns" => ["thigh", "wing", "leg", "drumstick", "tender", "strip", "nugget"]
      },
      "chicken thigh" => %{
        "boost_words" => ["boneless", "skinless", "thigh", "fresh"],
        "anti_patterns" => ["breast", "wing", "leg", "drumstick"]
      },
      "ground beef" => %{
        "boost_words" => ["lean", "ground", "fresh"],
        "anti_patterns" => ["patty", "meatball", "seasoned"]
      },
      "tomato" => %{
        "boost_words" => ["fresh", "ripe", "roma", "cherry", "grape", "heirloom", "vine"],
        "anti_patterns" => ["sauce", "paste", "puree", "canned", "diced", "crushed", "sun-dried", "juice"],
        "exclude_patterns" => ["\\btomato\\s+sauce\\b", "\\btomato\\s+paste\\b"]
      },
      "garlic" => %{
        "boost_words" => ["fresh", "clove", "minced", "whole", "head"],
        "anti_patterns" => ["powder", "granulated", "paste", "salt", "bread", "spread"]
      },
      "garlic powder" => %{
        "boost_words" => ["powder", "granulated"],
        "anti_patterns" => ["fresh", "clove", "minced", "whole"],
        "required_words" => ["powder"]
      },
      "olive oil" => %{
        "boost_words" => ["extra", "virgin", "evoo", "pure"],
        "anti_patterns" => ["vegetable", "canola", "coconut", "spray"]
      },
      "butter" => %{
        "boost_words" => ["unsalted", "salted", "european", "grass-fed"],
        "anti_patterns" => ["peanut", "almond", "nut", "spread", "substitute"]
      },
      "onion" => %{
        "boost_words" => ["fresh", "yellow", "white", "red", "sweet", "vidalia"],
        "anti_patterns" => ["powder", "flakes", "dried", "soup", "rings", "fried"]
      },
      "egg" => %{
        "boost_words" => ["large", "fresh", "whole", "free-range", "organic"],
        "anti_patterns" => ["white", "yolk", "substitute", "beater", "noodle", "wash"]
      },
      "flour" => %{
        "boost_words" => ["all-purpose", "white", "wheat"],
        "anti_patterns" => ["almond", "coconut", "rice", "oat", "self-rising", "bread", "cake", "pastry"]
      },
      "sugar" => %{
        "boost_words" => ["white", "granulated", "cane"],
        "anti_patterns" => ["brown", "powdered", "confectioner", "raw", "coconut", "maple"]
      },
      "salt" => %{
        "boost_words" => ["kosher", "sea", "fine", "table"],
        "anti_patterns" => ["garlic", "onion", "celery", "seasoned", "pepper"]
      },
      "black pepper" => %{
        "boost_words" => ["black", "ground", "freshly", "cracked", "whole"],
        "anti_patterns" => ["white", "cayenne", "red", "bell"]
      },
      "milk" => %{
        "boost_words" => ["whole", "2%", "skim", "fresh"],
        "anti_patterns" => ["coconut", "almond", "oat", "soy", "condensed", "evaporated", "buttermilk"]
      },
      "parsley" => %{
        "boost_words" => ["fresh", "flat-leaf", "italian", "curly"],
        "anti_patterns" => ["dried", "flakes"]
      },
      "cilantro" => %{
        "boost_words" => ["fresh", "whole"],
        "anti_patterns" => ["dried", "coriander", "paste"]
      },
      "basil" => %{
        "boost_words" => ["fresh", "sweet", "thai"],
        "anti_patterns" => ["dried", "paste", "pesto"]
      }
    }

    # Get top ingredients by usage
    ingredients =
      CanonicalIngredient
      |> where([i], i.usage_count > 0)
      |> order_by([i], desc: i.usage_count)
      |> limit(^limit)
      |> Repo.all()

    IO.puts("Processing #{length(ingredients)} ingredients...")

    # Generate and apply rules
    updates =
      ingredients
      |> Enum.map(fn ing ->
        rules = case Map.get(ingredient_overrides, ing.name) do
          nil ->
            case Map.get(category_rules, ing.category) do
              nil -> nil
              template -> add_defaults(template)
            end
          override ->
            add_defaults(override)
        end
        {ing, rules}
      end)
      |> Enum.filter(fn {_ing, rules} -> rules != nil and map_size(rules) > 0 end)

    IO.puts("Generated rules for #{length(updates)} ingredients")

    Enum.each(updates, fn {ing, rules} ->
      ing
      |> Ecto.Changeset.change(matching_rules: rules)
      |> Repo.update!()
    end)

    IO.puts("Done! Updated #{length(updates)} ingredients with matching rules.")
  end

  defp add_defaults(rules) do
    rules
    |> Map.put_new("boost_amount", 0.05)
    |> Map.put_new("anti_penalty", 0.15)
    |> Map.put_new("required_words", [])
    |> Map.put_new("exclude_patterns", [])
  end

  @doc """
  Generates a JWT token for a user by email.
  Useful for testing admin endpoints.

  Example:
    ./bin/controlcopypasta eval "Controlcopypasta.Release.generate_token(\"user@example.com\")"
  """
  def generate_token(email) do
    load_app()
    # Start the app to get Guardian working
    Application.ensure_all_started(@app)

    alias Controlcopypasta.Accounts
    alias Controlcopypasta.Accounts.Guardian

    case Accounts.get_user_by_email(email) do
      nil ->
        IO.puts("Error: User not found: #{email}")
        {:error, :user_not_found}

      user ->
        {:ok, token, _claims} = Guardian.encode_and_sign(user, %{}, ttl: {30, :day})
        IO.puts("Token for #{email} (valid 30 days):")
        IO.puts(token)
        {:ok, token}
    end
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
