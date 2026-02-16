defmodule Controlcopypasta.Nutrition.CalculatorTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Nutrition.Calculator
  alias Controlcopypasta.Nutrition.DensityConverter
  alias Controlcopypasta.Nutrition.Range
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Recipes

  # Helper to extract "best" value from a range map or return scalar directly
  defp get_value(%{best: best}), do: best
  defp get_value(%Range{best: best}), do: best
  defp get_value(value), do: value

  describe "calculate_recipe_nutrition/2" do
    setup do
      # Create a user for recipes
      {:ok, user} = Controlcopypasta.Accounts.create_user(%{email: "test@example.com"})

      # Create canonical ingredients
      {:ok, flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "all-purpose flour",
          display_name: "All-Purpose Flour",
          category: "grain"
        })

      {:ok, sugar} =
        Ingredients.create_canonical_ingredient(%{
          name: "granulated sugar",
          display_name: "Granulated Sugar",
          category: "sweetener"
        })

      {:ok, butter} =
        Ingredients.create_canonical_ingredient(%{
          name: "test butter",
          display_name: "Test Butter",
          category: "dairy"
        })

      # Create densities
      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: flour.id,
          volume_unit: "cup",
          grams_per_unit: Decimal.new("125"),
          source: "usda"
        })

      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: sugar.id,
          volume_unit: "cup",
          grams_per_unit: Decimal.new("200"),
          source: "usda"
        })

      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: butter.id,
          volume_unit: "tbsp",
          grams_per_unit: Decimal.new("14"),
          source: "usda"
        })

      # Create nutrition data
      {:ok, _} =
        Ingredients.create_nutrition(%{
          canonical_ingredient_id: flour.id,
          source: :usda,
          serving_size_value: Decimal.new("100"),
          serving_size_unit: "g",
          calories: Decimal.new("364"),
          protein_g: Decimal.new("10.33"),
          carbohydrates_g: Decimal.new("76.31"),
          fat_total_g: Decimal.new("0.98"),
          fiber_g: Decimal.new("2.7"),
          sugar_g: Decimal.new("0.27")
        })

      {:ok, _} =
        Ingredients.create_nutrition(%{
          canonical_ingredient_id: sugar.id,
          source: :usda,
          serving_size_value: Decimal.new("100"),
          serving_size_unit: "g",
          calories: Decimal.new("387"),
          protein_g: Decimal.new("0"),
          carbohydrates_g: Decimal.new("100"),
          fat_total_g: Decimal.new("0"),
          fiber_g: Decimal.new("0"),
          sugar_g: Decimal.new("100")
        })

      {:ok, _} =
        Ingredients.create_nutrition(%{
          canonical_ingredient_id: butter.id,
          source: :usda,
          serving_size_value: Decimal.new("100"),
          serving_size_unit: "g",
          calories: Decimal.new("717"),
          protein_g: Decimal.new("0.85"),
          carbohydrates_g: Decimal.new("0.06"),
          fat_total_g: Decimal.new("81.11"),
          fat_saturated_g: Decimal.new("51.368"),
          fiber_g: Decimal.new("0"),
          sugar_g: Decimal.new("0.06")
        })

      %{user: user, flour: flour, sugar: sugar, butter: butter}
    end

    test "calculates nutrition for a simple recipe", %{user: user} do
      {:ok, recipe} =
        Recipes.create_recipe(%{
          title: "Simple Cookies",
          user_id: user.id,
          servings: "12",
          ingredients: [
            %{"text" => "2 cups all-purpose flour"},
            %{"text" => "1 cup granulated sugar"},
            %{"text" => "4 tbsp test butter"}
          ]
        })

      result = Calculator.calculate_recipe_nutrition(recipe)

      # Check structure
      assert Map.has_key?(result, :total)
      assert Map.has_key?(result, :per_serving)
      assert Map.has_key?(result, :servings)
      assert Map.has_key?(result, :completeness)
      assert Map.has_key?(result, :ingredients)
      assert Map.has_key?(result, :warnings)

      # Check servings
      assert result.servings == 12

      # Check completeness (should be 1.0 if all ingredients calculated)
      assert result.completeness == 1.0

      # Check that totals are calculated (now returned as ranges with best value)
      assert get_value(result.total.calories) > 0
      assert get_value(result.total.protein_g) > 0
      assert get_value(result.total.carbohydrates_g) > 0

      # Check per-serving values are reasonable (total / servings)
      assert_in_delta get_value(result.per_serving.calories), get_value(result.total.calories) / 12, 1.0
    end

    test "handles unmatched ingredients gracefully", %{user: user} do
      {:ok, recipe} =
        Recipes.create_recipe(%{
          title: "Recipe with Unknown",
          user_id: user.id,
          servings: "4",
          ingredients: [
            %{"text" => "2 cups all-purpose flour"},
            %{"text" => "1 cup mystery ingredient xyz"}
          ]
        })

      result = Calculator.calculate_recipe_nutrition(recipe)

      # Completeness should be less than 1
      assert result.completeness < 1.0

      # Should have warnings
      assert length(result.warnings) > 0

      # First ingredient should be calculated
      flour_result = Enum.find(result.ingredients, &String.contains?(&1.original, "flour"))
      assert flour_result.status == :calculated

      # Unknown ingredient should show error
      unknown_result = Enum.find(result.ingredients, &String.contains?(&1.original, "mystery"))
      assert unknown_result.status == :no_match
    end

    test "handles ingredients without density data", %{user: user} do
      # Create an ingredient with nutrition but no density and no category (so no fallback)
      {:ok, salt} =
        Ingredients.create_canonical_ingredient(%{
          name: "test nodensity mineral",
          display_name: "Test Nodensity Mineral"
          # No category means no category-based density fallback
        })

      {:ok, _} =
        Ingredients.create_nutrition(%{
          canonical_ingredient_id: salt.id,
          source: :usda,
          serving_size_value: Decimal.new("100"),
          serving_size_unit: "g",
          calories: Decimal.new("0"),
          protein_g: Decimal.new("0"),
          sodium_mg: Decimal.new("38758")
        })

      {:ok, recipe} =
        Recipes.create_recipe(%{
          title: "Recipe with Nodensity",
          user_id: user.id,
          servings: "4",
          ingredients: [
            %{"text" => "1 tsp test nodensity mineral"}
          ]
        })

      result = Calculator.calculate_recipe_nutrition(recipe)

      # Should have warning about missing density
      nodensity_result = Enum.find(result.ingredients, &String.contains?(&1.original, "nodensity"))
      assert nodensity_result.status == :no_density
    end

    test "handles weight units without needing density", %{user: user} do
      {:ok, recipe} =
        Recipes.create_recipe(%{
          title: "Recipe with Weight",
          user_id: user.id,
          servings: "4",
          ingredients: [
            %{"text" => "100 g test butter"}
          ]
        })

      result = Calculator.calculate_recipe_nutrition(recipe)

      # Should calculate successfully using weight conversion
      butter_result = Enum.find(result.ingredients, &String.contains?(&1.original, "butter"))
      assert butter_result.status == :calculated
      # grams is now returned as a range map
      assert get_value(butter_result.grams) == 100.0
      assert get_value(butter_result.calories) == 717.0
    end

    test "respects servings override", %{user: user} do
      {:ok, recipe} =
        Recipes.create_recipe(%{
          title: "Test Recipe",
          user_id: user.id,
          servings: "4",
          ingredients: [
            %{"text" => "1 cup granulated sugar"}
          ]
        })

      result_default = Calculator.calculate_recipe_nutrition(recipe)
      result_override = Calculator.calculate_recipe_nutrition(recipe, servings_override: 8)

      # Same total (ranges)
      assert get_value(result_default.total.calories) == get_value(result_override.total.calories)

      # Different per-serving
      assert result_override.servings == 8
      assert_in_delta get_value(result_override.per_serving.calories), get_value(result_default.per_serving.calories) / 2, 1.0
    end

    test "parses various serving formats", %{user: user} do
      test_cases = [
        {"4", 4},
        {"4 servings", 4},
        {"serves 4", 4},
        {"4-6", 4},
        {nil, 1}
      ]

      for {servings_str, expected_servings} <- test_cases do
        {:ok, recipe} =
          Recipes.create_recipe(%{
            title: "Test #{servings_str}",
            user_id: user.id,
            servings: servings_str,
            ingredients: [%{"text" => "1 cup granulated sugar"}]
          })

        result = Calculator.calculate_recipe_nutrition(recipe)
        assert result.servings == expected_servings, "Expected #{expected_servings} for '#{servings_str}', got #{result.servings}"
      end
    end
  end

  describe "calculate_ingredient_nutrition/2" do
    setup do
      {:ok, flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "test calc flour",
          display_name: "Test Calc Flour",
          category: "grain"
        })

      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: flour.id,
          volume_unit: "cup",
          grams_per_unit: Decimal.new("125"),
          source: "usda"
        })

      {:ok, _} =
        Ingredients.create_nutrition(%{
          canonical_ingredient_id: flour.id,
          source: :usda,
          serving_size_value: Decimal.new("100"),
          serving_size_unit: "g",
          calories: Decimal.new("364"),
          protein_g: Decimal.new("10.33"),
          carbohydrates_g: Decimal.new("76.31")
        })

      %{flour: flour}
    end

    test "calculates nutrition for a single ingredient text" do
      result = Calculator.calculate_ingredient_nutrition("2 cups test calc flour")

      assert result.status == :calculated
      # grams is now a Range struct
      assert result.grams.best == 250.0  # 2 cups * 125g/cup

      # Scaled from per-100g values (now returned as Range)
      # 250g / 100g * 364 cal = 910 cal
      assert_in_delta result.nutrients.calories.best, 910.0, 1.0
      assert_in_delta result.nutrients.protein_g.best, 25.825, 0.1
    end

    test "returns error status for unmatched ingredient" do
      result = Calculator.calculate_ingredient_nutrition("1 cup xyzzyplugh")

      assert result.status == :no_match
      assert result.error != nil
    end
  end

  describe "DensityConverter" do
    setup do
      {:ok, flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "test flour",
          display_name: "Test Flour",
          category: "grain"
        })

      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: flour.id,
          volume_unit: "cup",
          grams_per_unit: Decimal.new("125"),
          source: "usda"
        })

      {:ok, _} =
        Ingredients.create_density(%{
          canonical_ingredient_id: flour.id,
          volume_unit: "tbsp",
          grams_per_unit: Decimal.new("8"),
          source: "usda"
        })

      %{flour: flour}
    end

    test "converts weight units directly" do
      # Test various weight conversions
      assert {:ok, grams} = DensityConverter.to_grams(nil, 1, "oz")
      assert_in_delta grams, 28.3495, 0.01

      assert {:ok, grams} = DensityConverter.to_grams(nil, 1, "lb")
      assert_in_delta grams, 453.592, 0.01

      assert {:ok, grams} = DensityConverter.to_grams(nil, 100, "g")
      assert grams == 100.0

      assert {:ok, grams} = DensityConverter.to_grams(nil, 1, "kg")
      assert grams == 1000.0
    end

    test "converts volume using ingredient density", %{flour: flour} do
      assert {:ok, grams} = DensityConverter.to_grams(flour.id, 1, "cup")
      assert grams == 125.0

      assert {:ok, grams} = DensityConverter.to_grams(flour.id, 2, "cup")
      assert grams == 250.0

      assert {:ok, grams} = DensityConverter.to_grams(flour.id, 1, "tbsp")
      assert grams == 8.0
    end

    test "derives density from cup when specific unit not available", %{flour: flour} do
      # tsp not explicitly defined, should derive from cup density
      assert {:ok, grams} = DensityConverter.to_grams(flour.id, 1, "tsp")
      # 1 tsp = 1/48 cup, so ~125/48 = ~2.6g
      assert_in_delta grams, 125.0 / 48.0, 0.1
    end

    test "returns error for volume without density" do
      {:ok, no_density} =
        Ingredients.create_canonical_ingredient(%{
          name: "no density ingredient",
          display_name: "No Density"
        })

      assert {:error, :no_density} = DensityConverter.to_grams(no_density.id, 1, "cup")
    end

    test "uses category fallback when specified" do
      {:ok, unknown} =
        Ingredients.create_canonical_ingredient(%{
          name: "unknown grain",
          display_name: "Unknown Grain",
          category: "grain"
        })

      # Should use grain category average (~130g/cup)
      assert {:ok, grams} = DensityConverter.to_grams(unknown.id, 1, "cup", category: "grain")
      assert_in_delta grams, 130.0, 0.1
    end

    test "identifies weight units correctly" do
      assert DensityConverter.weight_unit?("g")
      assert DensityConverter.weight_unit?("gram")
      assert DensityConverter.weight_unit?("grams")
      assert DensityConverter.weight_unit?("oz")
      assert DensityConverter.weight_unit?("lb")
      assert DensityConverter.weight_unit?("kg")

      refute DensityConverter.weight_unit?("cup")
      refute DensityConverter.weight_unit?("tbsp")
      refute DensityConverter.weight_unit?("ml")
    end

    test "identifies volume units correctly" do
      assert DensityConverter.volume_unit?("cup")
      assert DensityConverter.volume_unit?("cups")
      assert DensityConverter.volume_unit?("tbsp")
      assert DensityConverter.volume_unit?("tsp")
      assert DensityConverter.volume_unit?("ml")
      assert DensityConverter.volume_unit?("liter")

      refute DensityConverter.volume_unit?("g")
      refute DensityConverter.volume_unit?("oz")
      refute DensityConverter.volume_unit?("lb")
    end

    test "handles nil and invalid inputs" do
      assert {:error, :no_quantity} = DensityConverter.to_grams("id", nil, "cup")
      # nil unit now means "count" (e.g., 3 eggs) - returns :no_count_density if no density found
      assert {:error, :no_count_density} = DensityConverter.to_grams(Ecto.UUID.generate(), 1, nil)
      assert {:error, :invalid_unit} = DensityConverter.to_grams("id", 1, "invalid_unit")
    end
  end
end
