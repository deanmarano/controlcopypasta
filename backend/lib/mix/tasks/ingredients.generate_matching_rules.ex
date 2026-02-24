defmodule Mix.Tasks.Ingredients.GenerateMatchingRules do
  @moduledoc """
  Generates initial matching rules for top canonical ingredients.

  Uses category-based templates and ingredient-specific overrides to create
  boost words and anti-patterns for ingredient matching.

  ## Usage

      mix ingredients.generate_matching_rules
      mix ingredients.generate_matching_rules --dry-run
      mix ingredients.generate_matching_rules --limit 200
  """
  use Mix.Task
  import Ecto.Query

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @shortdoc "Generate matching rules for top ingredients"

  # Default scoring parameters
  @default_boost_amount 0.05
  @default_anti_penalty 0.15

  # Category-based rule templates
  @category_rules %{
    "protein" => %{
      "boost_words" => ["fresh", "raw"],
      "anti_patterns" => ["sauce", "broth", "stock", "gravy", "seasoning", "flavoring"]
    },
    "produce" => %{
      "boost_words" => ["fresh", "ripe", "raw", "organic"],
      "anti_patterns" => ["sauce", "paste", "puree", "canned", "dried", "juice", "extract"]
    },
    "dairy" => %{
      "boost_words" => ["fresh", "whole", "full-fat"],
      "anti_patterns" => ["free", "substitute", "alternative", "flavored"]
    },
    "grain" => %{
      "boost_words" => ["whole", "fresh"],
      "anti_patterns" => ["flour", "meal", "starch", "syrup"]
    },
    "spice" => %{
      "boost_words" => ["ground", "whole", "fresh"],
      "anti_patterns" => ["extract", "flavoring", "blend", "mix"]
    },
    "herb" => %{
      "boost_words" => ["fresh", "whole"],
      "anti_patterns" => ["dried", "extract", "oil", "paste"]
    },
    "oil" => %{
      "boost_words" => ["extra", "virgin", "pure", "cold-pressed"],
      "anti_patterns" => ["spray", "blend", "flavored"]
    },
    "condiment" => %{
      "boost_words" => [],
      "anti_patterns" => []
    },
    "sweetener" => %{
      "boost_words" => ["pure", "raw", "natural"],
      "anti_patterns" => ["free", "substitute", "flavored", "artificial"]
    },
    "nut" => %{
      "boost_words" => ["raw", "whole", "fresh", "roasted"],
      "anti_patterns" => ["butter", "milk", "flour", "oil", "extract"]
    },
    "legume" => %{
      "boost_words" => ["dried", "fresh", "whole"],
      "anti_patterns" => ["flour", "paste", "canned"]
    }
  }

  # Specific ingredient overrides (name => rules)
  @ingredient_overrides %{
    "chicken breast" => %{
      "boost_words" => ["boneless", "skinless", "breast", "fresh"],
      "anti_patterns" => ["thigh", "wing", "leg", "drumstick", "tender", "strip", "nugget"]
    },
    "chicken thigh" => %{
      "boost_words" => ["boneless", "skinless", "thigh", "fresh"],
      "anti_patterns" => ["breast", "wing", "leg", "drumstick"]
    },
    "ground beef" => %{
      "boost_words" => ["lean", "ground", "fresh"],
      "anti_patterns" => ["patty", "meatball", "seasoned"]
    },
    "tomato" => %{
      "boost_words" => ["fresh", "ripe", "roma", "cherry", "grape", "heirloom", "vine"],
      "anti_patterns" => [
        "sauce",
        "paste",
        "puree",
        "canned",
        "diced",
        "crushed",
        "sun-dried",
        "juice"
      ],
      "exclude_patterns" => ["\\btomato\\s+sauce\\b", "\\btomato\\s+paste\\b"]
    },
    "tomato sauce" => %{
      "boost_words" => ["sauce", "marinara"],
      "anti_patterns" => ["fresh", "raw", "cherry", "grape"],
      "required_words" => ["sauce"]
    },
    "tomato paste" => %{
      "boost_words" => ["paste", "concentrated"],
      "anti_patterns" => ["fresh", "raw", "sauce"],
      "required_words" => ["paste"]
    },
    "garlic" => %{
      "boost_words" => ["fresh", "clove", "minced", "whole", "head"],
      "anti_patterns" => ["powder", "granulated", "paste", "salt", "bread", "spread"]
    },
    "garlic powder" => %{
      "boost_words" => ["powder", "granulated"],
      "anti_patterns" => ["fresh", "clove", "minced", "whole"],
      "required_words" => ["powder"]
    },
    "olive oil" => %{
      "boost_words" => ["extra", "virgin", "evoo", "pure"],
      "anti_patterns" => ["vegetable", "canola", "coconut", "spray"]
    },
    "butter" => %{
      "boost_words" => ["unsalted", "salted", "european", "grass-fed"],
      "anti_patterns" => ["peanut", "almond", "nut", "spread", "substitute"]
    },
    "onion" => %{
      "boost_words" => ["fresh", "yellow", "white", "red", "sweet", "vidalia"],
      "anti_patterns" => ["powder", "flakes", "dried", "soup", "rings", "fried"]
    },
    "onion powder" => %{
      "boost_words" => ["powder", "granulated"],
      "anti_patterns" => ["fresh", "yellow", "white", "red"],
      "required_words" => ["powder"]
    },
    "lemon" => %{
      "boost_words" => ["fresh", "whole", "meyer"],
      "anti_patterns" => ["juice", "zest", "extract", "peel", "curd", "pepper"]
    },
    "lemon juice" => %{
      "boost_words" => ["juice", "fresh", "squeezed"],
      "anti_patterns" => ["whole", "zest", "peel"],
      "required_words" => ["juice"]
    },
    "egg" => %{
      "boost_words" => ["large", "fresh", "whole", "free-range", "organic"],
      "anti_patterns" => ["white", "yolk", "substitute", "beater", "noodle", "wash"]
    },
    "egg white" => %{
      "boost_words" => ["white", "fresh"],
      "anti_patterns" => ["whole", "yolk"],
      "required_words" => ["white"]
    },
    "flour" => %{
      "boost_words" => ["all-purpose", "white", "wheat"],
      "anti_patterns" => [
        "almond",
        "coconut",
        "rice",
        "oat",
        "self-rising",
        "bread",
        "cake",
        "pastry"
      ]
    },
    "almond flour" => %{
      "boost_words" => ["almond", "blanched", "superfine"],
      "anti_patterns" => ["all-purpose", "wheat", "coconut"],
      "required_words" => ["almond"]
    },
    "sugar" => %{
      "boost_words" => ["white", "granulated", "cane"],
      "anti_patterns" => ["brown", "powdered", "confectioner", "raw", "coconut", "maple"]
    },
    "brown sugar" => %{
      "boost_words" => ["brown", "light", "dark", "packed"],
      "anti_patterns" => ["white", "granulated"],
      "required_words" => ["brown"]
    },
    "salt" => %{
      "boost_words" => ["kosher", "sea", "fine", "table"],
      "anti_patterns" => ["garlic", "onion", "celery", "seasoned", "pepper"]
    },
    "black pepper" => %{
      "boost_words" => ["black", "ground", "freshly", "cracked", "whole"],
      "anti_patterns" => ["white", "cayenne", "red", "bell"]
    },
    "milk" => %{
      "boost_words" => ["whole", "2%", "skim", "fresh"],
      "anti_patterns" => [
        "coconut",
        "almond",
        "oat",
        "soy",
        "condensed",
        "evaporated",
        "buttermilk"
      ]
    },
    "coconut milk" => %{
      "boost_words" => ["coconut", "full-fat", "light"],
      "anti_patterns" => ["whole", "2%", "dairy", "almond"],
      "required_words" => ["coconut"]
    },
    "parsley" => %{
      "boost_words" => ["fresh", "flat-leaf", "italian", "curly"],
      "anti_patterns" => ["dried", "flakes"]
    },
    "cilantro" => %{
      "boost_words" => ["fresh", "whole"],
      "anti_patterns" => ["dried", "coriander", "paste"]
    },
    "basil" => %{
      "boost_words" => ["fresh", "sweet", "thai"],
      "anti_patterns" => ["dried", "paste", "pesto"]
    },
    "cream cheese" => %{
      "boost_words" => ["cream", "full-fat", "regular"],
      "anti_patterns" => ["neufchatel", "light", "fat-free", "flavored"],
      "required_words" => ["cream"]
    },
    "sour cream" => %{
      "boost_words" => ["sour", "full-fat", "regular"],
      "anti_patterns" => ["light", "fat-free", "greek", "yogurt"],
      "required_words" => ["sour"]
    },
    "heavy cream" => %{
      "boost_words" => ["heavy", "whipping", "double"],
      "anti_patterns" => ["light", "half", "sour", "ice"],
      "required_words" => ["cream"]
    },
    "rice" => %{
      "boost_words" => ["white", "long-grain", "basmati", "jasmine"],
      "anti_patterns" => [
        "brown",
        "wild",
        "arborio",
        "sushi",
        "fried",
        "vinegar",
        "wine",
        "paper",
        "noodle"
      ]
    },
    "brown rice" => %{
      "boost_words" => ["brown", "whole", "long-grain"],
      "anti_patterns" => ["white", "wild", "fried"],
      "required_words" => ["brown"]
    },
    "chicken" => %{
      "boost_words" => ["whole", "fresh", "roasted"],
      "anti_patterns" => [
        "broth",
        "stock",
        "bouillon",
        "seasoning",
        "breast",
        "thigh",
        "wing",
        "drumstick"
      ]
    },
    "beef" => %{
      "boost_words" => ["fresh", "lean"],
      "anti_patterns" => ["broth", "stock", "bouillon", "ground", "corned", "jerky"]
    },
    "pork" => %{
      "boost_words" => ["fresh", "lean"],
      "anti_patterns" => ["bacon", "ham", "sausage", "chop", "loin", "tenderloin"]
    },
    "salmon" => %{
      "boost_words" => ["fresh", "wild", "atlantic", "fillet", "sockeye"],
      "anti_patterns" => ["smoked", "canned", "lox"]
    },
    "shrimp" => %{
      "boost_words" => ["fresh", "raw", "peeled", "deveined", "large", "jumbo"],
      "anti_patterns" => ["dried", "paste", "cocktail", "popcorn"]
    }
  }

  def run(args) do
    dry_run = "--dry-run" in args
    limit = parse_limit(args) || 200

    Mix.Task.run("app.start")

    if dry_run do
      IO.puts("=== DRY RUN MODE ===\n")
    end

    # Get top ingredients by usage
    ingredients =
      CanonicalIngredient
      |> where([i], i.usage_count > 0)
      |> order_by([i], desc: i.usage_count)
      |> limit(^limit)
      |> Repo.all()

    IO.puts("Processing #{length(ingredients)} ingredients...\n")

    # Generate rules for each ingredient
    updates =
      ingredients
      |> Enum.map(fn ing ->
        rules = generate_rules(ing)
        {ing, rules}
      end)
      |> Enum.filter(fn {_ing, rules} -> rules != nil and map_size(rules) > 0 end)

    # Display summary
    with_overrides =
      Enum.count(updates, fn {ing, _} -> Map.has_key?(@ingredient_overrides, ing.name) end)

    with_category = length(updates) - with_overrides

    IO.puts("Generated rules for #{length(updates)} ingredients:")
    IO.puts("  - #{with_overrides} with specific overrides")
    IO.puts("  - #{with_category} with category defaults\n")

    # Show sample rules
    IO.puts("Sample rules:\n")

    updates
    |> Enum.take(10)
    |> Enum.each(fn {ing, rules} ->
      IO.puts("  #{ing.display_name} (#{ing.category || "uncategorized"}):")

      if rules["boost_words"] && length(rules["boost_words"]) > 0 do
        IO.puts("    boost: #{Enum.join(rules["boost_words"], ", ")}")
      end

      if rules["anti_patterns"] && length(rules["anti_patterns"]) > 0 do
        IO.puts("    anti:  #{Enum.join(rules["anti_patterns"], ", ")}")
      end

      if rules["required_words"] && length(rules["required_words"]) > 0 do
        IO.puts("    req:   #{Enum.join(rules["required_words"], ", ")}")
      end

      if rules["exclude_patterns"] && length(rules["exclude_patterns"]) > 0 do
        IO.puts("    excl:  #{Enum.join(rules["exclude_patterns"], ", ")}")
      end

      IO.puts("")
    end)

    unless dry_run do
      IO.puts("Updating database...")

      Enum.each(updates, fn {ing, rules} ->
        ing
        |> Ecto.Changeset.change(matching_rules: rules)
        |> Repo.update!()
      end)

      IO.puts("Done! Updated #{length(updates)} ingredients with matching rules.")
    else
      IO.puts("=== DRY RUN - No changes made ===")
    end
  end

  defp parse_limit(args) do
    case Enum.find(args, &String.starts_with?(&1, "--limit")) do
      "--limit" <> rest when rest != "" ->
        rest |> String.trim_leading("=") |> String.to_integer()

      _ ->
        # Check for --limit N pattern
        args
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.find_value(fn
          ["--limit", n] -> String.to_integer(n)
          _ -> nil
        end)
    end
  end

  defp generate_rules(ingredient) do
    # Check for specific override first
    case Map.get(@ingredient_overrides, ingredient.name) do
      nil ->
        # Fall back to category defaults
        generate_category_rules(ingredient)

      override ->
        # Merge override with defaults
        add_default_amounts(override)
    end
  end

  defp generate_category_rules(ingredient) do
    case Map.get(@category_rules, ingredient.category) do
      nil ->
        # No rules for this category
        nil

      template ->
        add_default_amounts(template)
    end
  end

  defp add_default_amounts(rules) do
    rules
    |> Map.put_new("boost_amount", @default_boost_amount)
    |> Map.put_new("anti_penalty", @default_anti_penalty)
    |> Map.put_new("required_words", [])
    |> Map.put_new("exclude_patterns", [])
  end
end
