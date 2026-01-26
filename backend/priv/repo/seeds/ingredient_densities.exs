# Seed file for ingredient densities
#
# Run with: mix run priv/repo/seeds/ingredient_densities.exs
#
# Data sources:
# - USDA FoodData Central (primary source)
# - King Arthur Flour weight chart
# - FDA rounding rules for nutrition labels

alias Controlcopypasta.Repo
alias Controlcopypasta.Ingredients
alias Controlcopypasta.Ingredients.CanonicalIngredient

IO.puts("Seeding ingredient densities...")

# Density data: {ingredient_name, volume_unit, grams_per_unit, preparation, source}
# All values are grams per unit
densities = [
  # Flours
  {"all-purpose flour", "cup", 125, nil, "usda"},
  {"all-purpose flour", "cup", 140, "packed", "usda"},
  {"all-purpose flour", "cup", 115, "sifted", "usda"},
  {"all-purpose flour", "tbsp", 8, nil, "usda"},
  {"bread flour", "cup", 127, nil, "usda"},
  {"cake flour", "cup", 114, nil, "usda"},
  {"cake flour", "cup", 100, "sifted", "usda"},
  {"whole wheat flour", "cup", 120, nil, "usda"},
  {"almond flour", "cup", 96, nil, "usda"},
  {"coconut flour", "cup", 112, nil, "usda"},
  {"oat flour", "cup", 104, nil, "usda"},

  # Sugars
  {"granulated sugar", "cup", 200, nil, "usda"},
  {"granulated sugar", "tbsp", 12.5, nil, "usda"},
  {"brown sugar", "cup", 200, nil, "usda"},
  {"brown sugar", "cup", 220, "packed", "usda"},
  {"powdered sugar", "cup", 120, nil, "usda"},
  {"powdered sugar", "cup", 115, "sifted", "usda"},
  {"honey", "cup", 340, nil, "usda"},
  {"honey", "tbsp", 21, nil, "usda"},
  {"maple syrup", "cup", 315, nil, "usda"},
  {"maple syrup", "tbsp", 20, nil, "usda"},
  {"molasses", "cup", 328, nil, "usda"},
  {"corn syrup", "cup", 328, nil, "usda"},

  # Dairy
  {"butter", "cup", 227, nil, "usda"},
  {"butter", "tbsp", 14, nil, "usda"},
  {"milk", "cup", 244, nil, "usda"},
  {"heavy cream", "cup", 238, nil, "usda"},
  {"sour cream", "cup", 242, nil, "usda"},
  {"cream cheese", "cup", 232, nil, "usda"},
  {"yogurt", "cup", 245, nil, "usda"},
  {"greek yogurt", "cup", 280, nil, "usda"},
  {"ricotta cheese", "cup", 246, nil, "usda"},
  {"cottage cheese", "cup", 226, nil, "usda"},
  {"parmesan cheese", "cup", 100, "grated", "usda"},
  {"cheddar cheese", "cup", 113, "shredded", "usda"},
  {"mozzarella cheese", "cup", 112, "shredded", "usda"},

  # Oils & Fats
  {"olive oil", "cup", 216, nil, "usda"},
  {"olive oil", "tbsp", 13.5, nil, "usda"},
  {"vegetable oil", "cup", 218, nil, "usda"},
  {"vegetable oil", "tbsp", 13.6, nil, "usda"},
  {"coconut oil", "cup", 218, nil, "usda"},
  {"coconut oil", "tbsp", 13.6, nil, "usda"},
  {"shortening", "cup", 205, nil, "usda"},
  {"lard", "cup", 205, nil, "usda"},

  # Grains
  {"rice", "cup", 185, nil, "usda"},
  {"white rice", "cup", 185, nil, "usda"},
  {"brown rice", "cup", 195, nil, "usda"},
  {"quinoa", "cup", 170, nil, "usda"},
  {"oats", "cup", 80, nil, "usda"},
  {"rolled oats", "cup", 80, nil, "usda"},
  {"quick oats", "cup", 80, nil, "usda"},
  {"cornmeal", "cup", 157, nil, "usda"},
  {"breadcrumbs", "cup", 108, nil, "usda"},
  {"panko breadcrumbs", "cup", 60, nil, "usda"},

  # Leavening & Baking
  {"baking powder", "tsp", 4.6, nil, "usda"},
  {"baking soda", "tsp", 4.6, nil, "usda"},
  {"yeast", "tsp", 4, nil, "usda"},
  {"active dry yeast", "tsp", 4, nil, "usda"},
  {"instant yeast", "tsp", 3, nil, "usda"},
  {"cornstarch", "cup", 128, nil, "usda"},
  {"cornstarch", "tbsp", 8, nil, "usda"},

  # Salt & Seasonings
  {"salt", "tsp", 6, nil, "usda"},
  {"table salt", "tsp", 6, nil, "usda"},
  {"kosher salt", "tsp", 4.8, nil, "usda"},
  {"sea salt", "tsp", 5, nil, "usda"},
  {"black pepper", "tsp", 2.3, nil, "usda"},
  {"cayenne pepper", "tsp", 1.8, nil, "usda"},
  {"paprika", "tsp", 2.3, nil, "usda"},
  {"cinnamon", "tsp", 2.6, nil, "usda"},
  {"cumin", "tsp", 2.1, nil, "usda"},
  {"garlic powder", "tsp", 2.8, nil, "usda"},
  {"onion powder", "tsp", 2.4, nil, "usda"},
  {"chili powder", "tsp", 2.6, nil, "usda"},
  {"oregano", "tsp", 1.0, nil, "usda"},
  {"basil", "tsp", 0.7, nil, "usda"},
  {"thyme", "tsp", 1.0, nil, "usda"},
  {"rosemary", "tsp", 1.2, nil, "usda"},

  # Nuts & Seeds
  {"almonds", "cup", 143, "whole", "usda"},
  {"almonds", "cup", 95, "sliced", "usda"},
  {"almonds", "cup", 96, "chopped", "usda"},
  {"walnuts", "cup", 117, "chopped", "usda"},
  {"pecans", "cup", 109, "chopped", "usda"},
  {"peanuts", "cup", 146, nil, "usda"},
  {"cashews", "cup", 137, nil, "usda"},
  {"pine nuts", "cup", 135, nil, "usda"},
  {"sunflower seeds", "cup", 140, nil, "usda"},
  {"sesame seeds", "cup", 144, nil, "usda"},
  {"chia seeds", "cup", 163, nil, "usda"},
  {"flax seeds", "cup", 168, nil, "usda"},
  {"pumpkin seeds", "cup", 129, nil, "usda"},

  # Chocolate & Cocoa
  {"cocoa powder", "cup", 86, nil, "usda"},
  {"cocoa powder", "tbsp", 5.4, nil, "usda"},
  {"chocolate chips", "cup", 168, nil, "usda"},

  # Produce (common conversions)
  {"onion", "cup", 160, "chopped", "usda"},
  {"garlic", "tsp", 3, "minced", "usda"},
  {"celery", "cup", 101, "chopped", "usda"},
  {"carrot", "cup", 128, "chopped", "usda"},
  {"bell pepper", "cup", 149, "chopped", "usda"},
  {"tomato", "cup", 180, "chopped", "usda"},
  {"spinach", "cup", 30, nil, "usda"},
  {"spinach", "cup", 180, "cooked", "usda"},
  {"kale", "cup", 67, "chopped", "usda"},
  {"lettuce", "cup", 36, "shredded", "usda"},
  {"broccoli", "cup", 91, "chopped", "usda"},
  {"cauliflower", "cup", 107, "chopped", "usda"},
  {"mushrooms", "cup", 70, "sliced", "usda"},
  {"zucchini", "cup", 124, "sliced", "usda"},
  {"potato", "cup", 150, "diced", "usda"},
  {"sweet potato", "cup", 133, "cubed", "usda"},

  # Fruits
  {"banana", "cup", 150, "sliced", "usda"},
  {"apple", "cup", 125, "chopped", "usda"},
  {"blueberries", "cup", 148, nil, "usda"},
  {"strawberries", "cup", 166, "sliced", "usda"},
  {"raspberries", "cup", 123, nil, "usda"},
  {"lemon juice", "cup", 244, nil, "usda"},
  {"lemon juice", "tbsp", 15, nil, "usda"},
  {"lime juice", "cup", 246, nil, "usda"},
  {"lime juice", "tbsp", 15, nil, "usda"},
  {"orange juice", "cup", 248, nil, "usda"},
  {"raisins", "cup", 145, nil, "usda"},
  {"dried cranberries", "cup", 123, nil, "usda"},

  # Liquids
  {"water", "cup", 237, nil, "usda"},
  {"chicken broth", "cup", 240, nil, "usda"},
  {"beef broth", "cup", 240, nil, "usda"},
  {"vegetable broth", "cup", 240, nil, "usda"},
  {"wine", "cup", 236, nil, "usda"},
  {"soy sauce", "tbsp", 16, nil, "usda"},
  {"worcestershire sauce", "tbsp", 17, nil, "usda"},
  {"vinegar", "cup", 239, nil, "usda"},
  {"apple cider vinegar", "cup", 239, nil, "usda"},
  {"balsamic vinegar", "cup", 255, nil, "usda"},

  # Condiments
  {"mayonnaise", "cup", 220, nil, "usda"},
  {"mayonnaise", "tbsp", 14, nil, "usda"},
  {"ketchup", "cup", 274, nil, "usda"},
  {"ketchup", "tbsp", 17, nil, "usda"},
  {"mustard", "tsp", 5, nil, "usda"},
  {"dijon mustard", "tsp", 5, nil, "usda"},
  {"tomato paste", "tbsp", 16, nil, "usda"},
  {"tomato sauce", "cup", 245, nil, "usda"},
  {"peanut butter", "cup", 258, nil, "usda"},
  {"peanut butter", "tbsp", 16, nil, "usda"},

  # Legumes
  {"black beans", "cup", 172, "cooked", "usda"},
  {"kidney beans", "cup", 177, "cooked", "usda"},
  {"chickpeas", "cup", 164, "cooked", "usda"},
  {"lentils", "cup", 198, "cooked", "usda"},

  # Eggs
  {"egg", "cup", 243, "beaten", "usda"},
]

# Build a lookup map of ingredient name -> id
name_to_id =
  Repo.all(CanonicalIngredient)
  |> Enum.flat_map(fn ci ->
    all_names = [ci.name | ci.aliases || []]
    Enum.map(all_names, fn name -> {String.downcase(name), ci.id} end)
  end)
  |> Map.new()

IO.puts("Found #{map_size(name_to_id)} canonical ingredients")

# Insert densities
{inserted, skipped, missing} =
  Enum.reduce(densities, {0, 0, []}, fn {name, unit, grams, prep, source}, {ins, skip, miss} ->
    case Map.get(name_to_id, String.downcase(name)) do
      nil ->
        {ins, skip, [name | miss]}

      canonical_id ->
        attrs = %{
          canonical_ingredient_id: canonical_id,
          volume_unit: unit,
          grams_per_unit: Decimal.new("#{grams}"),
          preparation: prep,
          source: source
        }

        case Ingredients.upsert_density(attrs) do
          {:ok, _} -> {ins + 1, skip, miss}
          {:error, _} -> {ins, skip + 1, miss}
        end
    end
  end)

IO.puts("Inserted/updated: #{inserted} densities")
IO.puts("Skipped (errors): #{skipped}")

if length(missing) > 0 do
  IO.puts("\nMissing canonical ingredients (#{length(missing)}):")
  missing
  |> Enum.uniq()
  |> Enum.sort()
  |> Enum.each(&IO.puts("  - #{&1}"))
end

# Print stats
stats = Ingredients.density_coverage_stats()
IO.puts("\nDensity coverage:")
IO.puts("  Total ingredients: #{stats.total_ingredients}")
IO.puts("  With density: #{stats.with_density}")
IO.puts("  Without density: #{stats.without_density}")
IO.puts("  Coverage: #{stats.coverage_percent}%")

IO.puts("\nDone!")
