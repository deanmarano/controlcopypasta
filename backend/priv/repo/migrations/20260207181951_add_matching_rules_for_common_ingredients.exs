defmodule Controlcopypasta.Repo.Migrations.AddMatchingRulesForCommonIngredients do
  use Ecto.Migration

  @moduledoc """
  Adds matching rules for common ingredients that don't have them yet.
  These rules help the ingredient matcher disambiguate similar ingredients.

  Rules structure:
  - boost_words: words that increase confidence (varieties, preparations)
  - anti_patterns: words that decrease confidence (suggest different ingredient)
  - required_words: words that must be present (rarely used)
  - exclude_patterns: regex patterns that disqualify (rarely used)
  """

  @default_rule %{
    "boost_words" => [],
    "anti_patterns" => [],
    "required_words" => [],
    "exclude_patterns" => [],
    "boost_amount" => 0.05,
    "anti_penalty" => 0.15
  }

  def up do
    rules = [
      # Baking basics
      {"water", %{
        "boost_words" => ["cold", "warm", "hot", "ice", "room temperature", "lukewarm", "boiling"],
        "anti_patterns" => ["coconut", "rose", "orange", "soda", "tonic", "sparkling", "mineral"]
      }},
      {"baking powder", %{
        "boost_words" => ["double-acting", "aluminum-free"],
        "anti_patterns" => ["soda", "yeast", "flour"]
      }},
      {"baking soda", %{
        "boost_words" => ["arm", "hammer"],
        "anti_patterns" => ["powder", "yeast"]
      }},
      {"yeast", %{
        "boost_words" => ["active", "dry", "instant", "rapid", "fresh", "cake"],
        "anti_patterns" => ["nutritional", "extract", "brewer"]
      }},

      # Sauces and condiments
      {"soy sauce", %{
        "boost_words" => ["light", "dark", "low-sodium", "tamari", "shoyu"],
        "anti_patterns" => ["fish", "oyster", "hoisin", "teriyaki", "worcestershire"]
      }},
      {"mayonnaise", %{
        "boost_words" => ["hellmann", "best foods", "duke", "kewpie", "homemade"],
        "anti_patterns" => ["mustard", "aioli", "ranch"]
      }},
      {"mustard", %{
        "boost_words" => ["yellow", "prepared", "american", "ballpark"],
        "anti_patterns" => ["dijon", "whole grain", "powder", "seed", "honey"]
      }},
      {"dijon mustard", %{
        "boost_words" => ["french", "grey poupon", "maille"],
        "anti_patterns" => ["yellow", "honey", "whole grain", "powder"]
      }},
      {"hot sauce", %{
        "boost_words" => ["tabasco", "frank", "louisiana", "cayenne", "buffalo"],
        "anti_patterns" => ["sriracha", "chili", "sambal", "gochujang"]
      }},
      {"worcestershire sauce", %{
        "boost_words" => ["lea", "perrins"],
        "anti_patterns" => ["soy", "fish", "oyster"]
      }},
      {"fish sauce", %{
        "boost_words" => ["nam pla", "nuoc mam", "thai", "vietnamese", "red boat"],
        "anti_patterns" => ["soy", "oyster", "worcestershire"]
      }},
      {"ketchup", %{
        "boost_words" => ["heinz", "tomato"],
        "anti_patterns" => ["mustard", "mayo", "bbq", "sriracha"]
      }},
      {"tomato paste", %{
        "boost_words" => ["double", "concentrated", "tube"],
        "anti_patterns" => ["sauce", "puree", "crushed", "diced", "canned"]
      }},
      {"tomato sauce", %{
        "boost_words" => ["canned", "plain"],
        "anti_patterns" => ["paste", "marinara", "pizza", "pasta"]
      }},

      # Vinegars
      {"apple cider vinegar", %{
        "boost_words" => ["bragg", "raw", "unfiltered", "mother"],
        "anti_patterns" => ["white", "wine", "balsamic", "rice", "red"]
      }},
      {"rice vinegar", %{
        "boost_words" => ["seasoned", "unseasoned", "japanese", "mirin"],
        "anti_patterns" => ["wine", "white", "apple", "balsamic"]
      }},
      {"red wine vinegar", %{
        "boost_words" => ["french", "italian"],
        "anti_patterns" => ["white", "balsamic", "apple", "rice", "sherry"]
      }},
      {"balsamic vinegar", %{
        "boost_words" => ["aged", "modena", "traditional", "glaze"],
        "anti_patterns" => ["white", "wine", "apple", "rice"]
      }},
      {"white vinegar", %{
        "boost_words" => ["distilled"],
        "anti_patterns" => ["wine", "balsamic", "apple", "rice", "red"]
      }},
      {"white wine vinegar", %{
        "boost_words" => ["french", "champagne"],
        "anti_patterns" => ["red", "balsamic", "apple", "rice"]
      }},
      {"vinegar", %{
        "boost_words" => [],
        "anti_patterns" => ["balsamic", "apple", "rice", "wine", "white", "red", "sherry", "malt"]
      }},

      # Broths
      {"chicken broth", %{
        "boost_words" => ["low-sodium", "unsalted", "homemade", "organic"],
        "anti_patterns" => ["beef", "vegetable", "bone", "fish", "seafood"]
      }},
      {"vegetable broth", %{
        "boost_words" => ["low-sodium", "unsalted", "homemade", "organic"],
        "anti_patterns" => ["chicken", "beef", "bone", "fish"]
      }},
      {"beef broth", %{
        "boost_words" => ["low-sodium", "unsalted", "homemade", "organic"],
        "anti_patterns" => ["chicken", "vegetable", "bone", "fish"]
      }},

      # Alcohol
      {"wine", %{
        "boost_words" => ["cooking", "dry"],
        "anti_patterns" => ["red", "white", "rice", "vinegar", "marsala", "sherry", "port"]
      }},
      {"rum", %{
        "boost_words" => ["dark", "light", "white", "spiced", "gold", "aged"],
        "anti_patterns" => ["extract", "flavoring"]
      }},
      {"bourbon", %{
        "boost_words" => ["kentucky", "small batch"],
        "anti_patterns" => ["vanilla", "extract", "whiskey"]
      }},

      # Nuts and seeds
      {"peanut butter", %{
        "boost_words" => ["creamy", "smooth", "crunchy", "chunky", "natural", "unsweetened"],
        "anti_patterns" => ["almond", "cashew", "sunflower", "tahini"]
      }},
      {"sesame seeds", %{
        "boost_words" => ["white", "black", "toasted", "unhulled", "hulled"],
        "anti_patterns" => ["oil", "tahini", "paste"]
      }},
      {"tahini", %{
        "boost_words" => ["sesame", "paste"],
        "anti_patterns" => ["seeds", "oil"]
      }},
      {"pine nuts", %{
        "boost_words" => ["pignoli", "italian", "toasted"],
        "anti_patterns" => []
      }},
      {"almond flour", %{
        "boost_words" => ["blanched", "super-fine", "bob"],
        "anti_patterns" => ["meal", "whole", "sliced", "slivered"]
      }},
      {"flax meal", %{
        "boost_words" => ["ground", "golden", "brown"],
        "anti_patterns" => ["seed", "whole", "oil"]
      }},

      # Beverages
      {"coffee", %{
        "boost_words" => ["brewed", "strong", "espresso", "instant"],
        "anti_patterns" => ["liqueur", "extract", "flavored"]
      }},

      # Vegetables
      {"peas", %{
        "boost_words" => ["green", "garden", "english", "sweet", "frozen", "fresh"],
        "anti_patterns" => ["snow", "snap", "split", "black-eyed", "chickpea"]
      }},
      {"green chile", %{
        "boost_words" => ["hatch", "anaheim", "roasted", "canned", "diced"],
        "anti_patterns" => ["red", "chipotle", "jalapeno", "serrano", "poblano"]
      }},
      {"radish", %{
        "boost_words" => ["red", "daikon", "watermelon", "breakfast", "french"],
        "anti_patterns" => ["horseradish"]
      }},
      {"asparagus", %{
        "boost_words" => ["fresh", "green", "white", "pencil", "jumbo"],
        "anti_patterns" => []
      }},

      # Beans
      {"kidney beans", %{
        "boost_words" => ["red", "dark", "light", "canned"],
        "anti_patterns" => ["white", "black", "pinto", "navy"]
      }},

      # Spices
      {"ground cloves", %{
        "boost_words" => [],
        "anti_patterns" => ["whole", "garlic"]
      }},
      {"white pepper", %{
        "boost_words" => ["ground", "fine"],
        "anti_patterns" => ["black", "peppercorn"]
      }},
      {"black peppercorns", %{
        "boost_words" => ["whole", "tellicherry"],
        "anti_patterns" => ["ground", "white", "pink", "green"]
      }},

      # Sweeteners
      {"molasses", %{
        "boost_words" => ["blackstrap", "unsulphured", "dark", "light"],
        "anti_patterns" => ["pomegranate"]
      }},
      {"coconut sugar", %{
        "boost_words" => ["organic", "unrefined"],
        "anti_patterns" => ["palm", "brown", "white", "cane"]
      }},

      # Chocolates
      {"bittersweet chocolate", %{
        "boost_words" => ["ghirardelli", "valrhona", "callebaut", "chips", "bar"],
        "anti_patterns" => ["milk", "white", "semi-sweet", "unsweetened", "cocoa"]
      }},
      {"white chocolate", %{
        "boost_words" => ["chips", "bar", "ghirardelli"],
        "anti_patterns" => ["dark", "milk", "bittersweet", "semi-sweet"]
      }},

      # Oils
      {"avocado oil", %{
        "boost_words" => ["refined", "unrefined", "cold-pressed"],
        "anti_patterns" => ["olive", "coconut", "vegetable", "sesame"]
      }},

      # Asian ingredients
      {"miso", %{
        "boost_words" => ["white", "red", "yellow", "shiro", "aka", "paste"],
        "anti_patterns" => ["soup", "broth"]
      }},
      {"tamari", %{
        "boost_words" => ["gluten-free", "san-j"],
        "anti_patterns" => ["soy sauce"]
      }},

      # Misc
      {"ice", %{
        "boost_words" => ["cubes", "crushed"],
        "anti_patterns" => ["cream", "water"]
      }}
    ]

    for {name, custom_rules} <- rules do
      full_rules = Map.merge(@default_rule, custom_rules) |> Jason.encode!()

      execute """
      UPDATE canonical_ingredients
      SET matching_rules = '#{escape_json(full_rules)}'::jsonb
      WHERE name = '#{escape_sql(name)}'
      AND (matching_rules IS NULL OR matching_rules = '{}'::jsonb)
      """
    end
  end

  def down do
    names = [
      "water", "baking powder", "baking soda", "yeast",
      "soy sauce", "mayonnaise", "mustard", "dijon mustard", "hot sauce",
      "worcestershire sauce", "fish sauce", "ketchup", "tomato paste", "tomato sauce",
      "apple cider vinegar", "rice vinegar", "red wine vinegar", "balsamic vinegar",
      "white vinegar", "white wine vinegar", "vinegar",
      "chicken broth", "vegetable broth", "beef broth",
      "wine", "rum", "bourbon",
      "peanut butter", "sesame seeds", "tahini", "pine nuts", "almond flour", "flax meal",
      "coffee", "peas", "green chile", "radish", "asparagus",
      "kidney beans", "ground cloves", "white pepper", "black peppercorns",
      "molasses", "coconut sugar", "bittersweet chocolate", "white chocolate",
      "avocado oil", "miso", "tamari", "ice"
    ]

    for name <- names do
      execute """
      UPDATE canonical_ingredients
      SET matching_rules = NULL
      WHERE name = '#{escape_sql(name)}'
      """
    end
  end

  defp escape_sql(str), do: String.replace(str, "'", "''")
  defp escape_json(str), do: String.replace(str, "'", "''")
end
