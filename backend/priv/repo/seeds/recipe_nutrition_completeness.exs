# Seeds for recipe nutrition completeness
# Adds missing canonical ingredients and estimated nutrition data
# needed for 100% nutrition coverage of personal recipes.

alias Controlcopypasta.Ingredients

IO.puts("Seeding recipe nutrition completeness data...")

# =============================================================================
# Missing canonical ingredients
# =============================================================================

new_ingredients = [
  %{
    name: "cottage cheese",
    display_name: "Cottage Cheese",
    category: "dairy",
    aliases: ["farmers cheese"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "split peas",
    display_name: "Split Peas",
    category: "legume",
    aliases: ["dried split peas", "green split peas", "yellow split peas"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "vanilla extract",
    display_name: "Vanilla Extract",
    category: "other",
    aliases: ["pure vanilla extract", "vanilla"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "durum wheat",
    display_name: "Durum Wheat",
    category: "grain",
    aliases: ["durum wheat flour", "semola", "semola di grano duro", "durum wheat semolina"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"]
  },
  %{
    name: "red chili flakes",
    display_name: "Red Chili Flakes",
    category: "spice",
    aliases: ["chili flakes", "chile flakes", "crushed chili flakes"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "kosher salt",
    display_name: "Kosher Salt",
    category: "spice",
    aliases: ["coarse salt", "coarse kosher salt", "Diamond Crystal kosher salt"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "grape tomatoes",
    display_name: "Grape Tomatoes",
    category: "produce",
    aliases: ["grape tomato"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "condensed milk",
    display_name: "Condensed Milk",
    category: "dairy",
    aliases: ["sweetened condensed milk"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "chaat masala",
    display_name: "Chaat Masala",
    category: "spice",
    aliases: ["chat masala", "sandwich masala"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "anise extract",
    display_name: "Anise Extract",
    category: "other",
    aliases: ["anise flavoring"],
    dietary_flags: ["vegetarian", "vegan"]
  },
  %{
    name: "coconut cream",
    display_name: "Coconut Cream",
    category: "dairy",
    aliases: ["unsweetened coconut cream", "cream of coconut"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free", "dairy_free"]
  },
  %{
    name: "fontina cheese",
    display_name: "Fontina Cheese",
    category: "dairy",
    aliases: ["fontina", "fontal"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "protein powder",
    display_name: "Protein Powder",
    category: "other",
    aliases: ["vanilla protein powder", "whey protein", "protein powder scoop"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "onion powder",
    display_name: "Onion Powder",
    category: "spice",
    aliases: [],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "caciocavallo",
    display_name: "Caciocavallo",
    category: "dairy",
    aliases: ["caciocavallo cheese"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "asafoetida",
    display_name: "Asafoetida",
    category: "spice",
    aliases: ["asafetida", "hing"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "lobster tail",
    display_name: "Lobster Tail",
    category: "protein",
    aliases: ["lobster tails"],
    dietary_flags: ["gluten_free", "dairy_free"]
  },
  %{
    name: "anchovy fillet",
    display_name: "Anchovy Fillet",
    category: "protein",
    aliases: ["anchovy fillets", "anchovies"],
    dietary_flags: ["gluten_free", "dairy_free"]
  },
  %{
    name: "pita bread",
    display_name: "Pita Bread",
    category: "grain",
    aliases: ["pita breads", "pita", "pitas"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"]
  },
  %{
    name: "green chili",
    display_name: "Green Chili",
    category: "produce",
    aliases: ["green chile", "green chiles", "green chilies", "green chili pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "red chili",
    display_name: "Red Chili",
    category: "produce",
    aliases: ["red chile", "red chiles", "red chilies", "red chili pepper"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "curry leaves",
    display_name: "Curry Leaves",
    category: "herb",
    aliases: ["fresh curry leaves", "curry leaf"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  # New ingredients for remaining no_match/no_nutrition gaps
  %{
    name: "cornmeal",
    display_name: "Cornmeal",
    category: "grain",
    aliases: ["corn meal", "fine cornmeal", "medium grind cornmeal", "polenta"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "instant yeast",
    display_name: "Instant Yeast",
    category: "other",
    aliases: ["quick-rising yeast", "bread machine yeast", "rapid rise yeast"],
    dietary_flags: ["vegetarian", "vegan"]
  },
  %{
    name: "sun-dried tomatoes",
    display_name: "Sun-Dried Tomatoes",
    category: "produce",
    aliases: ["sundried tomatoes", "sun dried tomatoes", "sun-dried tomato"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "herbs de provence",
    display_name: "Herbs de Provence",
    category: "spice",
    aliases: ["herbes de provence", "dried Italian herb mix", "Italian herb mix", "Italian seasoning blend"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  },
  %{
    name: "yeast extract spread",
    display_name: "Yeast Extract Spread",
    category: "condiment",
    aliases: ["marmite", "vegemite", "yeast extract"],
    dietary_flags: ["vegetarian", "vegan"]
  },
  %{
    name: "sandwich bread",
    display_name: "Sandwich Bread",
    category: "grain",
    aliases: ["pullman bread", "soft sandwich bread", "white bread", "sliced bread"],
    is_allergen: true,
    allergen_groups: ["wheat", "gluten"]
  },
  %{
    name: "chocolate mint candy",
    display_name: "Chocolate Mint Candy",
    category: "other",
    aliases: ["andes mints", "chocolate mint wafer", "mint chocolate candy"],
    dietary_flags: ["vegetarian"]
  },
  %{
    name: "ancho chili powder",
    display_name: "Ancho Chili Powder",
    category: "spice",
    aliases: ["ground chili ancho", "ground ancho", "ancho powder", "mild ground chili ancho"],
    dietary_flags: ["vegetarian", "vegan", "gluten_free"]
  }
]

{count, _} = Ingredients.bulk_insert_canonical_ingredients(new_ingredients)
IO.puts("  Inserted #{count} new canonical ingredients")

# =============================================================================
# Nutrition data (estimated from USDA, per 100g serving)
# =============================================================================

# Map of ingredient name -> nutrition values per 100g
nutrition_data = [
  {"lemon juice", 22, 0.35, 0.24, 6.9, 0.3, 2.5, 1, 0},
  {"peas", 81, 5.42, 0.4, 14.45, 5.7, 5.67, 5, 0},
  {"sesame seeds", 573, 17.73, 49.67, 23.45, 11.8, 0.3, 11, 0},
  {"garlic powder", 331, 16.55, 0.73, 72.73, 9.0, 2.43, 26, 0},
  {"smoked paprika", 282, 14.14, 12.89, 53.99, 34.9, 10.34, 68, 0},
  {"rice vinegar", 18, 0.04, 0.0, 0.4, 0.0, 0.4, 2, 0},
  {"rice wine vinegar", 18, 0.04, 0.0, 0.4, 0.0, 0.4, 2, 0},
  {"canola oil", 884, 0.0, 100.0, 0.0, 0.0, 0.0, 0, 0},
  {"red onion", 40, 1.1, 0.1, 9.34, 1.7, 4.24, 4, 0},
  {"dark chocolate", 598, 7.79, 42.63, 45.9, 10.9, 23.99, 24, 2},
  {"cherry tomato", 18, 0.88, 0.2, 3.92, 1.2, 2.64, 5, 0},
  {"red pepper flakes", 318, 12.01, 17.27, 56.63, 28.7, 10.34, 91, 0},
  {"red chili flakes", 318, 12.01, 17.27, 56.63, 28.7, 10.34, 91, 0},
  {"poppy seeds", 525, 17.99, 41.56, 28.13, 19.5, 2.99, 26, 0},
  {"lime juice", 25, 0.42, 0.07, 8.42, 0.4, 1.69, 1, 0},
  {"vanilla essence", 288, 0.06, 0.06, 12.65, 0.0, 12.65, 9, 0},
  {"vanilla extract", 288, 0.06, 0.06, 12.65, 0.0, 12.65, 9, 0},
  {"marinara sauce", 59, 1.74, 1.85, 9.35, 2.1, 6.01, 478, 0},
  {"jasmine rice", 130, 2.69, 0.28, 28.17, 0.4, 0.05, 1, 0},
  {"fennel seeds", 345, 15.8, 14.87, 52.29, 39.8, 0.0, 88, 0},
  {"white pepper", 296, 10.4, 2.12, 68.61, 26.2, 0.64, 5, 0},
  {"red wine vinegar", 19, 0.04, 0.0, 0.27, 0.0, 0.0, 8, 0},
  {"frozen peas", 77, 5.15, 0.27, 13.69, 4.5, 4.47, 72, 0},
  {"dark brown sugar", 380, 0.12, 0.0, 98.09, 0.0, 96.21, 28, 0},
  {"kosher salt", 0, 0.0, 0.0, 0.0, 0.0, 0.0, 38758, 0},
  {"coconut sugar", 375, 1.5, 0.5, 93.0, 0.0, 93.0, 45, 0},
  {"cottage cheese", 98, 11.12, 4.3, 3.38, 0.0, 2.67, 364, 17},
  {"salmon fillet", 208, 20.42, 13.42, 0.0, 0.0, 0.0, 59, 63},
  {"collard greens", 32, 3.02, 0.61, 5.42, 4.0, 0.46, 20, 0},
  {"split peas", 341, 24.55, 1.16, 60.37, 25.5, 8.0, 15, 0},
  {"durum wheat", 339, 13.68, 2.47, 71.13, 4.6, 2.67, 2, 0},
  {"grape tomatoes", 18, 0.88, 0.2, 3.92, 1.2, 2.64, 5, 0},
  {"condensed milk", 321, 7.91, 8.7, 54.4, 0.0, 54.4, 127, 34},
  {"chaat masala", 250, 10.0, 5.0, 45.0, 8.0, 2.0, 3000, 0},
  {"anise extract", 288, 0.06, 0.06, 12.65, 0.0, 12.65, 9, 0},
  {"coconut cream", 197, 2.02, 19.57, 6.65, 0.0, 6.23, 4, 0},
  {"fontina cheese", 389, 25.6, 31.14, 1.55, 0.0, 0.0, 800, 116},
  {"protein powder", 370, 75.0, 3.0, 12.0, 1.0, 5.0, 500, 0},
  # Additional commonly needed
  {"salt", 0, 0.0, 0.0, 0.0, 0.0, 0.0, 38758, 0},
  {"msg", 0, 0.0, 0.0, 0.0, 0.0, 0.0, 12304, 0},
  {"olives", 115, 0.84, 10.68, 6.26, 3.2, 0.0, 1556, 0},
  {"green olives", 145, 1.03, 15.32, 3.84, 3.3, 0.0, 1556, 0},
  {"onion powder", 341, 10.41, 1.04, 79.12, 15.2, 6.58, 73, 0},
  {"tapioca starch", 358, 0.19, 0.02, 88.69, 0.9, 3.35, 1, 0},
  {"pine nuts", 673, 13.69, 68.37, 13.08, 3.7, 3.59, 2, 0},
  {"chili powder", 282, 13.46, 14.28, 49.7, 34.8, 7.19, 1640, 0},
  {"watermelon", 30, 0.61, 0.15, 7.55, 0.4, 6.2, 1, 0},
  {"grape tomatoes", 18, 0.88, 0.2, 3.92, 1.2, 2.64, 5, 0},
  {"caciocavallo", 387, 25.6, 30.8, 2.2, 0.0, 0.0, 730, 109},
  {"asafoetida", 297, 4.0, 1.1, 67.8, 4.1, 0.0, 10, 0},
  {"lobster tail", 89, 19.0, 0.86, 0.0, 0.0, 0.0, 486, 146},
  {"anchovy fillet", 210, 28.89, 9.71, 0.0, 0.0, 0.0, 3668, 60},
  {"pita bread", 275, 9.1, 1.2, 55.7, 2.2, 1.3, 536, 0},
  {"green chili", 40, 2.0, 0.2, 9.46, 1.5, 5.1, 7, 0},
  {"red chili", 40, 1.87, 0.44, 8.81, 1.5, 5.3, 9, 0},
  {"curry leaves", 108, 6.1, 1.0, 18.7, 6.4, 0.0, 0, 0},
  # New for remaining gaps
  {"cornmeal", 362, 8.12, 3.59, 76.89, 7.3, 1.61, 7, 0},
  {"instant yeast", 325, 40.44, 7.61, 41.22, 26.9, 0.0, 51, 0},
  {"sun-dried tomatoes", 258, 14.11, 2.97, 55.76, 12.3, 37.59, 2095, 0},
  {"herbs de provence", 271, 12.0, 7.0, 52.0, 18.0, 2.0, 50, 0},
  {"yeast extract spread", 185, 27.8, 0.11, 23.9, 3.5, 1.3, 3400, 0},
  {"sandwich bread", 265, 9.43, 3.59, 49.0, 2.7, 5.67, 491, 0},
  {"chocolate mint candy", 480, 4.0, 28.0, 56.0, 2.0, 50.0, 35, 10},
  {"ancho chili powder", 282, 13.46, 14.28, 49.7, 34.8, 7.19, 1640, 0},
  {"jalapeño", 29, 0.91, 0.37, 6.5, 2.8, 4.12, 3, 0},
  {"summer squash", 16, 1.21, 0.18, 3.35, 1.1, 2.36, 2, 0},
  {"sea salt", 0, 0.0, 0.0, 0.0, 0.0, 0.0, 38758, 0},
  {"thai chile", 40, 1.87, 0.44, 8.81, 1.5, 5.3, 9, 0},
  {"serrano chile", 32, 1.74, 0.44, 6.7, 3.7, 4.0, 10, 0},
  {"cannellini beans", 333, 23.4, 0.85, 60.27, 24.4, 2.1, 16, 0},
]

for {name, cal, pro, fat, carb, fib, sug, sod, chol} <- nutrition_data do
  case Ingredients.find_canonical_ingredient(name) do
    {:ok, ingredient} ->
      case Ingredients.has_nutrition?(ingredient.id) do
        false ->
          Ingredients.create_nutrition(%{
            canonical_ingredient_id: ingredient.id,
            source: :estimated,
            serving_size_value: Decimal.new("100"),
            serving_size_unit: "g",
            calories: Decimal.new("#{cal}"),
            protein_g: Decimal.new("#{pro}"),
            fat_total_g: Decimal.new("#{fat}"),
            carbohydrates_g: Decimal.new("#{carb}"),
            fiber_g: Decimal.new("#{fib}"),
            sugar_g: Decimal.new("#{sug}"),
            sodium_mg: Decimal.new("#{sod}"),
            cholesterol_mg: Decimal.new("#{chol}")
          })
          IO.puts("  Added nutrition for: #{name}")

        true ->
          IO.puts("  Skipping #{name} (already has nutrition)")
      end

    {:error, :not_found} ->
      IO.puts("  WARNING: Canonical ingredient not found: #{name}")
  end
end

# =============================================================================
# Density data for commonly needed ingredients
# =============================================================================

density_data = [
  # {name, unit, grams_per_unit, preparation}
  {"lemon juice", "tbsp", 15.0, nil},
  {"lemon juice", "cup", 244.0, nil},
  {"lime juice", "tbsp", 15.0, nil},
  {"lime juice", "cup", 244.0, nil},
  {"marinara sauce", "cup", 250.0, nil},
  {"tapioca starch", "tbsp", 8.0, nil},
  {"tapioca starch", "tsp", 2.7, nil},
  {"tapioca starch", "cup", 120.0, nil},
  {"coconut sugar", "tbsp", 12.0, nil},
  {"coconut sugar", "cup", 192.0, nil},
  {"red onion", "cup", 160.0, "chopped"},
  {"red onion", "each", 150.0, nil},
  {"cherry tomato", "cup", 149.0, nil},
  {"grape tomatoes", "cup", 149.0, nil},
  {"dark brown sugar", "cup", 220.0, nil},
  {"watermelon", "cup", 152.0, "cubed"},
  {"pine nuts", "cup", 135.0, nil},
  {"pine nuts", "tbsp", 8.4, nil},
  {"cottage cheese", "cup", 226.0, nil},
  {"condensed milk", "cup", 306.0, nil},
  {"fontina cheese", "cup", 132.0, "shredded"},
  {"coconut cream", "cup", 240.0, nil},
  {"collard greens", "each", 60.0, nil},
  {"collard greens", "cup", 36.0, "chopped"},
  # Count items needed for recipe completeness
  {"lemon", "each", 58.0, nil},
  {"lime", "each", 44.0, nil},
  {"bay leaf", "each", 0.6, nil},
  {"bay leaves", "each", 0.6, nil},
  {"chickpeas", "can", 425.0, nil},
  {"cannellini beans", "can", 425.0, nil},
  {"white beans", "can", 425.0, nil},
  {"black beans", "can", 425.0, nil},
  {"onion", "each", 150.0, nil},
  {"yellow onion", "each", 150.0, nil},
  {"white onion", "each", 150.0, nil},
  {"jalapeño", "each", 14.0, nil},
  {"serrano pepper", "each", 6.0, nil},
  {"chipotle pepper", "each", 12.0, nil},
  {"green chili", "each", 10.0, nil},
  {"red chili", "each", 10.0, nil},
  {"chile pepper", "each", 10.0, nil},
  {"curry leaves", "each", 0.3, nil},
  {"butternut squash", "each", 900.0, nil},
  {"summer squash", "each", 196.0, nil},
  {"zucchini", "each", 196.0, nil},
  {"pita bread", "each", 60.0, nil},
  {"pita", "each", 60.0, nil},
  {"serrano chile", "each", 6.0, nil},
  {"thai chile", "each", 3.0, nil},
  {"tempeh", "block", 227.0, nil},
  {"lobster tail", "each", 142.0, nil},
  {"lobster", "each", 142.0, nil},
  {"anchovy", "each", 4.0, nil},
  {"anchovy fillet", "each", 4.0, nil},
  {"condensed milk", "can", 397.0, nil},
  {"protein powder", "each", 30.0, nil},
  {"ham", "cup", 150.0, "chopped"},
  # New count items for remaining gaps
  {"sandwich bread", "slice", 28.0, nil},
  {"sandwich bread", "each", 28.0, nil},
  {"chocolate mint candy", "each", 8.0, nil},
  {"green chili", "each", 10.0, nil},
  {"cornmeal", "cup", 157.0, nil},
  {"sun-dried tomatoes", "tbsp", 7.0, nil},
  {"sun-dried tomatoes", "cup", 54.0, nil},
  {"instant yeast", "tsp", 3.0, nil},
  {"instant yeast", "tbsp", 9.0, nil},
  {"herbs de provence", "tsp", 1.0, nil},
  {"herbs de provence", "tbsp", 3.0, nil},
  {"yeast extract spread", "tsp", 5.0, nil},
  {"yeast extract spread", "tbsp", 15.0, nil},
  {"ancho chili powder", "tsp", 2.7, nil},
  {"ancho chili powder", "tbsp", 8.0, nil},
  # "Juice of 1 lime" → parser outputs lime juice with unit=nil (count)
  # One lime yields about 30ml/2 tbsp of juice, one lemon about 45ml/3 tbsp
  {"lime juice", "each", 30.0, nil},
  {"lemon juice", "each", 45.0, nil},
  # Ginger piece (1 piece ≈ 1" piece ≈ 11g)
  {"ginger", "piece", 11.0, nil},
  {"ginger", "each", 11.0, nil},
  # Pinch/dash conversions (negligible amounts)
  {"salt", "pinch", 0.36, nil},
  {"kosher salt", "pinch", 0.36, nil},
  {"sea salt", "pinch", 0.36, nil},
  {"asafoetida", "pinch", 0.3, nil},
]

for {name, unit, grams, prep} <- density_data do
  case Ingredients.find_canonical_ingredient(name) do
    {:ok, ingredient} ->
      Ingredients.upsert_density(%{
        canonical_ingredient_id: ingredient.id,
        volume_unit: unit,
        grams_per_unit: Decimal.new("#{grams}"),
        preparation: prep,
        source: "manual"
      })
      IO.puts("  Added density for: #{name} (#{unit})")

    {:error, :not_found} ->
      IO.puts("  WARNING: Canonical ingredient not found for density: #{name}")
  end
end

# =============================================================================
# Add aliases for better matching
# =============================================================================

alias_updates = [
  {"vanilla essence", ["vanilla extract", "pure vanilla"]},
  {"green onion", ["green onions", "scallion", "scallions"]},
  {"sesame oil", ["toasted sesame oil", "sesame seed oil"]},
  {"caciocavallo", ["Caciocavallo"]},
  {"coconut cream", ["unsweetened coconut cream", "cream of coconut"]},
  {"almond milk", ["almondmilk", "almond breeze", "Almond Breeze Original Almondmilk"]},
  {"pasta", ["medium shells", "small shells", "shell pasta", "cavatelli", "ditalini", "elbow pasta", "penne pasta"]},
  {"canned tomatoes", ["puréed tomatoes", "pureed tomatoes"]},
  {"italian seasoning", ["dried Italian herb mix"]},
  {"pita bread", ["pita", "pitas", "pita breads"]},
  {"kosher salt", ["Diamond Crystal kosher salt", "diamond crystal salt", "Diamond Crystal salt"]},
]

# Add nutrition for white beans (from the fixture no_nutrition failure)
for name <- ["white beans", "diamond crystal salt"] do
  case Ingredients.find_canonical_ingredient(name) do
    {:ok, ingredient} ->
      case Ingredients.has_nutrition?(ingredient.id) do
        false ->
          case name do
            "white beans" ->
              Ingredients.create_nutrition(%{
                canonical_ingredient_id: ingredient.id,
                source: :estimated,
                serving_size_value: Decimal.new("100"),
                serving_size_unit: "g",
                calories: Decimal.new("139"),
                protein_g: Decimal.new("9.73"),
                fat_total_g: Decimal.new("0.35"),
                carbohydrates_g: Decimal.new("25.09"),
                fiber_g: Decimal.new("6.3"),
                sugar_g: Decimal.new("0.34"),
                sodium_mg: Decimal.new("6"),
                cholesterol_mg: Decimal.new("0")
              })
              IO.puts("  Added nutrition for: #{name}")
            "diamond crystal salt" ->
              Ingredients.create_nutrition(%{
                canonical_ingredient_id: ingredient.id,
                source: :estimated,
                serving_size_value: Decimal.new("100"),
                serving_size_unit: "g",
                calories: Decimal.new("0"),
                protein_g: Decimal.new("0"),
                fat_total_g: Decimal.new("0"),
                carbohydrates_g: Decimal.new("0"),
                fiber_g: Decimal.new("0"),
                sugar_g: Decimal.new("0"),
                sodium_mg: Decimal.new("38758"),
                cholesterol_mg: Decimal.new("0")
              })
              IO.puts("  Added nutrition for: #{name}")
            _ -> :ok
          end
        true ->
          IO.puts("  Skipping #{name} (already has nutrition)")
      end
    {:error, :not_found} ->
      IO.puts("  WARNING: Not found: #{name}")
  end
end

# Update measurement_type for liquid ingredients
for name <- ["lemon juice", "lime juice", "water"] do
  case Ingredients.find_canonical_ingredient(name) do
    {:ok, ingredient} ->
      if ingredient.measurement_type != "liquid" do
        Ingredients.update_canonical_ingredient(ingredient, %{measurement_type: "liquid"})
        IO.puts("  Set measurement_type=liquid for: #{name}")
      end
    {:error, :not_found} ->
      IO.puts("  WARNING: Canonical not found for measurement_type update: #{name}")
  end
end

# Add density data for "asafetida" canonical (duplicate spelling)
case Ingredients.find_canonical_ingredient("asafetida") do
  {:ok, ingredient} ->
    Ingredients.upsert_density(%{
      canonical_ingredient_id: ingredient.id,
      volume_unit: "pinch",
      grams_per_unit: Decimal.new("0.3"),
      source: "manual"
    })
    IO.puts("  Added pinch density for asafetida (alternate spelling)")
  {:error, :not_found} -> :ok
end

for {name, new_aliases} <- alias_updates do
  case Ingredients.find_canonical_ingredient(name) do
    {:ok, ingredient} ->
      existing = ingredient.aliases || []
      merged = Enum.uniq(existing ++ new_aliases)
      if merged != existing do
        Ingredients.update_canonical_ingredient(ingredient, %{aliases: merged})
        IO.puts("  Updated aliases for: #{name}")
      end

    {:error, :not_found} ->
      IO.puts("  WARNING: Canonical ingredient not found for alias update: #{name}")
  end
end

IO.puts("Recipe nutrition completeness seeding complete!")
