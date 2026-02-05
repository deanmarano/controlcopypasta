defmodule Controlcopypasta.Repo.Migrations.PopulateNormalizerData do
  use Ecto.Migration

  @doc """
  Data migration that merges the IngredientNormalizer's @canonical_ingredients map
  into the canonical_ingredients table as similarity_name values and aliases.

  For each {variant, canonical_form} entry:
  - If variant matches a canonical_ingredient name: set similarity_name = canonical_form
  - If variant matches an existing alias: set similarity_name on the owning ingredient
  - Otherwise: add variant as alias on the canonical_ingredient named canonical_form,
    or skip if the canonical_form ingredient doesn't exist
  """

  def up do
    # Process each normalizer entry
    for {variant, canonical_form} <- normalizer_map() do
      # Skip identity mappings (where variant == canonical_form)
      if variant != canonical_form do
        # Try to set similarity_name on the variant if it exists as a canonical ingredient
        {rows_updated, _} = repo().query!(
          "UPDATE canonical_ingredients SET similarity_name = $1 WHERE name = $2 AND similarity_name IS NULL",
          [canonical_form, variant]
        ) |> then(fn %{num_rows: n} -> {n, nil} end)

        if rows_updated == 0 do
          # Check if variant is an existing alias
          result = repo().query!(
            "SELECT id FROM canonical_ingredients WHERE $1 = ANY(aliases) LIMIT 1",
            [variant]
          )

          if result.num_rows > 0 do
            # Set similarity_name on the owning ingredient
            [[id]] = result.rows
            repo().query!(
              "UPDATE canonical_ingredients SET similarity_name = $1 WHERE id = $2 AND similarity_name IS NULL",
              [canonical_form, id]
            )
          else
            # Add variant as an alias on the canonical_form ingredient
            repo().query!(
              "UPDATE canonical_ingredients SET aliases = array_append(aliases, $1) WHERE name = $2 AND NOT ($1 = ANY(aliases))",
              [variant, canonical_form]
            )
          end
        end
      end
    end
  end

  def down do
    # Clear all similarity_name values
    repo().query!("UPDATE canonical_ingredients SET similarity_name = NULL")

    # Note: We don't remove aliases added by this migration since we can't
    # reliably distinguish them from aliases added by other means
  end

  # The normalizer map from IngredientNormalizer
  # Only entries where variant != canonical_form are meaningful for migration
  defp normalizer_map do
    %{
      # Flour
      "all-purpose flour" => "flour",
      "all purpose flour" => "flour",
      "ap flour" => "flour",
      # Sugar
      "granulated sugar" => "sugar",
      "white sugar" => "sugar",
      "caster sugar" => "sugar",
      "confectioners sugar" => "powdered sugar",
      "confectioners' sugar" => "powdered sugar",
      "icing sugar" => "powdered sugar",
      "light brown sugar" => "brown sugar",
      "dark brown sugar" => "brown sugar",
      # Butter/Oil
      "unsalted butter" => "butter",
      "salted butter" => "butter",
      "canola oil" => "vegetable oil",
      "extra virgin olive oil" => "olive oil",
      "extra-virgin olive oil" => "olive oil",
      "evoo" => "olive oil",
      # Dairy
      "whole milk" => "milk",
      "2% milk" => "milk",
      "skim milk" => "milk",
      "heavy whipping cream" => "heavy cream",
      "whipping cream" => "heavy cream",
      "half-and-half" => "half and half",
      "plain yogurt" => "yogurt",
      # Eggs (plurals handled by singularizer, but similarity_name is useful)
      "eggs" => "egg",
      "egg whites" => "egg white",
      "egg yolks" => "egg yolk",
      # Salt
      "kosher salt" => "salt",
      "sea salt" => "salt",
      "table salt" => "salt",
      "flaky salt" => "salt",
      # Leavening
      "bicarbonate of soda" => "baking soda",
      "active dry yeast" => "yeast",
      "instant yeast" => "yeast",
      # Vanilla
      "vanilla extract" => "vanilla",
      "pure vanilla extract" => "vanilla",
      "vanilla paste" => "vanilla",
      # Garlic/Onion
      "garlic clove" => "garlic",
      "garlic cloves" => "garlic",
      "onions" => "onion",
      "yellow onion" => "onion",
      "white onion" => "onion",
      "green onions" => "green onion",
      "scallion" => "green onion",
      "scallions" => "green onion",
      "shallots" => "shallot",
      # Pepper
      "pepper" => "black pepper",
      "ground black pepper" => "black pepper",
      "freshly ground black pepper" => "black pepper",
      "cayenne pepper" => "cayenne",
      "crushed red pepper" => "red pepper flakes",
      # Chicken
      "chicken breasts" => "chicken breast",
      "chicken thighs" => "chicken thigh",
      "chicken legs" => "chicken leg",
      # Pork
      "pork chops" => "pork chop",
      # Tomato
      "tomatoes" => "tomato",
      "roma tomato" => "tomato",
      "cherry tomatoes" => "cherry tomato",
      "grape tomato" => "cherry tomato",
      "grape tomatoes" => "cherry tomato",
      "canned tomato" => "canned tomatoes",
      "diced tomatoes" => "canned tomatoes",
      # Cheese
      "cheddar cheese" => "cheddar",
      "parmesan cheese" => "parmesan",
      "parmigiano-reggiano" => "parmesan",
      "mozzarella cheese" => "mozzarella",
      "feta cheese" => "feta",
      # Herbs
      "coriander" => "cilantro",
      "chive" => "chives",
      "bay leaves" => "bay leaf",
      # Spices
      "ground cinnamon" => "cinnamon",
      "ground nutmeg" => "nutmeg",
      "ground cumin" => "cumin",
      # Vinegar - these are distinct, no normalization needed
      # Soy/Asian
      "low sodium soy sauce" => "soy sauce",
      "tamari" => "soy sauce",
      # Nuts (plurals)
      "almonds" => "almond",
      "walnuts" => "walnut",
      "pecans" => "pecan",
      "peanuts" => "peanut",
      "cashews" => "cashew",
      "pistachios" => "pistachio",
      # Citrus
      "lemons" => "lemon",
      "limes" => "lime",
      "oranges" => "orange",
      # Common vegetables (plurals)
      "carrots" => "carrot",
      "potatoes" => "potato",
      "bell peppers" => "bell pepper",
      "cucumbers" => "cucumber",
      "mushrooms" => "mushroom"
    }
  end
end
