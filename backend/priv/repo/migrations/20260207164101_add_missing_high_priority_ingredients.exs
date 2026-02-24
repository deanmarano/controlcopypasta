defmodule Controlcopypasta.Repo.Migrations.AddMissingHighPriorityIngredients do
  use Ecto.Migration

  @doc """
  Adds high-priority canonical ingredients identified from pending_ingredients analysis.
  Based on frequency analysis:
  - sesame seeds (2843x)
  - peas (1688x)
  - black peppercorns (1117x)
  - xanthan gum (616x)
  - white beans, dried currants, curry leaves, etc.
  """

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    ingredients = [
      # Seeds and nuts
      %{
        name: "sesame seeds",
        display_name: "Sesame Seeds",
        category: "nut_seed",
        aliases: [
          "sesame",
          "toasted sesame seeds",
          "unhulled sesame seeds",
          "hulled sesame seeds"
        ],
        is_allergen: true,
        allergen_groups: ["sesame"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "white sesame seeds",
        display_name: "White Sesame Seeds",
        category: "nut_seed",
        aliases: ["white sesame"],
        is_allergen: true,
        allergen_groups: ["sesame"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "black sesame seeds",
        display_name: "Black Sesame Seeds",
        category: "nut_seed",
        aliases: ["black sesame", "kuro goma"],
        is_allergen: true,
        allergen_groups: ["sesame"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Vegetables - peas
      %{
        name: "peas",
        display_name: "Peas",
        category: "vegetable",
        aliases: ["green peas", "garden peas", "english peas", "sweet peas"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "frozen peas",
        display_name: "Frozen Peas",
        category: "vegetable",
        aliases: ["frozen green peas"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "snow peas",
        display_name: "Snow Peas",
        category: "vegetable",
        aliases: ["chinese pea pods", "mangetout"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "sugar snap peas",
        display_name: "Sugar Snap Peas",
        category: "vegetable",
        aliases: ["snap peas", "sugar peas"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Peppercorns
      %{
        name: "black peppercorns",
        display_name: "Black Peppercorns",
        category: "spice",
        aliases: ["whole black pepper", "whole peppercorns", "peppercorns"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "white peppercorns",
        display_name: "White Peppercorns",
        category: "spice",
        aliases: ["whole white pepper"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "pink peppercorns",
        display_name: "Pink Peppercorns",
        category: "spice",
        aliases: ["red peppercorns"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "szechuan peppercorns",
        display_name: "Szechuan Peppercorns",
        category: "spice",
        aliases: ["sichuan peppercorns", "szechwan peppercorns", "chinese peppercorns"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Baking - thickeners
      %{
        name: "xanthan gum",
        display_name: "Xanthan Gum",
        category: "baking",
        aliases: ["xanthan"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "guar gum",
        display_name: "Guar Gum",
        category: "baking",
        aliases: [],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Beans
      %{
        name: "white beans",
        display_name: "White Beans",
        category: "legume",
        aliases: ["white kidney beans"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "cannellini beans",
        display_name: "Cannellini Beans",
        category: "legume",
        aliases: ["cannellini", "white cannellini beans"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "great northern beans",
        display_name: "Great Northern Beans",
        category: "legume",
        aliases: ["great northern white beans"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "navy beans",
        display_name: "Navy Beans",
        category: "legume",
        aliases: ["haricot beans", "boston beans", "pea beans"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Dried fruits
      %{
        name: "dried currants",
        display_name: "Dried Currants",
        category: "fruit",
        aliases: ["currants", "zante currants", "dried zante currants"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Asian herbs and aromatics
      %{
        name: "curry leaves",
        display_name: "Curry Leaves",
        category: "herb",
        aliases: ["fresh curry leaves", "kadi patta", "kadhi patta", "sweet neem leaves"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "kaffir lime leaves",
        display_name: "Kaffir Lime Leaves",
        category: "herb",
        aliases: ["makrut lime leaves", "thai lime leaves", "lime leaves"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Peppers - jalapeño variants
      %{
        name: "jalapeño",
        display_name: "Jalapeño",
        category: "vegetable",
        subcategory: "pepper",
        aliases: ["jalapeno", "jalapeños", "jalapenos", "jalapeño pepper", "jalapeno pepper"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "pickled jalapeños",
        display_name: "Pickled Jalapeños",
        category: "vegetable",
        subcategory: "pepper",
        aliases: ["pickled jalapenos", "jarred jalapeños", "canned jalapeños"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },

      # Additional common missing items
      %{
        name: "rice wine vinegar",
        display_name: "Rice Wine Vinegar",
        category: "vinegar",
        aliases: ["rice vinegar", "seasoned rice vinegar"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      },
      %{
        name: "fish sauce",
        display_name: "Fish Sauce",
        category: "sauce",
        aliases: ["nam pla", "nuoc mam", "patis"],
        dietary_flags: ["gluten_free", "dairy_free"]
      },
      %{
        name: "mirin",
        display_name: "Mirin",
        category: "sauce",
        aliases: ["sweet rice wine", "rice wine"],
        dietary_flags: ["vegan", "vegetarian", "dairy_free"]
      },
      %{
        name: "rice noodles",
        display_name: "Rice Noodles",
        category: "pasta",
        aliases: ["rice stick noodles", "rice vermicelli", "pho noodles", "pad thai noodles"],
        dietary_flags: ["vegan", "vegetarian", "gluten_free", "dairy_free"]
      }
    ]

    for ing <- ingredients do
      name = escape_sql(ing.name)
      display_name = escape_sql(ing.display_name)
      aliases_sql = format_array(ing[:aliases] || [])
      allergen_sql = format_array(ing[:allergen_groups] || [])
      dietary_sql = format_array(ing[:dietary_flags] || [])
      subcategory = if ing[:subcategory], do: "'#{escape_sql(ing[:subcategory])}'", else: "NULL"

      execute """
      INSERT INTO canonical_ingredients (id, name, display_name, category, subcategory, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        '#{name}',
        '#{display_name}',
        '#{ing.category}',
        #{subcategory},
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
      "sesame seeds",
      "white sesame seeds",
      "black sesame seeds",
      "peas",
      "frozen peas",
      "snow peas",
      "sugar snap peas",
      "black peppercorns",
      "white peppercorns",
      "pink peppercorns",
      "szechuan peppercorns",
      "xanthan gum",
      "guar gum",
      "white beans",
      "cannellini beans",
      "great northern beans",
      "navy beans",
      "dried currants",
      "curry leaves",
      "kaffir lime leaves",
      "jalapeño",
      "pickled jalapeños",
      "rice wine vinegar",
      "fish sauce",
      "mirin",
      "rice noodles"
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
