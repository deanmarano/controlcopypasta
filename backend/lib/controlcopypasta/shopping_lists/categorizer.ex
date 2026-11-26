defmodule Controlcopypasta.ShoppingLists.Categorizer do
  @moduledoc """
  Guesses the store aisle for an ingredient name.

  Matching is on whole words, and longer phrases win over single words, so
  "stone ground mustard" is a condiment (not "ground" meat), "eggplant" is not
  an egg, and "olive oil and salt" follows the olive oil.
  """

  # Listed in priority order: when two phrases of the same length match, the
  # category that comes first wins.
  @keywords [
    {"produce",
     [
       "lettuce",
       "spinach",
       "kale",
       "arugula",
       "tomato",
       "tomatoes",
       "onion",
       "garlic",
       "bell pepper",
       "green pepper",
       "red pepper",
       "jalapeno",
       "jalapeño",
       "carrot",
       "celery",
       "cucumber",
       "zucchini",
       "squash",
       "broccoli",
       "cauliflower",
       "potato",
       "potatoes",
       "sweet potato",
       "sweet potatoes",
       "mushroom",
       "apple",
       "banana",
       "orange",
       "lemon",
       "lime",
       "avocado",
       "cilantro",
       "parsley",
       "basil",
       "mint",
       "ginger",
       "scallion",
       "leek",
       "cabbage",
       "corn",
       "pea",
       "green bean",
       "asparagus",
       "shallot",
       "eggplant",
       "radish",
       "beet",
       "berries",
       "strawberries",
       "blueberries",
       "raspberries"
     ]},
    {"protein",
     [
       "chicken",
       "beef",
       "pork",
       "lamb",
       "turkey",
       "bacon",
       "sausage",
       "ham",
       "salmon",
       "tuna",
       "shrimp",
       "fish",
       "steak",
       "tofu",
       "tempeh",
       "egg",
       "ground beef",
       "ground turkey",
       "ground pork",
       "ground chicken",
       "ground lamb",
       "ground meat",
       "cod",
       "scallop",
       "crab",
       "lobster"
     ]},
    {"dairy",
     [
       "milk",
       "cream",
       "butter",
       "cheese",
       "yogurt",
       "sour cream",
       "cream cheese",
       "cottage cheese",
       "ricotta",
       "mozzarella",
       "parmesan",
       "cheddar",
       "feta",
       "goat cheese",
       "buttermilk",
       "half and half",
       "ghee"
     ]},
    {"bakery",
     [
       "bread",
       "roll",
       "bun",
       "bagel",
       "croissant",
       "muffin",
       "cake",
       "pie",
       "pastry",
       "tortilla",
       "pita",
       "naan"
     ]},
    {"frozen", ["frozen", "ice cream", "popsicle"]},
    {"spices",
     [
       "salt",
       "pepper",
       "black pepper",
       "white pepper",
       "cayenne pepper",
       "lemon pepper",
       "red pepper flakes",
       "cumin",
       "paprika",
       "cinnamon",
       "nutmeg",
       "oregano",
       "thyme",
       "rosemary",
       "sage",
       "bay leaf",
       "bay leaves",
       "clove",
       "cardamom",
       "coriander",
       "turmeric",
       "curry",
       "curry powder",
       "chili powder",
       "cayenne",
       "garlic powder",
       "onion powder",
       "garlic salt",
       "celery salt",
       "ground ginger",
       "ginger powder",
       "dried basil",
       "dried parsley",
       "dried oregano",
       "dried thyme",
       "dried mint",
       "mustard seed",
       "mustard powder",
       "dry mustard",
       "cream of tartar",
       "vanilla"
     ]},
    {"condiments",
     [
       "ketchup",
       "mustard",
       "mayonnaise",
       "mayo",
       "soy sauce",
       "hot sauce",
       "bbq sauce",
       "fish sauce",
       "worcestershire sauce",
       "salsa",
       "vinegar",
       "rice vinegar",
       "apple cider vinegar",
       "red wine vinegar",
       "white wine vinegar",
       "oil",
       "olive oil",
       "sesame oil",
       "vegetable oil",
       "honey",
       "maple syrup",
       "sriracha"
     ]},
    {"beverages", ["juice", "soda", "water", "coffee", "tea", "wine", "beer", "apple cider"]},
    {"pantry",
     [
       "tomato paste",
       "tomato sauce",
       "tomato puree",
       "peanut butter",
       "almond butter",
       "cocoa butter",
       "coconut milk",
       "almond milk",
       "oat milk",
       "coconut cream",
       "chicken broth",
       "chicken stock",
       "beef broth",
       "beef stock",
       "vegetable broth",
       "vegetable stock",
       "fish stock",
       "bread crumbs",
       "breadcrumbs",
       "bread flour",
       "corn starch",
       "cornstarch",
       "corn syrup",
       "cornmeal",
       "potato starch",
       "baking soda",
       "baking powder",
       "egg noodles",
       "black beans",
       "kidney beans",
       "white beans",
       "pinto beans",
       "chickpeas"
     ]}
  ]

  # Longest phrase first; ties keep the priority order above.
  @phrases @keywords
           |> Enum.flat_map(fn {category, words} -> Enum.map(words, &{&1, category}) end)
           |> Enum.with_index()
           |> Enum.sort_by(fn {{phrase, _category}, index} ->
             {-length(String.split(phrase)), index}
           end)
           |> Enum.map(fn {pair, _index} -> pair end)

  @doc "Returns one of the shopping list item categories for `name`."
  def categorize(nil), do: "other"

  def categorize(name) when is_binary(name) do
    padded = " " <> normalize(name) <> " "

    Enum.find_value(@phrases, "pantry", fn {phrase, category} ->
      if contains_words?(padded, phrase), do: category
    end)
  end

  defp normalize(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^\p{L}\s]/u, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Whole-word match, allowing a simple plural on the last word.
  defp contains_words?(padded, phrase) do
    String.contains?(padded, " " <> phrase <> " ") or
      String.contains?(padded, " " <> phrase <> "s ") or
      String.contains?(padded, " " <> phrase <> "es ")
  end
end
