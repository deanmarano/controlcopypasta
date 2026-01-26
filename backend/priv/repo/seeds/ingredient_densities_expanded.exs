# Expanded seed file for ingredient densities
#
# Run with: mix run priv/repo/seeds/ingredient_densities_expanded.exs
#
# This adds densities for more ingredients beyond the initial seed.

alias Controlcopypasta.Repo
alias Controlcopypasta.Ingredients
alias Controlcopypasta.Ingredients.CanonicalIngredient

IO.puts("Seeding expanded ingredient densities...")

# Additional density data organized by category
# Format: {ingredient_name, volume_unit, grams_per_unit, preparation, source}
densities = [
  # ============ PRODUCE ============
  # Fruits
  {"mango", "cup", 165, "chopped", "usda"},
  {"peach", "cup", 154, "sliced", "usda"},
  {"pear", "cup", 165, "sliced", "usda"},
  {"plum", "cup", 165, "sliced", "usda"},
  {"grapes", "cup", 151, nil, "usda"},
  {"pineapple", "cup", 165, "chunks", "usda"},
  {"watermelon", "cup", 152, "cubed", "usda"},
  {"cantaloupe", "cup", 160, "cubed", "usda"},
  {"honeydew", "cup", 170, "cubed", "usda"},
  {"kiwi", "cup", 180, "sliced", "usda"},
  {"cherries", "cup", 138, nil, "usda"},
  {"cranberries", "cup", 100, nil, "usda"},
  {"blackberries", "cup", 144, nil, "usda"},
  {"apricot", "cup", 155, "sliced", "usda"},
  {"fig", "cup", 149, nil, "usda"},
  {"pomegranate seeds", "cup", 174, nil, "usda"},
  {"grapefruit", "cup", 230, "sections", "usda"},
  {"orange", "cup", 180, "sections", "usda"},
  {"tangerine", "cup", 195, "sections", "usda"},
  {"lemon zest", "tbsp", 6, nil, "usda"},
  {"lime zest", "tbsp", 6, nil, "usda"},
  {"orange zest", "tbsp", 6, nil, "usda"},

  # Vegetables
  {"cabbage", "cup", 89, "shredded", "usda"},
  {"savoy cabbage", "cup", 89, "shredded", "usda"},
  {"red cabbage", "cup", 89, "shredded", "usda"},
  {"napa cabbage", "cup", 76, "shredded", "usda"},
  {"brussels sprouts", "cup", 88, nil, "usda"},
  {"asparagus", "cup", 134, "chopped", "usda"},
  {"green beans", "cup", 110, nil, "usda"},
  {"snap peas", "cup", 98, nil, "usda"},
  {"snow peas", "cup", 98, nil, "usda"},
  {"peas", "cup", 145, nil, "usda"},
  {"corn", "cup", 154, "kernels", "usda"},
  {"artichoke hearts", "cup", 168, nil, "usda"},
  {"eggplant", "cup", 82, "cubed", "usda"},
  {"fennel", "cup", 87, "sliced", "usda"},
  {"leek", "cup", 89, "sliced", "usda"},
  {"radish", "cup", 116, "sliced", "usda"},
  {"turnip", "cup", 130, "cubed", "usda"},
  {"rutabaga", "cup", 140, "cubed", "usda"},
  {"parsnip", "cup", 133, "sliced", "usda"},
  {"beet", "cup", 136, "sliced", "usda"},
  {"butternut squash", "cup", 140, "cubed", "usda"},
  {"acorn squash", "cup", 140, "cubed", "usda"},
  {"spaghetti squash", "cup", 155, "cooked", "usda"},
  {"pumpkin", "cup", 116, "cubed", "usda"},
  {"cucumber", "cup", 104, "sliced", "usda"},
  {"tomato", "cup", 180, "chopped", "usda"},
  {"cherry tomatoes", "cup", 149, nil, "usda"},
  {"grape tomatoes", "cup", 149, nil, "usda"},
  {"vine tomato", "cup", 180, "chopped", "usda"},
  {"roma tomato", "cup", 180, "chopped", "usda"},
  {"avocado", "cup", 150, "cubed", "usda"},
  {"jalapeno", "cup", 90, "sliced", "usda"},
  {"serrano pepper", "cup", 105, "sliced", "usda"},
  {"poblano pepper", "cup", 120, "chopped", "usda"},
  {"anaheim pepper", "cup", 120, "chopped", "usda"},
  {"habanero pepper", "tbsp", 9, "minced", "usda"},
  {"shallot", "cup", 160, "chopped", "usda"},
  {"scallion", "cup", 100, "sliced", "usda"},
  {"green onion", "cup", 100, "sliced", "usda"},
  {"chives", "tbsp", 3, nil, "usda"},
  {"bok choy", "cup", 70, "shredded", "usda"},
  {"swiss chard", "cup", 36, nil, "usda"},
  {"collard greens", "cup", 36, nil, "usda"},
  {"arugula", "cup", 20, nil, "usda"},
  {"watercress", "cup", 34, nil, "usda"},
  {"endive", "cup", 50, "chopped", "usda"},
  {"radicchio", "cup", 40, "shredded", "usda"},

  # ============ PROTEINS ============
  # Fish & Seafood (typically measured by weight, but some volume measures for cooked/flaked)
  {"cod", "cup", 140, "flaked", "usda"},
  {"tilapia", "cup", 140, "flaked", "usda"},
  {"salmon", "cup", 140, "flaked", "usda"},
  {"tuna", "cup", 154, "canned", "usda"},
  {"shrimp", "cup", 145, "cooked", "usda"},
  {"crab", "cup", 135, "cooked", "usda"},
  {"lobster", "cup", 145, "cooked", "usda"},
  {"scallops", "cup", 150, nil, "usda"},
  {"clams", "cup", 160, "chopped", "usda"},
  {"mussels", "cup", 150, "cooked", "usda"},
  {"oysters", "cup", 170, nil, "usda"},
  {"anchovies", "tbsp", 10, "minced", "usda"},
  {"sardines", "cup", 149, "drained", "usda"},

  # Meat (cooked, diced/shredded for volume measures)
  {"chicken", "cup", 140, "diced", "usda"},
  {"turkey", "cup", 140, "diced", "usda"},
  {"beef", "cup", 135, "diced", "usda"},
  {"ground beef", "cup", 225, nil, "usda"},
  {"ground turkey", "cup", 225, nil, "usda"},
  {"ground pork", "cup", 225, nil, "usda"},
  {"ground chicken", "cup", 225, nil, "usda"},
  {"pork", "cup", 135, "diced", "usda"},
  {"lamb", "cup", 135, "diced", "usda"},
  {"ham", "cup", 140, "diced", "usda"},
  {"bacon", "cup", 115, "crumbled", "usda"},
  {"pancetta", "cup", 115, "diced", "usda"},
  {"prosciutto", "cup", 80, "chopped", "usda"},
  {"sausage", "cup", 175, "crumbled", "usda"},
  {"chorizo", "cup", 175, "crumbled", "usda"},
  {"salami", "cup", 100, "diced", "usda"},
  {"pepperoni", "cup", 100, "sliced", "usda"},

  # Tofu & Plant proteins
  {"tofu", "cup", 252, "cubed", "usda"},
  {"tempeh", "cup", 166, "cubed", "usda"},
  {"seitan", "cup", 180, "cubed", "usda"},

  # ============ GRAINS & PASTA ============
  # Pasta (dry)
  {"pasta", "cup", 105, nil, "usda"},
  {"spaghetti", "cup", 105, nil, "usda"},
  {"penne", "cup", 105, nil, "usda"},
  {"rigatoni", "cup", 105, nil, "usda"},
  {"fusilli", "cup", 105, nil, "usda"},
  {"farfalle", "cup", 90, nil, "usda"},
  {"rotini", "cup", 105, nil, "usda"},
  {"linguine", "cup", 105, nil, "usda"},
  {"fettuccine", "cup", 105, nil, "usda"},
  {"tagliatelle", "cup", 105, nil, "usda"},
  {"orzo", "cup", 170, nil, "usda"},
  {"couscous", "cup", 173, nil, "usda"},
  {"egg noodles", "cup", 80, nil, "usda"},
  {"rice noodles", "cup", 176, nil, "usda"},
  {"macaroni", "cup", 105, nil, "usda"},
  {"lasagna noodles", "cup", 100, nil, "usda"},

  # Grains
  {"barley", "cup", 200, nil, "usda"},
  {"bulgur", "cup", 140, nil, "usda"},
  {"farro", "cup", 180, nil, "usda"},
  {"freekeh", "cup", 160, nil, "usda"},
  {"millet", "cup", 200, nil, "usda"},
  {"polenta", "cup", 163, nil, "usda"},
  {"grits", "cup", 156, nil, "usda"},
  {"wild rice", "cup", 160, nil, "usda"},
  {"arborio rice", "cup", 200, nil, "usda"},
  {"jasmine rice", "cup", 185, nil, "usda"},
  {"basmati rice", "cup", 180, nil, "usda"},
  {"sushi rice", "cup", 200, nil, "usda"},

  # Bread & Baked
  {"breadcrumbs", "cup", 108, nil, "usda"},
  {"panko", "cup", 60, nil, "usda"},
  {"croutons", "cup", 30, nil, "usda"},
  {"bread", "cup", 45, "cubed", "usda"},
  {"stuffing mix", "cup", 70, nil, "usda"},
  {"tortilla chips", "cup", 30, nil, "usda"},
  {"crackers", "cup", 40, "crushed", "usda"},
  {"graham crackers", "cup", 85, "crushed", "usda"},

  # ============ CONDIMENTS & SAUCES ============
  {"tahini", "cup", 240, nil, "usda"},
  {"tahini", "tbsp", 15, nil, "usda"},
  {"hummus", "cup", 246, nil, "usda"},
  {"salsa", "cup", 260, nil, "usda"},
  {"hot sauce", "tsp", 5, nil, "usda"},
  {"sriracha", "tsp", 5, nil, "usda"},
  {"fish sauce", "tbsp", 18, nil, "usda"},
  {"oyster sauce", "tbsp", 18, nil, "usda"},
  {"hoisin sauce", "tbsp", 16, nil, "usda"},
  {"teriyaki sauce", "tbsp", 18, nil, "usda"},
  {"barbecue sauce", "cup", 280, nil, "usda"},
  {"marinara sauce", "cup", 250, nil, "usda"},
  {"tomato sauce", "cup", 245, nil, "usda"},
  {"enchilada sauce", "cup", 250, nil, "usda"},
  {"buffalo sauce", "tbsp", 17, nil, "usda"},
  {"ranch dressing", "tbsp", 15, nil, "usda"},
  {"italian dressing", "tbsp", 15, nil, "usda"},
  {"caesar dressing", "tbsp", 15, nil, "usda"},
  {"balsamic glaze", "tbsp", 20, nil, "usda"},
  {"pesto", "cup", 260, nil, "usda"},
  {"pesto", "tbsp", 16, nil, "usda"},
  {"chimichurri", "tbsp", 14, nil, "usda"},
  {"tzatziki", "cup", 246, nil, "usda"},
  {"aioli", "tbsp", 14, nil, "usda"},
  {"guacamole", "cup", 230, nil, "usda"},
  {"miso paste", "tbsp", 17, nil, "usda"},
  {"gochujang", "tbsp", 17, nil, "usda"},
  {"sambal oelek", "tbsp", 15, nil, "usda"},
  {"harissa", "tbsp", 15, nil, "usda"},
  {"curry paste", "tbsp", 16, nil, "usda"},
  {"green curry paste", "tbsp", 16, nil, "usda"},
  {"red curry paste", "tbsp", 16, nil, "usda"},
  {"coconut milk", "cup", 240, nil, "usda"},
  {"coconut cream", "cup", 240, nil, "usda"},
  {"cream of coconut", "cup", 280, nil, "usda"},
  {"pickle relish", "tbsp", 15, nil, "usda"},
  {"capers", "tbsp", 9, nil, "usda"},
  {"olives", "cup", 134, "sliced", "usda"},
  {"sun-dried tomatoes", "cup", 110, nil, "usda"},
  {"roasted red peppers", "cup", 140, nil, "usda"},

  # ============ SPICES & SEASONINGS ============
  {"curry powder", "tsp", 2, nil, "usda"},
  {"garam masala", "tsp", 2, nil, "usda"},
  {"italian seasoning", "tsp", 1.5, nil, "usda"},
  {"herbes de provence", "tsp", 1.5, nil, "usda"},
  {"chinese five spice", "tsp", 2, nil, "usda"},
  {"pumpkin pie spice", "tsp", 2, nil, "usda"},
  {"everything bagel seasoning", "tsp", 4, nil, "usda"},
  {"taco seasoning", "tsp", 2.5, nil, "usda"},
  {"old bay seasoning", "tsp", 2.5, nil, "usda"},
  {"ranch seasoning", "tsp", 2.5, nil, "usda"},
  {"cajun seasoning", "tsp", 2.5, nil, "usda"},
  {"creole seasoning", "tsp", 2.5, nil, "usda"},
  {"jerk seasoning", "tsp", 2.5, nil, "usda"},
  {"za'atar", "tsp", 2, nil, "usda"},
  {"sumac", "tsp", 2.5, nil, "usda"},
  {"turmeric", "tsp", 2.2, nil, "usda"},
  {"ginger", "tsp", 1.8, "ground", "usda"},
  {"ginger", "tbsp", 6, "fresh minced", "usda"},
  {"nutmeg", "tsp", 2.2, nil, "usda"},
  {"allspice", "tsp", 1.9, nil, "usda"},
  {"cloves", "tsp", 2.1, "ground", "usda"},
  {"cardamom", "tsp", 2, nil, "usda"},
  {"coriander", "tsp", 1.8, nil, "usda"},
  {"fennel seeds", "tsp", 2, nil, "usda"},
  {"caraway seeds", "tsp", 2.1, nil, "usda"},
  {"mustard seeds", "tsp", 3.3, nil, "usda"},
  {"celery seeds", "tsp", 2, nil, "usda"},
  {"poppy seeds", "tsp", 2.8, nil, "usda"},
  {"red pepper flakes", "tsp", 1.5, nil, "usda"},
  {"crushed red pepper", "tsp", 1.5, nil, "usda"},
  {"white pepper", "tsp", 2.4, nil, "usda"},
  {"smoked paprika", "tsp", 2.3, nil, "usda"},
  {"ancho chili powder", "tsp", 2.6, nil, "usda"},
  {"chipotle powder", "tsp", 2.6, nil, "usda"},
  {"adobo seasoning", "tsp", 2.5, nil, "usda"},
  {"saffron", "tsp", 0.7, nil, "usda"},
  {"msg", "tsp", 5, nil, "usda"},
  {"vanilla extract", "tsp", 4.2, nil, "usda"},
  {"almond extract", "tsp", 4.2, nil, "usda"},
  {"peppermint extract", "tsp", 4.2, nil, "usda"},
  {"lemon extract", "tsp", 4.2, nil, "usda"},

  # ============ HERBS (fresh) ============
  {"cilantro", "cup", 16, "chopped", "usda"},
  {"parsley", "cup", 60, "chopped", "usda"},
  {"dill", "cup", 30, "chopped", "usda"},
  {"mint", "cup", 48, "chopped", "usda"},
  {"tarragon", "cup", 16, "chopped", "usda"},
  {"marjoram", "cup", 16, "chopped", "usda"},
  {"sage", "tbsp", 2, "chopped", "usda"},
  {"chervil", "cup", 16, "chopped", "usda"},
  {"lemongrass", "tbsp", 6, "minced", "usda"},

  # ============ DAIRY & EGGS ============
  {"creme fraiche", "cup", 232, nil, "usda"},
  {"mascarpone", "cup", 227, nil, "usda"},
  {"brie", "cup", 150, "cubed", "usda"},
  {"goat cheese", "cup", 150, "crumbled", "usda"},
  {"feta cheese", "cup", 150, "crumbled", "usda"},
  {"blue cheese", "cup", 135, "crumbled", "usda"},
  {"gorgonzola", "cup", 135, "crumbled", "usda"},
  {"monterey jack", "cup", 113, "shredded", "usda"},
  {"pepper jack", "cup", 113, "shredded", "usda"},
  {"swiss cheese", "cup", 108, "shredded", "usda"},
  {"gruyere", "cup", 108, "shredded", "usda"},
  {"provolone", "cup", 113, "shredded", "usda"},
  {"colby cheese", "cup", 113, "shredded", "usda"},
  {"american cheese", "cup", 113, "shredded", "usda"},
  {"queso fresco", "cup", 120, "crumbled", "usda"},
  {"cotija cheese", "cup", 100, "crumbled", "usda"},
  {"paneer", "cup", 225, "cubed", "usda"},
  {"halloumi", "cup", 200, "cubed", "usda"},
  {"margarine", "cup", 227, nil, "usda"},
  {"margarine", "tbsp", 14, nil, "usda"},
  {"whipped cream", "cup", 60, nil, "usda"},
  {"half and half", "cup", 242, nil, "usda"},
  {"evaporated milk", "cup", 252, nil, "usda"},
  {"condensed milk", "cup", 306, nil, "usda"},
  {"buttermilk", "cup", 245, nil, "usda"},
  {"kefir", "cup", 243, nil, "usda"},
  {"egg whites", "cup", 243, nil, "usda"},
  {"egg yolks", "cup", 243, nil, "usda"},

  # ============ NUTS & SEEDS (more) ============
  {"pistachio", "cup", 123, nil, "usda"},
  {"hazelnut", "cup", 135, nil, "usda"},
  {"chestnut", "cup", 150, nil, "usda"},
  {"macadamia nuts", "cup", 134, nil, "usda"},
  {"brazil nuts", "cup", 133, nil, "usda"},
  {"coconut flakes", "cup", 93, nil, "usda"},
  {"shredded coconut", "cup", 93, nil, "usda"},
  {"hemp seeds", "cup", 160, nil, "usda"},
  {"tahini", "cup", 240, nil, "usda"},

  # ============ OILS & FATS ============
  {"sesame oil", "tbsp", 14, nil, "usda"},
  {"sesame oil", "cup", 218, nil, "usda"},
  {"ghee", "tbsp", 14, nil, "usda"},
  {"ghee", "cup", 218, nil, "usda"},
  {"avocado oil", "tbsp", 14, nil, "usda"},
  {"avocado oil", "cup", 218, nil, "usda"},
  {"walnut oil", "tbsp", 14, nil, "usda"},
  {"peanut oil", "tbsp", 14, nil, "usda"},
  {"canola oil", "tbsp", 14, nil, "usda"},
  {"grapeseed oil", "tbsp", 14, nil, "usda"},
  {"truffle oil", "tsp", 5, nil, "usda"},

  # ============ BEVERAGES & LIQUIDS ============
  {"coffee", "cup", 237, nil, "usda"},
  {"espresso", "tbsp", 15, nil, "usda"},
  {"tea", "cup", 237, nil, "usda"},
  {"beer", "cup", 240, nil, "usda"},
  {"red wine", "cup", 236, nil, "usda"},
  {"white wine", "cup", 236, nil, "usda"},
  {"sherry", "cup", 240, nil, "usda"},
  {"marsala", "cup", 240, nil, "usda"},
  {"port", "cup", 240, nil, "usda"},
  {"brandy", "cup", 240, nil, "usda"},
  {"rum", "cup", 240, nil, "usda"},
  {"bourbon", "cup", 240, nil, "usda"},
  {"vodka", "cup", 240, nil, "usda"},
  {"kahlua", "cup", 280, nil, "usda"},
  {"amaretto", "cup", 280, nil, "usda"},
  {"grand marnier", "cup", 260, nil, "usda"},
  {"triple sec", "cup", 260, nil, "usda"},
  {"coconut water", "cup", 240, nil, "usda"},
  {"almond milk", "cup", 240, nil, "usda"},
  {"oat milk", "cup", 240, nil, "usda"},
  {"soy milk", "cup", 243, nil, "usda"},
  {"rice milk", "cup", 240, nil, "usda"},

  # ============ OTHER / BAKING ============
  {"gelatin", "tbsp", 7, nil, "usda"},
  {"agar agar", "tsp", 2, nil, "usda"},
  {"tapioca", "cup", 152, nil, "usda"},
  {"tapioca starch", "cup", 120, nil, "usda"},
  {"arrowroot", "tbsp", 8, nil, "usda"},
  {"potato starch", "cup", 160, nil, "usda"},
  {"xanthan gum", "tsp", 2.5, nil, "usda"},
  {"cream of tartar", "tsp", 3, nil, "usda"},
  {"baking cocoa", "cup", 86, nil, "usda"},
  {"dutch process cocoa", "cup", 86, nil, "usda"},
  {"dark chocolate", "cup", 170, "chips", "usda"},
  {"white chocolate", "cup", 170, "chips", "usda"},
  {"milk chocolate", "cup", 170, "chips", "usda"},
  {"butterscotch chips", "cup", 170, nil, "usda"},
  {"peanut butter chips", "cup", 170, nil, "usda"},
  {"sprinkles", "tbsp", 12, nil, "usda"},
  {"food coloring", "tsp", 5, nil, "usda"},
  {"marshmallows", "cup", 50, nil, "usda"},
  {"marshmallow fluff", "cup", 90, nil, "usda"},
  {"meringue powder", "tbsp", 7, nil, "usda"},

  # ============ LEGUMES ============
  {"black beans", "cup", 172, "cooked", "usda"},
  {"pinto beans", "cup", 171, "cooked", "usda"},
  {"navy beans", "cup", 182, "cooked", "usda"},
  {"cannellini beans", "cup", 179, "cooked", "usda"},
  {"great northern beans", "cup", 177, "cooked", "usda"},
  {"lima beans", "cup", 170, "cooked", "usda"},
  {"black-eyed peas", "cup", 165, "cooked", "usda"},
  {"chickpeas", "cup", 164, "cooked", "usda"},
  {"lentils", "cup", 198, "cooked", "usda"},
  {"red lentils", "cup", 192, nil, "usda"},
  {"green lentils", "cup", 192, nil, "usda"},
  {"split peas", "cup", 196, nil, "usda"},
  {"edamame", "cup", 155, nil, "usda"},
  {"refried beans", "cup", 252, nil, "usda"},
  {"hummus", "cup", 246, nil, "usda"},
]

# Build a lookup map of ingredient name -> id (including aliases)
name_to_id =
  Repo.all(CanonicalIngredient)
  |> Enum.flat_map(fn ci ->
    all_names = [ci.name | ci.aliases || []]
    Enum.map(all_names, fn name -> {String.downcase(name), ci.id} end)
  end)
  |> Map.new()

IO.puts("Found #{map_size(name_to_id)} canonical ingredient names/aliases")

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

IO.puts("\nInserted/updated: #{inserted} densities")
IO.puts("Skipped (errors): #{skipped}")

if length(missing) > 0 do
  unique_missing = Enum.uniq(missing)
  IO.puts("\nMissing canonical ingredients (#{length(unique_missing)}):")
  unique_missing
  |> Enum.sort()
  |> Enum.take(20)
  |> Enum.each(&IO.puts("  - #{&1}"))
  if length(unique_missing) > 20, do: IO.puts("  ... and #{length(unique_missing) - 20} more")
end

# Print final stats
stats = Ingredients.density_coverage_stats()
IO.puts("\nFinal density coverage:")
IO.puts("  Total ingredients: #{stats.total_ingredients}")
IO.puts("  With density: #{stats.with_density}")
IO.puts("  Without density: #{stats.without_density}")
IO.puts("  Coverage: #{stats.coverage_percent}%")

IO.puts("\nDone!")
