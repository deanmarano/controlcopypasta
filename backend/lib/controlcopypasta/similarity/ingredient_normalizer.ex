defmodule Controlcopypasta.Similarity.IngredientNormalizer do
  @moduledoc """
  Normalizes ingredient names to canonical forms for similarity matching.

  This handles:
  - Pluralization (eggs -> egg)
  - Common variations (all-purpose flour -> flour)
  - Brand names removal
  - Descriptor removal (large, small, fresh, etc.)
  """

  # Mapping of ingredient variations to canonical names
  @canonical_ingredients %{
    # Flour
    "all-purpose flour" => "flour",
    "all purpose flour" => "flour",
    "ap flour" => "flour",
    "bread flour" => "bread flour",
    "cake flour" => "cake flour",
    "whole wheat flour" => "whole wheat flour",
    "self-rising flour" => "self-rising flour",
    "self rising flour" => "self-rising flour",
    # Sugar
    "granulated sugar" => "sugar",
    "white sugar" => "sugar",
    "caster sugar" => "sugar",
    "powdered sugar" => "powdered sugar",
    "confectioners sugar" => "powdered sugar",
    "confectioners' sugar" => "powdered sugar",
    "icing sugar" => "powdered sugar",
    "brown sugar" => "brown sugar",
    "light brown sugar" => "brown sugar",
    "dark brown sugar" => "brown sugar",
    # Butter/Oil
    "unsalted butter" => "butter",
    "salted butter" => "butter",
    "vegetable oil" => "vegetable oil",
    "canola oil" => "vegetable oil",
    "olive oil" => "olive oil",
    "extra virgin olive oil" => "olive oil",
    "extra-virgin olive oil" => "olive oil",
    "evoo" => "olive oil",
    "coconut oil" => "coconut oil",
    # Dairy
    "whole milk" => "milk",
    "2% milk" => "milk",
    "skim milk" => "milk",
    "heavy cream" => "heavy cream",
    "heavy whipping cream" => "heavy cream",
    "whipping cream" => "heavy cream",
    "half and half" => "half and half",
    "half-and-half" => "half and half",
    "sour cream" => "sour cream",
    "greek yogurt" => "greek yogurt",
    "plain yogurt" => "yogurt",
    "cream cheese" => "cream cheese",
    # Eggs
    "egg" => "egg",
    "eggs" => "egg",
    "egg white" => "egg white",
    "egg whites" => "egg white",
    "egg yolk" => "egg yolk",
    "egg yolks" => "egg yolk",
    # Salt
    "salt" => "salt",
    "kosher salt" => "salt",
    "sea salt" => "salt",
    "table salt" => "salt",
    "flaky salt" => "salt",
    # Leavening
    "baking powder" => "baking powder",
    "baking soda" => "baking soda",
    "bicarbonate of soda" => "baking soda",
    "yeast" => "yeast",
    "active dry yeast" => "yeast",
    "instant yeast" => "yeast",
    # Vanilla
    "vanilla extract" => "vanilla",
    "vanilla" => "vanilla",
    "pure vanilla extract" => "vanilla",
    "vanilla bean" => "vanilla bean",
    "vanilla paste" => "vanilla",
    # Garlic/Onion
    "garlic" => "garlic",
    "garlic clove" => "garlic",
    "garlic cloves" => "garlic",
    "onion" => "onion",
    "onions" => "onion",
    "yellow onion" => "onion",
    "white onion" => "onion",
    "red onion" => "red onion",
    "green onion" => "green onion",
    "green onions" => "green onion",
    "scallion" => "green onion",
    "scallions" => "green onion",
    "shallot" => "shallot",
    "shallots" => "shallot",
    # Pepper
    "black pepper" => "black pepper",
    "pepper" => "black pepper",
    "ground black pepper" => "black pepper",
    "freshly ground black pepper" => "black pepper",
    "white pepper" => "white pepper",
    "cayenne" => "cayenne",
    "cayenne pepper" => "cayenne",
    "red pepper flakes" => "red pepper flakes",
    "crushed red pepper" => "red pepper flakes",
    # Chicken
    "chicken" => "chicken",
    "chicken breast" => "chicken breast",
    "chicken breasts" => "chicken breast",
    "chicken thigh" => "chicken thigh",
    "chicken thighs" => "chicken thigh",
    "chicken leg" => "chicken leg",
    "chicken legs" => "chicken leg",
    "ground chicken" => "ground chicken",
    # Beef
    "beef" => "beef",
    "ground beef" => "ground beef",
    "beef chuck" => "beef chuck",
    "steak" => "steak",
    "sirloin" => "sirloin",
    "ribeye" => "ribeye",
    # Pork
    "pork" => "pork",
    "ground pork" => "ground pork",
    "pork chop" => "pork chop",
    "pork chops" => "pork chop",
    "bacon" => "bacon",
    "sausage" => "sausage",
    # Tomato
    "tomato" => "tomato",
    "tomatoes" => "tomato",
    "roma tomato" => "tomato",
    "cherry tomato" => "cherry tomato",
    "cherry tomatoes" => "cherry tomato",
    "grape tomato" => "cherry tomato",
    "grape tomatoes" => "cherry tomato",
    "canned tomato" => "canned tomatoes",
    "canned tomatoes" => "canned tomatoes",
    "diced tomatoes" => "canned tomatoes",
    "crushed tomatoes" => "crushed tomatoes",
    "tomato paste" => "tomato paste",
    "tomato sauce" => "tomato sauce",
    # Cheese
    "cheese" => "cheese",
    "cheddar" => "cheddar",
    "cheddar cheese" => "cheddar",
    "parmesan" => "parmesan",
    "parmesan cheese" => "parmesan",
    "parmigiano-reggiano" => "parmesan",
    "mozzarella" => "mozzarella",
    "mozzarella cheese" => "mozzarella",
    "feta" => "feta",
    "feta cheese" => "feta",
    "goat cheese" => "goat cheese",
    # Herbs
    "parsley" => "parsley",
    "cilantro" => "cilantro",
    "coriander" => "cilantro",
    "basil" => "basil",
    "oregano" => "oregano",
    "thyme" => "thyme",
    "rosemary" => "rosemary",
    "sage" => "sage",
    "mint" => "mint",
    "dill" => "dill",
    "chive" => "chives",
    "chives" => "chives",
    "bay leaf" => "bay leaf",
    "bay leaves" => "bay leaf",
    # Spices
    "cinnamon" => "cinnamon",
    "ground cinnamon" => "cinnamon",
    "nutmeg" => "nutmeg",
    "ground nutmeg" => "nutmeg",
    "cumin" => "cumin",
    "ground cumin" => "cumin",
    "paprika" => "paprika",
    "smoked paprika" => "smoked paprika",
    "chili powder" => "chili powder",
    "curry powder" => "curry powder",
    "ginger" => "ginger",
    "ground ginger" => "ground ginger",
    "turmeric" => "turmeric",
    # Vinegar
    "vinegar" => "vinegar",
    "white vinegar" => "white vinegar",
    "red wine vinegar" => "red wine vinegar",
    "white wine vinegar" => "white wine vinegar",
    "balsamic vinegar" => "balsamic vinegar",
    "apple cider vinegar" => "apple cider vinegar",
    "rice vinegar" => "rice vinegar",
    # Soy/Asian
    "soy sauce" => "soy sauce",
    "low sodium soy sauce" => "soy sauce",
    "tamari" => "soy sauce",
    "sesame oil" => "sesame oil",
    "fish sauce" => "fish sauce",
    "oyster sauce" => "oyster sauce",
    "hoisin sauce" => "hoisin sauce",
    # Nuts
    "almond" => "almond",
    "almonds" => "almond",
    "walnut" => "walnut",
    "walnuts" => "walnut",
    "pecan" => "pecan",
    "pecans" => "pecan",
    "peanut" => "peanut",
    "peanuts" => "peanut",
    "cashew" => "cashew",
    "cashews" => "cashew",
    "pistachio" => "pistachio",
    "pistachios" => "pistachio",
    # Citrus
    "lemon" => "lemon",
    "lemons" => "lemon",
    "lemon juice" => "lemon juice",
    "lemon zest" => "lemon zest",
    "lime" => "lime",
    "limes" => "lime",
    "lime juice" => "lime juice",
    "lime zest" => "lime zest",
    "orange" => "orange",
    "oranges" => "orange",
    "orange juice" => "orange juice",
    "orange zest" => "orange zest",
    # Common vegetables
    "carrot" => "carrot",
    "carrots" => "carrot",
    "celery" => "celery",
    "potato" => "potato",
    "potatoes" => "potato",
    "bell pepper" => "bell pepper",
    "bell peppers" => "bell pepper",
    "broccoli" => "broccoli",
    "spinach" => "spinach",
    "kale" => "kale",
    "lettuce" => "lettuce",
    "cucumber" => "cucumber",
    "cucumbers" => "cucumber",
    "zucchini" => "zucchini",
    "mushroom" => "mushroom",
    "mushrooms" => "mushroom"
  }

  @doc """
  Normalizes an ingredient name to its canonical form.
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(name) when is_binary(name) do
    normalized = name |> String.downcase() |> String.trim()

    # First check exact match
    case Map.get(@canonical_ingredients, normalized) do
      nil ->
        # Try without common prefixes
        stripped = strip_descriptors(normalized)

        case Map.get(@canonical_ingredients, stripped) do
          nil ->
            # Return the stripped version as the canonical name
            singularize(stripped)

          canonical ->
            canonical
        end

      canonical ->
        canonical
    end
  end

  @doc """
  Returns a similarity score (0.0 to 1.0) between two ingredient names.
  Uses canonical normalization and Levenshtein distance for fuzzy matching.
  """
  @spec similarity(String.t(), String.t()) :: float()
  def similarity(name1, name2) do
    canonical1 = normalize(name1)
    canonical2 = normalize(name2)

    cond do
      canonical1 == canonical2 ->
        1.0

      String.contains?(canonical1, canonical2) or String.contains?(canonical2, canonical1) ->
        0.8

      true ->
        # Levenshtein-based similarity
        max_len = max(String.length(canonical1), String.length(canonical2))

        if max_len == 0 do
          1.0
        else
          distance = levenshtein(canonical1, canonical2)
          max(0.0, 1.0 - distance / max_len)
        end
    end
  end

  # Simple Levenshtein distance implementation
  defp levenshtein(s1, s2) do
    s1_chars = String.graphemes(s1)
    s2_chars = String.graphemes(s2)

    {dist, _} =
      Enum.reduce(s1_chars, {0..length(s2_chars) |> Enum.to_list(), 0}, fn c1, {prev_row, i} ->
        current_row =
          Enum.reduce(Enum.with_index(s2_chars), [i + 1], fn {c2, j}, row ->
            cost = if c1 == c2, do: 0, else: 1

            val =
              Enum.min([
                Enum.at(row, j) + 1,
                Enum.at(prev_row, j + 1) + 1,
                Enum.at(prev_row, j) + cost
              ])

            row ++ [val]
          end)

        {current_row, i + 1}
      end)

    List.last(dist)
  end

  @descriptors ~w(
    large small medium extra fresh frozen dried organic
    raw cooked ripe unripe whole boneless skinless
  )

  defp strip_descriptors(name) do
    words = String.split(name, " ")

    stripped =
      words
      |> Enum.reject(&(&1 in @descriptors))
      |> Enum.join(" ")

    if String.trim(stripped) == "", do: name, else: stripped
  end

  defp singularize(word) do
    cond do
      String.ends_with?(word, "ies") ->
        String.slice(word, 0..-4//1) <> "y"

      String.ends_with?(word, "ves") ->
        String.slice(word, 0..-4//1) <> "f"

      String.ends_with?(word, "es") and
          String.ends_with?(word, ["shes", "ches", "xes", "zes", "sses"]) ->
        String.slice(word, 0..-3//1)

      String.ends_with?(word, "s") and not String.ends_with?(word, "ss") ->
        String.slice(word, 0..-2//1)

      true ->
        word
    end
  end
end
