defmodule Controlcopypasta.Repo.Migrations.AddMoreCanonicalIngredients do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add more missing canonical ingredients
    ingredients = [
      # Oils
      %{
        name: "grapeseed oil",
        display_name: "Grapeseed Oil",
        category: "oil",
        aliases: ["grape seed oil"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Baking ingredients
      %{
        name: "flax meal",
        display_name: "Flax Meal",
        category: "grain",
        aliases: ["ground flax", "ground flaxseed", "flaxseed meal", "flax egg"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "meringue powder",
        display_name: "Meringue Powder",
        category: "baking",
        aliases: [],
        dietary_flags: ["vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "barley malt syrup",
        display_name: "Barley Malt Syrup",
        category: "sweetener",
        aliases: ["malt syrup", "barley malt"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "turbinado sugar",
        display_name: "Turbinado Sugar",
        category: "sweetener",
        aliases: ["raw sugar", "demerara sugar"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Breakfast/cereal
      %{
        name: "granola",
        display_name: "Granola",
        category: "grain",
        aliases: ["granola cereal"],
        dietary_flags: ["vegetarian", "dairy_free"]
      },

      # Chile powders
      %{
        name: "ancho chile powder",
        display_name: "Ancho Chile Powder",
        category: "spice",
        aliases: ["ancho chili powder", "ground ancho chile", "ground ancho"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "red chile powder",
        display_name: "Red Chile Powder",
        category: "spice",
        aliases: ["red chili powder", "ground red chile"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Sauces
      %{
        name: "chili sauce",
        display_name: "Chili Sauce",
        category: "condiment",
        aliases: ["chile sauce", "sambal", "sambal oelek"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "chipotle in adobo",
        display_name: "Chipotle in Adobo",
        category: "condiment",
        aliases: [
          "chipotle in adobo sauce",
          "chipotles in adobo",
          "chipotle peppers in adobo",
          "chipotle in adobo, minced"
        ],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Vegetables/sprouts
      %{
        name: "bean sprouts",
        display_name: "Bean Sprouts",
        category: "vegetable",
        aliases: ["mung bean sprouts", "sprouts"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Bread products
      %{
        name: "brioche",
        display_name: "Brioche",
        category: "grain",
        aliases: ["brioche bread", "brioche buns", "brioche rolls"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten", "eggs"],
        dietary_flags: ["vegetarian"]
      },
      %{
        name: "hoagie roll",
        display_name: "Hoagie Roll",
        category: "grain",
        aliases: ["hoagie rolls", "sub roll", "sub rolls", "submarine roll"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegetarian", "dairy_free"]
      },

      # Oats (from TODO - generic oats)
      %{
        name: "oats",
        display_name: "Oats",
        category: "grain",
        aliases: [
          "rolled oats",
          "old-fashioned oats",
          "quick oats",
          "instant oats",
          "oatmeal",
          "porridge oats"
        ],
        is_allergen: true,
        allergen_groups: ["gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },

      # Cheese blends (from TODO)
      %{
        name: "mexican cheese blend",
        display_name: "Mexican Cheese Blend",
        category: "dairy",
        aliases: ["mexican cheese", "queso blend", "taco cheese"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },
      %{
        name: "shredded cheese",
        display_name: "Shredded Cheese",
        category: "dairy",
        aliases: ["cheese blend", "mixed cheese"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      }
    ]

    for ing <- ingredients do
      aliases_sql = format_array(ing[:aliases] || [])
      allergen_sql = format_array(ing[:allergen_groups] || [])
      dietary_sql = format_array(ing[:dietary_flags] || [])

      execute """
      INSERT INTO canonical_ingredients (id, name, display_name, category, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        '#{ing.name}',
        '#{ing.display_name}',
        '#{ing.category}',
        ARRAY[#{aliases_sql}]::varchar[],
        #{ing[:is_allergen] || false},
        ARRAY[#{allergen_sql}]::varchar[],
        ARRAY[#{dietary_sql}]::varchar[],
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO UPDATE SET
        aliases = EXCLUDED.aliases,
        dietary_flags = EXCLUDED.dietary_flags,
        updated_at = EXCLUDED.updated_at
      """
    end

    # Also add aliases to existing ingredients
    # Add "unsweetened cocoa" as alias to cocoa powder
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'unsweetened cocoa')
    WHERE name = 'cocoa powder'
    AND NOT ('unsweetened cocoa' = ANY(aliases))
    """

    # Add "dutch-process cocoa" as alias to cocoa powder
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'dutch-process cocoa')
    WHERE name = 'cocoa powder'
    AND NOT ('dutch-process cocoa' = ANY(aliases))
    """
  end

  def down do
    ingredients_to_remove = [
      "grapeseed oil",
      "flax meal",
      "meringue powder",
      "barley malt syrup",
      "turbinado sugar",
      "granola",
      "ancho chile powder",
      "red chile powder",
      "chili sauce",
      "chipotle in adobo",
      "bean sprouts",
      "brioche",
      "hoagie roll",
      "oats",
      "mexican cheese blend",
      "shredded cheese"
    ]

    for name <- ingredients_to_remove do
      execute "DELETE FROM canonical_ingredients WHERE name = '#{name}'"
    end

    # Remove aliases from cocoa powder
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_remove(array_remove(aliases, 'unsweetened cocoa'), 'dutch-process cocoa')
    WHERE name = 'cocoa powder'
    """
  end

  defp format_array([]), do: ""

  defp format_array(items) do
    items
    |> Enum.map(&"'#{String.replace(&1, "'", "''")}'")
    |> Enum.join(", ")
  end
end
