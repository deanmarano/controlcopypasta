defmodule Controlcopypasta.Repo.Migrations.AddOilsFruitsAndChileAliases do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Add new canonical ingredients
    ingredients = [
      # Generic oil
      %{
        name: "vegetable oil",
        display_name: "Vegetable Oil",
        category: "oil",
        aliases: ["oil", "cooking oil", "neutral oil", "frying oil"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Greens (generic)
      %{
        name: "greens",
        display_name: "Greens",
        category: "vegetable",
        aliases: ["leafy greens", "mixed greens", "cooking greens", "salad greens"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Fruits
      %{
        name: "nectarine",
        display_name: "Nectarine",
        category: "fruit",
        aliases: ["nectarines"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "apricot",
        display_name: "Apricot",
        category: "fruit",
        aliases: ["apricots", "fresh apricot", "fresh apricots"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Chocolate varieties
      %{
        name: "chocolate chips",
        display_name: "Chocolate Chips",
        category: "baking",
        aliases: ["semi-sweet chocolate chips", "semisweet chocolate chips", "chocolate morsels"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },
      %{
        name: "chocolate chunks",
        display_name: "Chocolate Chunks",
        category: "baking",
        aliases: ["chocolate pieces"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },

      # Fire roasted tomatoes
      %{
        name: "fire roasted tomatoes",
        display_name: "Fire Roasted Tomatoes",
        category: "vegetable",
        aliases: ["fire-roasted tomatoes", "fire roasted diced tomatoes", "roasted tomatoes"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Dulce de leche
      %{
        name: "dulce de leche",
        display_name: "Dulce de Leche",
        category: "dairy",
        aliases: ["caramel sauce", "milk caramel"],
        is_allergen: true,
        allergen_groups: ["milk"],
        dietary_flags: ["vegetarian", "gluten_free"]
      },

      # Hominy
      %{
        name: "hominy",
        display_name: "Hominy",
        category: "grain",
        aliases: ["posole", "pozole", "white hominy", "dried hominy"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
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

    # Add "chile" as alternate spelling to chili-related ingredients
    # chili sauce already exists - add "chile sauce" alias
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'chile sauce')
    WHERE name = 'chili sauce'
    AND NOT ('chile sauce' = ANY(aliases))
    """

    # chili powder - add "chile powder" alias
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'chile powder')
    WHERE name = 'chili powder'
    AND NOT ('chile powder' = ANY(aliases))
    """

    # red chile powder - add "red chili powder" alias if not present
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'red chili powder')
    WHERE name = 'red chile powder'
    AND NOT ('red chili powder' = ANY(aliases))
    """

    # ancho chile powder - make sure "ancho chili powder" alias is there
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'ancho chili powder')
    WHERE name = 'ancho chile powder'
    AND NOT ('ancho chili powder' = ANY(aliases))
    """

    # chipotle pepper - add "chile" spelling aliases
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_cat(aliases, ARRAY['chipotle chile', 'chipotle chiles']::varchar[])
    WHERE name = 'chipotle pepper'
    AND NOT ('chipotle chile' = ANY(aliases))
    """

    # Add "almond meal" as alias to almond flour
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'almond meal')
    WHERE name = 'almond flour'
    AND NOT ('almond meal' = ANY(aliases))
    """
  end

  def down do
    ingredients_to_remove = [
      "vegetable oil", "greens", "nectarine", "apricot",
      "chocolate chips", "chocolate chunks", "fire roasted tomatoes",
      "dulce de leche", "hominy"
    ]

    for name <- ingredients_to_remove do
      execute "DELETE FROM canonical_ingredients WHERE name = '#{name}'"
    end

    # Remove chile spelling aliases
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_remove(aliases, 'chile sauce')
    WHERE name = 'chili sauce'
    """

    execute """
    UPDATE canonical_ingredients
    SET aliases = array_remove(aliases, 'chile powder')
    WHERE name = 'chili powder'
    """

    execute """
    UPDATE canonical_ingredients
    SET aliases = array_remove(aliases, 'almond meal')
    WHERE name = 'almond flour'
    """
  end

  defp format_array([]), do: ""
  defp format_array(items) do
    items
    |> Enum.map(&"'#{String.replace(&1, "'", "''")}'")
    |> Enum.join(", ")
  end
end
