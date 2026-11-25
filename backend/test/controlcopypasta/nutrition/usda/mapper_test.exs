defmodule Controlcopypasta.Nutrition.Usda.MapperTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.Usda.Mapper

  @fixtures Path.join([__DIR__, "../../../support/fixtures/usda"])

  defp fixture(name), do: @fixtures |> Path.join(name) |> File.read!() |> Jason.decode!()

  defp thyme, do: fixture("food_173470_thyme_fresh.json")

  describe "nutrition_attrs/1" do
    test "reads kcal and not kJ" do
      # The trap this module exists for: "Thyme, fresh" lists kJ (423) BEFORE
      # kcal (101). Taking the first Energy entry would overstate calories by
      # 4.184x.
      {:ok, attrs} = Mapper.nutrition_attrs(thyme())

      assert attrs.calories == 101.0
      refute attrs.calories == 423.0
    end

    test "records provenance for every row" do
      {:ok, attrs} = Mapper.nutrition_attrs(thyme())

      assert attrs.source == :usda
      assert attrs.source_id == "173470"
      assert attrs.source_name == "USDA FoodData Central - SR Legacy"
      assert attrs.source_url =~ "173470"
      assert attrs.serving_description == "Thyme, fresh"
    end

    test "values are per 100 g" do
      {:ok, attrs} = Mapper.nutrition_attrs(thyme())

      assert attrs.serving_size_value == 100
      assert attrs.serving_size_unit == "g"
      assert attrs.protein_g == 5.56
      assert attrs.water_g == 65.11
    end

    test "refuses a record with no calories" do
      # A nutrition row with no calories is worse than no row: the calculator
      # would report the ingredient as covered and contribute nothing.
      food = %{"fdcId" => 1, "description" => "x", "foodNutrients" => []}

      assert {:error, :no_calories} = Mapper.nutrition_attrs(food)
    end

    test "skips a nutrient reported in an unexpected unit" do
      # Rather than rescale it and risk being wrong by 1000x.
      food = %{
        "fdcId" => 1,
        "description" => "x",
        "foodNutrients" => [
          %{"nutrient" => %{"id" => 1008, "unitName" => "kcal"}, "amount" => 50.0},
          %{"nutrient" => %{"id" => 1093, "unitName" => "g"}, "amount" => 2.0}
        ]
      }

      {:ok, attrs} = Mapper.nutrition_attrs(food)

      assert attrs.calories == 50.0
      refute Map.has_key?(attrs, :sodium_mg)
    end

    test "accepts micrograms however they are spelled" do
      for spelling <- ["UG", "ug", "µg", "mcg"] do
        food = %{
          "fdcId" => 1,
          "description" => "x",
          "foodNutrients" => [
            %{"nutrient" => %{"id" => 1008, "unitName" => "kcal"}, "amount" => 1.0},
            %{"nutrient" => %{"id" => 1177, "unitName" => spelling}, "amount" => 45.0}
          ]
        }

        {:ok, attrs} = Mapper.nutrition_attrs(food)
        assert attrs.folate_mcg == 45.0, spelling
      end
    end
  end

  describe "portions/1" do
    test "derives grams per single unit from the stated amount" do
      # The fixture says 0.5 tsp weighs 0.4 g, so a tsp is 0.8 g. Reading
      # gramWeight directly would halve it.
      portions = Mapper.portions(thyme())
      tsp = Enum.find(portions, &(&1.unit == "tsp"))

      assert tsp
      assert_in_delta tsp.grams_per_unit, 0.8, 0.001
    end

    test "drops a portion with no usable amount" do
      food = %{
        "foodPortions" => [
          %{"amount" => 0, "gramWeight" => 5.0, "modifier" => "sprig"},
          %{"gramWeight" => 5.0, "modifier" => "sprig"},
          %{"amount" => 1.0, "gramWeight" => 5.0, "modifier" => ""}
        ]
      }

      assert Mapper.portions(food) == []
    end

    test "prefers a structured measure unit over the modifier" do
      food = %{
        "foodPortions" => [
          %{
            "amount" => 1.0,
            "gramWeight" => 20.0,
            "modifier" => "whatever",
            "measureUnit" => %{"name" => "cup"}
          }
        ]
      }

      assert [%{unit: "cup", grams_per_unit: 20.0}] = Mapper.portions(food)
    end

    test "ignores the undetermined placeholder measure unit" do
      # Most SR Legacy rows carry measureUnit "undetermined" with the real unit
      # in the modifier.
      food = %{
        "foodPortions" => [
          %{
            "amount" => 1.0,
            "gramWeight" => 3.0,
            "modifier" => "sprig",
            "measureUnit" => %{"name" => "undetermined"}
          }
        ]
      }

      assert [%{unit: "sprig", grams_per_unit: 3.0}] = Mapper.portions(food)
    end
  end
end
