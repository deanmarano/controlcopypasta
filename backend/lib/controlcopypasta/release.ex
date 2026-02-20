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

  @doc """
  Backfills meal type tags on existing recipes from stored JSON-LD metadata.

  Example:
    ./bin/controlcopypasta eval "Controlcopypasta.Release.backfill_meal_tags(\"user@example.com\")"
    ./bin/controlcopypasta eval "Controlcopypasta.Release.backfill_meal_tags(\"user@example.com\", dry_run: true)"
    ./bin/controlcopypasta eval "Controlcopypasta.Release.backfill_meal_tags(\"user@example.com\", limit: 10)"
  """
  def backfill_meal_tags(email, opts \\ []) do
    load_app()
    Application.ensure_all_started(@app)

    import Ecto.Query

    alias Controlcopypasta.Repo
    alias Controlcopypasta.Recipes
    alias Controlcopypasta.Recipes.Recipe
    alias Controlcopypasta.Parser.{JsonLd, MealTypeMapper}

    dry_run = Keyword.get(opts, :dry_run, false)
    limit = Keyword.get(opts, :limit, nil)

    user =
      case Controlcopypasta.Accounts.get_user_by_email(email) do
        nil ->
          IO.puts("Error: User not found: #{email}")
          System.halt(1)

        user ->
          user
      end

    IO.puts("Backfilling meal tags for user: #{user.email}")

    query =
      Recipe
      |> where([r], r.user_id == ^user.id)
      |> where([r], is_nil(r.archived_at))
      |> order_by([r], asc: r.inserted_at)
      |> preload(:tags)

    query = if limit, do: limit(query, ^limit), else: query
    all_recipes = Repo.all(query)

    IO.puts("Found #{length(all_recipes)} recipes to process\n")
    if dry_run, do: IO.puts("DRY RUN - No tags will be applied\n")

    {tagged, skipped, failed} =
      all_recipes
      |> Enum.with_index(1)
      |> Enum.reduce({0, 0, 0}, fn {recipe, idx}, {tagged, skipped, failed} ->
        IO.puts("[#{idx}/#{length(all_recipes)}] #{recipe.title}")

        case do_backfill_recipe(recipe, dry_run) do
          :tagged -> {tagged + 1, skipped, failed}
          :dry_run -> {tagged + 1, skipped, failed}
          :skipped -> {tagged, skipped + 1, failed}
          :failed -> {tagged, skipped, failed + 1}
        end
      end)

    IO.puts("\n" <> String.duplicate("=", 50))
    IO.puts("Backfill Summary")
    IO.puts(String.duplicate("=", 50))

    if dry_run do
      IO.puts("Would tag: #{tagged}")
    else
      IO.puts("Tagged:    #{tagged}")
    end

    IO.puts("Skipped:   #{skipped}")
    IO.puts("Failed:    #{failed}")
  end

  defp do_backfill_recipe(recipe, dry_run) do
    alias Controlcopypasta.Recipes
    alias Controlcopypasta.Parser.{JsonLd, MealTypeMapper}

    {categories, keywords, source} =
      cond do
        recipe.source_json_ld && map_size(recipe.source_json_ld) > 0 ->
          cats = get_string_or_list(recipe.source_json_ld, "recipeCategory")
          kws = get_string_or_list(recipe.source_json_ld, "keywords")
          {cats, kws, :stored}

        recipe.source_url && recipe.source_url != "" ->
          case refetch_json_ld(recipe.source_url) do
            {:ok, json_ld} ->
              cats = get_string_or_list(json_ld, "recipeCategory")
              kws = get_string_or_list(json_ld, "keywords")
              {cats, kws, :refetched}

            {:error, reason} ->
              IO.puts("  x Failed: #{inspect(reason)}")
              {[], [], :error}
          end

        true ->
          {[], [], :none}
      end

    if source == :error do
      :failed
    else
      suggested = MealTypeMapper.suggest_meal_tags(categories, keywords)

      if suggested == [] do
        IO.puts("  ~ No meal type tags found")
        :skipped
      else
        existing_tag_names = Enum.map(recipe.tags, & &1.name) |> MapSet.new()
        new_tags = Enum.reject(suggested, &MapSet.member?(existing_tag_names, &1))

        if new_tags == [] do
          IO.puts("  ~ Already tagged: #{Enum.join(suggested, ", ")}")
          :skipped
        else
          if dry_run do
            IO.puts("  ? Would add: #{Enum.join(new_tags, ", ")} (from #{source})")
            :dry_run
          else
            new_tag_records =
              Enum.reduce(new_tags, [], fn name, acc ->
                case Recipes.get_or_create_tag(name) do
                  {:ok, tag} -> [tag | acc]
                  _ -> acc
                end
              end)

            all_tags = Enum.uniq_by(recipe.tags ++ new_tag_records, & &1.id)

            case recipe
                 |> Ecto.Changeset.change()
                 |> Ecto.Changeset.put_assoc(:tags, all_tags)
                 |> Controlcopypasta.Repo.update() do
              {:ok, _} ->
                IO.puts("  + Added: #{Enum.join(new_tags, ", ")} (from #{source})")
                :tagged

              {:error, changeset} ->
                IO.puts("  x Failed: #{inspect(changeset.errors)}")
                :failed
            end
          end
        end
      end
    end
  end

  defp refetch_json_ld(url) do
    alias Controlcopypasta.Parser.JsonLd

    Process.sleep(1_000)

    case Req.get(url,
           headers: [{"user-agent", "ControlCopyPasta/1.0 (Recipe Parser)"}],
           max_redirects: 5
         ) do
      {:ok, %Req.Response{status: 200, body: body}} when is_binary(body) ->
        case JsonLd.extract(body) do
          {:ok, _normalized, raw_json_ld} -> {:ok, raw_json_ld}
          {:error, reason} -> {:error, reason}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, "HTTP #{status}"}

      {:error, exception} ->
        {:error, "Fetch failed: #{inspect(exception)}"}
    end
  end

  defp get_string_or_list(map, key) do
    case Map.get(map, key) do
      nil -> []
      value when is_binary(value) ->
        value |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
      values when is_list(values) ->
        Enum.flat_map(values, fn
          v when is_binary(v) ->
            v |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
          _ -> []
        end)
      _ -> []
    end
  end

  @doc """
  Parses all unparsed recipe ingredients using TokenParser.

  Example:
    ./bin/controlcopypasta eval "Controlcopypasta.Release.parse_ingredients()"
    ./bin/controlcopypasta eval "Controlcopypasta.Release.parse_ingredients(limit: 100)"
  """
  def parse_ingredients(opts \\ []) do
    load_app()

    {:ok, _, _} =
      Ecto.Migrator.with_repo(Controlcopypasta.Repo, fn _repo ->
        do_parse_ingredients(opts)
      end)
  end

  defp do_parse_ingredients(opts) do
    import Ecto.Query

    alias Controlcopypasta.Repo
    alias Controlcopypasta.Recipes.Recipe
    alias Controlcopypasta.Ingredients
    alias Controlcopypasta.Ingredients.TokenParser

    limit = Keyword.get(opts, :limit)
    recipe_id = Keyword.get(opts, :recipe_id)

    IO.puts("Building ingredient lookup...")
    lookup = Ingredients.build_ingredient_lookup()

    force = Keyword.get(opts, :force, false)

    recipe_ids =
      cond do
        recipe_id ->
          [recipe_id]

        force ->
          # Re-parse ALL recipes with ingredients
          id_query =
            from r in Recipe,
              where: fragment("jsonb_array_length(?) > 0", r.ingredients),
              select: r.id

          id_query = if limit, do: Ecto.Query.limit(id_query, ^limit), else: id_query
          Repo.all(id_query, timeout: 120_000)

        true ->
          # Only unparsed ingredients
          id_query =
            from r in Recipe,
              where:
                fragment(
                  "jsonb_array_length(?) > 0 AND EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem WHERE elem->>'canonical_id' IS NULL OR elem->>'canonical_id' = '')",
                  r.ingredients,
                  r.ingredients
                ),
              select: r.id

          id_query = if limit, do: Ecto.Query.limit(id_query, ^limit), else: id_query
          Repo.all(id_query, timeout: 120_000)
      end

    total = length(recipe_ids)
    IO.puts("Found #{total} recipes to parse")

    # Process in batches to avoid memory issues
    batch_size = 200
    {success, failed} =
      recipe_ids
      |> Enum.chunk_every(batch_size)
      |> Enum.with_index()
      |> Enum.reduce({0, 0}, fn {batch_ids, batch_idx}, {s_acc, f_acc} ->
        recipes = Repo.all(from r in Recipe, where: r.id in ^batch_ids, select: [:id, :ingredients])

        {batch_s, batch_f} =
          Enum.reduce(recipes, {0, 0}, fn recipe, {s, f} ->
            try do
              parsed_ingredients =
                Enum.map(recipe.ingredients, fn ingredient ->
                  text = ingredient["text"]

                  if is_nil(text) or text == "" do
                    ingredient
                  else
                    parsed = TokenParser.parse(text, lookup: lookup)
                    jsonb = TokenParser.to_jsonb_map(parsed)
                    group = ingredient["group"]
                    if group, do: Map.put(jsonb, "group", group), else: jsonb
                  end
                end)

              canonical_ids =
                parsed_ingredients
                |> Enum.map(& &1["canonical_id"])
                |> Enum.reject(&is_nil/1)
                |> Enum.reject(&(&1 == ""))
                |> Enum.uniq()

              all_parsed =
                length(parsed_ingredients) > 0 and
                Enum.all?(parsed_ingredients, fn ing ->
                  (ing["canonical_id"] != nil and ing["canonical_id"] != "") or
                  ing["skipped"] == true
                end)

              recipe
              |> Ecto.Changeset.change(%{
                ingredients: parsed_ingredients,
                ingredients_parsed_at: DateTime.utc_now() |> DateTime.truncate(:second),
                ingredient_canonical_ids: canonical_ids,
                all_ingredients_parsed: all_parsed
              })
              |> Repo.update!()

              {s + 1, f}
            rescue
              e ->
                IO.puts("  Error parsing recipe #{recipe.id}: #{inspect(e)}")
                {s, f + 1}
            end
          end)

        done = s_acc + batch_s + f_acc + batch_f
        if rem(batch_idx + 1, 5) == 0 or done == total do
          IO.puts("Progress: #{done}/#{total} (#{s_acc + batch_s} ok, #{f_acc + batch_f} failed)")
        end

        {s_acc + batch_s, f_acc + batch_f}
      end)

    IO.puts("\nDone! #{success} parsed, #{failed} failed")
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end
end
