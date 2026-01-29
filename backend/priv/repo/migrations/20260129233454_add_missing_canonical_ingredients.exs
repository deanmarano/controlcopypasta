defmodule Controlcopypasta.Repo.Migrations.AddMissingCanonicalIngredients do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add missing canonical ingredients
    ingredients = [
      # Cloves (the spice, not garlic cloves)
      %{
        name: "cloves",
        display_name: "Cloves",
        category: "spice",
        aliases: ["ground cloves", "whole cloves", "clove"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Generic nuts
      %{
        name: "nuts",
        display_name: "Nuts",
        category: "nut",
        aliases: ["mixed nuts", "chopped nuts", "assorted nuts"],
        is_allergen: true,
        allergen_groups: ["tree_nuts"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Generic broth (not chicken/beef/vegetable specific)
      %{
        name: "broth",
        display_name: "Broth",
        category: "other",
        aliases: ["stock", "cooking broth"],
        dietary_flags: ["gluten_free", "dairy_free"]
      },

      # Seasoning blends
      %{
        name: "creole seasoning",
        display_name: "Creole Seasoning",
        category: "spice",
        aliases: ["cajun seasoning", "louisiana seasoning"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "poultry seasoning",
        display_name: "Poultry Seasoning",
        category: "spice",
        aliases: [],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "taco seasoning",
        display_name: "Taco Seasoning",
        category: "spice",
        aliases: ["taco seasoning mix", "taco spice"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "italian seasoning",
        display_name: "Italian Seasoning",
        category: "spice",
        aliases: ["italian herb blend", "italian herbs"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "five-spice powder",
        display_name: "Five-Spice Powder",
        category: "spice",
        aliases: ["chinese five-spice", "five spice powder", "chinese five spice"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Prepared doughs
      %{
        name: "puff pastry",
        display_name: "Puff Pastry",
        category: "grain",
        aliases: ["frozen puff pastry", "puff pastry sheets", "puff pastry dough"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegetarian"]
      },
      %{
        name: "pizza dough",
        display_name: "Pizza Dough",
        category: "grain",
        aliases: ["homemade pizza dough", "store-bought pizza dough"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegetarian", "dairy_free"]
      },
      %{
        name: "phyllo dough",
        display_name: "Phyllo Dough",
        category: "grain",
        aliases: ["filo dough", "fillo dough", "phyllo sheets", "frozen phyllo"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "pie crust",
        display_name: "Pie Crust",
        category: "grain",
        aliases: ["pie shell", "pastry crust", "prepared pie crust"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegetarian"]
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
  end

  def down do
    ingredients_to_remove = [
      "cloves", "nuts", "broth", "creole seasoning", "poultry seasoning",
      "taco seasoning", "italian seasoning", "five-spice powder",
      "puff pastry", "pizza dough", "phyllo dough", "pie crust"
    ]

    for name <- ingredients_to_remove do
      execute "DELETE FROM canonical_ingredients WHERE name = '#{name}'"
    end
  end

  defp format_array([]), do: ""
  defp format_array(items) do
    items
    |> Enum.map(&"'#{String.replace(&1, "'", "''")}'")
    |> Enum.join(", ")
  end
end
