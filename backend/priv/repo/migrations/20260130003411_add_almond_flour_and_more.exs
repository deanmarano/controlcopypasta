defmodule Controlcopypasta.Repo.Migrations.AddAlmondFlourAndMore do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ingredients = [
      %{
        name: "almond flour",
        display_name: "Almond Flour",
        category: "baking",
        aliases: ["almond meal", "ground almonds", "blanched almond flour"],
        is_allergen: true,
        allergen_groups: ["tree_nuts"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "coconut flour",
        display_name: "Coconut Flour",
        category: "baking",
        aliases: [],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "lemon curd",
        display_name: "Lemon Curd",
        category: "condiment",
        aliases: ["lime curd", "citrus curd"],
        is_allergen: true,
        allergen_groups: ["eggs"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },
      %{
        name: "confectioners sugar",
        display_name: "Confectioners Sugar",
        category: "sweetener",
        aliases: ["powdered sugar", "icing sugar", "confectioners' sugar"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "peppermint",
        display_name: "Peppermint",
        category: "herb",
        aliases: ["peppermint bark", "peppermint extract", "peppermint oil"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "udon noodles",
        display_name: "Udon Noodles",
        category: "grain",
        aliases: ["udon", "japanese udon noodles"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "lasagna noodles",
        display_name: "Lasagna Noodles",
        category: "grain",
        aliases: ["lasagna sheets", "lasagne noodles", "dried lasagna"],
        is_allergen: true,
        allergen_groups: ["wheat", "gluten"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
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
      "almond flour",
      "coconut flour",
      "lemon curd",
      "confectioners sugar",
      "peppermint",
      "udon noodles",
      "lasagna noodles"
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
