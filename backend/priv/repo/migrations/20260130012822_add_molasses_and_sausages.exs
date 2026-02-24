defmodule Controlcopypasta.Repo.Migrations.AddMolassesAndSausages do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ingredients = [
      # Sweeteners
      %{
        name: "molasses",
        display_name: "Molasses",
        category: "sweetener",
        aliases: [
          "light molasses",
          "mild-flavored molasses",
          "blackstrap molasses",
          "dark molasses"
        ],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Sausages
      %{
        name: "andouille sausage",
        display_name: "Andouille Sausage",
        category: "meat",
        aliases: ["andouille", "cajun sausage"],
        animal_type: "pork",
        dietary_flags: ["gluten_free", "dairy_free"]
      },
      %{
        name: "chorizo",
        display_name: "Chorizo",
        category: "meat",
        aliases: ["spanish chorizo", "mexican chorizo", "chorizo sausage"],
        animal_type: "pork",
        dietary_flags: ["gluten_free", "dairy_free"]
      },
      %{
        name: "italian sausage",
        display_name: "Italian Sausage",
        category: "meat",
        aliases: ["sweet italian sausage", "hot italian sausage", "mild italian sausage"],
        animal_type: "pork",
        dietary_flags: ["gluten_free", "dairy_free"]
      },

      # Poultry
      %{
        name: "quail",
        display_name: "Quail",
        category: "meat",
        aliases: ["whole quail", "quail meat"],
        animal_type: "poultry",
        dietary_flags: ["gluten_free", "dairy_free"]
      },

      # Seafood
      %{
        name: "sardine",
        display_name: "Sardine",
        category: "seafood",
        aliases: ["sardines", "fresh sardines", "canned sardines"],
        is_allergen: true,
        allergen_groups: ["fish"],
        dietary_flags: ["gluten_free", "dairy_free"]
      },
      %{
        name: "anchovy paste",
        display_name: "Anchovy Paste",
        category: "seafood",
        aliases: ["anchovy puree"],
        is_allergen: true,
        allergen_groups: ["fish"],
        dietary_flags: ["gluten_free", "dairy_free"]
      },

      # Misc
      %{
        name: "pork shoulder",
        display_name: "Pork Shoulder",
        category: "meat",
        aliases: ["pork butt", "boston butt", "pork shoulder roast"],
        animal_type: "pork",
        dietary_flags: ["gluten_free", "dairy_free"]
      },
      %{
        name: "brisket",
        display_name: "Brisket",
        category: "meat",
        aliases: ["beef brisket", "flat-cut brisket", "point-cut brisket"],
        animal_type: "beef",
        dietary_flags: ["gluten_free", "dairy_free"]
      }
    ]

    for ing <- ingredients do
      aliases_sql = format_array(ing[:aliases] || [])
      allergen_sql = format_array(ing[:allergen_groups] || [])
      dietary_sql = format_array(ing[:dietary_flags] || [])
      animal_type = ing[:animal_type] || ""

      execute """
      INSERT INTO canonical_ingredients (id, name, display_name, category, aliases, is_allergen, allergen_groups, dietary_flags, animal_type, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        '#{ing.name}',
        '#{ing.display_name}',
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
      "molasses",
      "andouille sausage",
      "chorizo",
      "italian sausage",
      "quail",
      "sardine",
      "anchovy paste",
      "pork shoulder",
      "brisket"
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
