defmodule Controlcopypasta.Ingredients.PreStepGeneratorTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.PreStepGenerator
  alias Controlcopypasta.Ingredients.PreStepGenerator.PreStep
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  describe "generate_pre_steps/1" do
    test "generates pre-steps from preparations" do
      parsed = %ParsedIngredient{
        original: "2 cups carrots, peeled and diced",
        quantity: 2.0,
        unit: "cup",
        preparations: ["peeled", "diced"],
        primary_ingredient: %{
          name: "carrots",
          canonical_name: "carrot",
          canonical_id: "123",
          confidence: 1.0
        }
      }

      steps = PreStepGenerator.generate_pre_steps(parsed)

      assert length(steps) == 2

      # Steps should be ordered: process (peel) before cut (dice)
      [first, second] = steps
      assert first.action == "peel"
      assert first.category == :process
      assert first.target == "carrot"

      assert second.action == "dice"
      assert second.category == :cut
      assert second.target == "carrot"
    end

    test "assigns order hints based on category" do
      parsed = %ParsedIngredient{
        original: "1 lb butter, softened and cubed",
        quantity: 1.0,
        unit: "lb",
        preparations: ["cubed", "softened"],
        primary_ingredient: %{
          name: "butter",
          canonical_name: "butter",
          canonical_id: "456",
          confidence: 1.0
        }
      }

      steps = PreStepGenerator.generate_pre_steps(parsed)

      # Temperature (softened) should come before cut (cubed)
      [first, second] = steps
      assert first.action == "soften"
      assert first.category == :temperature
      assert first.order_hint == 1

      assert second.action == "cube"
      assert second.category == :cut
      assert second.order_hint == 2
    end

    test "estimates time based on quantity and unit" do
      parsed = %ParsedIngredient{
        original: "4 cups onions, diced",
        quantity: 4.0,
        unit: "cup",
        preparations: ["diced"],
        primary_ingredient: %{
          name: "onions",
          canonical_name: "onion",
          canonical_id: "789",
          confidence: 1.0
        }
      }

      [step] = PreStepGenerator.generate_pre_steps(parsed)

      # diced has time_per_cup: 2, so 4 cups = 8 minutes
      assert step.estimated_time_min == 8
    end

    test "includes tool when specified" do
      parsed = %ParsedIngredient{
        original: "1 cup cheese, grated",
        quantity: 1.0,
        unit: "cup",
        preparations: ["grated"],
        primary_ingredient: %{
          name: "cheese",
          canonical_name: "cheese",
          canonical_id: "abc",
          confidence: 1.0
        }
      }

      [step] = PreStepGenerator.generate_pre_steps(parsed)

      assert step.tool == "grater"
    end

    test "handles temperature preparations with fixed time" do
      parsed = %ParsedIngredient{
        original: "2 eggs, room temperature",
        quantity: 2.0,
        unit: nil,
        preparations: ["room temperature"],
        primary_ingredient: %{
          name: "eggs",
          canonical_name: "egg",
          canonical_id: "def",
          confidence: 1.0
        }
      }

      [step] = PreStepGenerator.generate_pre_steps(parsed)

      assert step.action == "bring to room temperature"
      assert step.category == :temperature
      assert step.estimated_time_min == 30
    end

    test "handles unknown preparations" do
      parsed = %ParsedIngredient{
        original: "1 cup weird ingredient, flambéed",
        quantity: 1.0,
        unit: "cup",
        preparations: ["flambéed"],
        primary_ingredient: %{
          name: "weird ingredient",
          canonical_name: nil,
          canonical_id: nil,
          confidence: 0.5
        }
      }

      [step] = PreStepGenerator.generate_pre_steps(parsed)

      assert step.action == "flambéed"
      assert step.category == :other
      assert step.estimated_time_min == nil
    end

    test "returns empty list when no preparations" do
      parsed = %ParsedIngredient{
        original: "1 cup flour",
        quantity: 1.0,
        unit: "cup",
        preparations: [],
        primary_ingredient: %{
          name: "flour",
          canonical_name: "flour",
          canonical_id: "ghi",
          confidence: 1.0
        }
      }

      assert PreStepGenerator.generate_pre_steps(parsed) == []
    end

    test "returns empty list for nil input" do
      assert PreStepGenerator.generate_pre_steps(nil) == []
    end
  end

  describe "to_map/1" do
    test "converts PreStep to JSONB-compatible map" do
      step = %PreStep{
        action: "dice",
        target: "carrots",
        quantity: 2.0,
        unit: "cup",
        category: :cut,
        estimated_time_min: 4,
        tool: "knife",
        order_hint: 1,
        original_prep: "diced"
      }

      map = PreStepGenerator.to_map(step)

      assert map == %{
               "action" => "dice",
               "target" => "carrots",
               "quantity" => 2.0,
               "unit" => "cup",
               "category" => "cut",
               "estimated_time_min" => 4,
               "tool" => "knife",
               "order_hint" => 1
             }
    end

    test "omits nil values from map" do
      step = %PreStep{
        action: "soften",
        target: "butter",
        quantity: nil,
        unit: nil,
        category: :temperature,
        estimated_time_min: 30,
        tool: nil,
        order_hint: 1,
        original_prep: "softened"
      }

      map = PreStepGenerator.to_map(step)

      refute Map.has_key?(map, "quantity")
      refute Map.has_key?(map, "unit")
      refute Map.has_key?(map, "tool")
    end
  end

  describe "known_preparation?/1" do
    test "returns true for known preparations" do
      assert PreStepGenerator.known_preparation?("diced")
      assert PreStepGenerator.known_preparation?("Minced")
      assert PreStepGenerator.known_preparation?("CHOPPED")
      assert PreStepGenerator.known_preparation?("room temperature")
    end

    test "returns false for unknown preparations" do
      refute PreStepGenerator.known_preparation?("flambéed")
      refute PreStepGenerator.known_preparation?("unknown")
    end
  end
end
