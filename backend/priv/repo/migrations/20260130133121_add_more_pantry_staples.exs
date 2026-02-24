defmodule Controlcopypasta.Repo.Migrations.AddMorePantryStaples do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ingredients = [
      # Oils
      %{
        name: "grapeseed oil",
        display_name: "Grapeseed Oil",
        category: "oil",
        aliases: ["grape seed oil"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Flours and meals
      %{
        name: "flax meal",
        display_name: "Flax Meal",
        category: "baking",
        aliases: ["ground flaxseed", "flaxseed meal", "ground flax"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Spice blends
      %{
        name: "za'atar",
        display_name: "Za'atar",
        category: "spice",
        aliases: ["zaatar", "zatar", "za'tar"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "creole seasoning",
        display_name: "Creole Seasoning",
        category: "spice",
        aliases: ["cajun seasoning", "cajun spice", "creole spice"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "chinese five spice",
        display_name: "Chinese Five Spice",
        category: "spice",
        aliases: ["five spice", "5 spice", "chinese 5 spice", "five-spice powder"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "garam masala",
        display_name: "Garam Masala",
        category: "spice",
        aliases: [],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Sweeteners and syrups
      %{
        name: "barley malt syrup",
        display_name: "Barley Malt Syrup",
        category: "sweetener",
        aliases: ["malt syrup", "barley malt"],
        is_allergen: true,
        allergen_groups: ["gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "turbinado sugar",
        display_name: "Turbinado Sugar",
        category: "sweetener",
        aliases: ["raw sugar", "demerara sugar"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Breads and rolls
      %{
        name: "brioche bun",
        display_name: "Brioche Bun",
        category: "bread",
        aliases: ["brioche buns", "brioche roll", "brioche rolls"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten", "eggs", "milk"],
        dietary_flags: ["vegetarian"]
      },
      %{
        name: "hoagie roll",
        display_name: "Hoagie Roll",
        category: "bread",
        aliases: ["hoagie rolls", "hoagie bun", "sub roll", "submarine roll"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },

      # Vegetables and greens
      %{
        name: "sprouts",
        display_name: "Sprouts",
        category: "vegetable",
        aliases: ["alfalfa sprouts", "bean sprouts", "broccoli sprouts", "radish sprouts"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Condiments
      %{
        name: "gochujang",
        display_name: "Gochujang",
        category: "condiment",
        aliases: ["korean chile paste", "korean chili paste", "korean red pepper paste"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },

      # Cheese
      %{
        name: "paneer",
        display_name: "Paneer",
        category: "dairy",
        aliases: ["paneer cheese", "indian cheese"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },

      # Grains
      %{
        name: "granola",
        display_name: "Granola",
        category: "grain",
        aliases: [],
        dietary_flags: ["vegetarian"]
      },

      # Nuts and seeds
      %{
        name: "sunflower seeds",
        display_name: "Sunflower Seeds",
        category: "nut",
        aliases: ["sunflower kernels"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      }
    ]

    for ing <- ingredients do
      aliases_sql = format_array(ing[:aliases] || [])
      allergen_sql = format_array(ing[:allergen_groups] || [])
      dietary_sql = format_array(ing[:dietary_flags] || [])
      animal_type = ing[:animal_type] || ""
      name = escape_sql(ing.name)
      display_name = escape_sql(ing.display_name)

      execute """
      INSERT INTO canonical_ingredients (id, name, display_name, category, aliases, is_allergen, allergen_groups, dietary_flags, animal_type, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        '#{name}',
        '#{display_name}',
        '#{ing.category}',
        ARRAY[#{aliases_sql}]::varchar[],
        #{ing[:is_allergen] || false},
        ARRAY[#{allergen_sql}]::varchar[],
        ARRAY[#{dietary_sql}]::varchar[],
        '#{animal_type}',
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO UPDATE SET
        aliases = EXCLUDED.aliases,
        dietary_flags = EXCLUDED.dietary_flags,
        updated_at = EXCLUDED.updated_at
      """
    end
  end

  def down do
    ingredients_to_remove = [
      "grapeseed oil",
      "flax meal",
      "za'atar",
      "creole seasoning",
      "chinese five spice",
      "garam masala",
      "barley malt syrup",
      "turbinado sugar",
      "brioche bun",
      "hoagie roll",
      "sprouts",
      "gochujang",
      "paneer",
      "granola",
      "sunflower seeds"
    ]

    for name <- ingredients_to_remove do
      execute "DELETE FROM canonical_ingredients WHERE name = '#{escape_sql(name)}'"
    end
  end

  defp format_array([]), do: ""

  defp format_array(items) do
    items
    |> Enum.map(&"'#{escape_sql(&1)}'")
    |> Enum.join(", ")
  end

  defp escape_sql(str), do: String.replace(str, "'", "''")
end
