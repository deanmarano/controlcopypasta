defmodule Controlcopypasta.IngredientsTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.{CanonicalIngredient, Preparation, IngredientForm}

  describe "canonical_ingredients" do
    @valid_attrs %{
      name: "chicken breast",
      display_name: "Chicken Breast",
      category: "protein",
      subcategory: "poultry",
      tags: ["meat", "poultry", "chicken"],
      is_allergen: false,
      dietary_flags: ["gluten_free", "keto"]
    }

    @invalid_attrs %{name: nil, display_name: nil}

    test "list_canonical_ingredients/0 returns all canonical ingredients" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)
      ingredients = Ingredients.list_canonical_ingredients()
      assert Enum.any?(ingredients, fn i -> i.id == ingredient.id end)
    end

    test "list_canonical_ingredients/1 filters by category" do
      {:ok, chicken} = Ingredients.create_canonical_ingredient(@valid_attrs)

      {:ok, _flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "flour",
          display_name: "Flour",
          category: "grain"
        })

      results = Ingredients.list_canonical_ingredients(category: "protein")
      assert Enum.any?(results, fn i -> i.id == chicken.id end)
      refute Enum.any?(results, fn i -> i.category == "grain" end)
    end

    test "list_canonical_ingredients/1 filters by tag" do
      {:ok, chicken} = Ingredients.create_canonical_ingredient(@valid_attrs)

      {:ok, _flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "flour",
          display_name: "Flour",
          tags: ["baking"]
        })

      results = Ingredients.list_canonical_ingredients(tag: "poultry")
      assert Enum.any?(results, fn i -> i.id == chicken.id end)
      assert length(results) == 1
    end

    test "list_canonical_ingredients/1 filters by is_allergen" do
      {:ok, milk} =
        Ingredients.create_canonical_ingredient(%{
          name: "milk",
          display_name: "Milk",
          is_allergen: true,
          allergen_groups: ["dairy"]
        })

      {:ok, _chicken} = Ingredients.create_canonical_ingredient(@valid_attrs)

      results = Ingredients.list_canonical_ingredients(is_allergen: true)
      assert Enum.any?(results, fn i -> i.id == milk.id end)
      refute Enum.any?(results, fn i -> i.name == "chicken breast" end)
    end

    test "list_canonical_ingredients/1 filters by allergen_group" do
      {:ok, milk} =
        Ingredients.create_canonical_ingredient(%{
          name: "milk",
          display_name: "Milk",
          is_allergen: true,
          allergen_groups: ["dairy"]
        })

      {:ok, _peanut} =
        Ingredients.create_canonical_ingredient(%{
          name: "peanut",
          display_name: "Peanut",
          is_allergen: true,
          allergen_groups: ["peanuts"]
        })

      results = Ingredients.list_canonical_ingredients(allergen_group: "dairy")
      assert length(results) == 1
      assert hd(results).id == milk.id
    end

    test "list_canonical_ingredients/1 filters by dietary_flag" do
      {:ok, chicken} = Ingredients.create_canonical_ingredient(@valid_attrs)

      {:ok, _milk} =
        Ingredients.create_canonical_ingredient(%{
          name: "milk",
          display_name: "Milk",
          dietary_flags: ["vegetarian"]
        })

      results = Ingredients.list_canonical_ingredients(dietary_flag: "keto")
      assert Enum.any?(results, fn i -> i.id == chicken.id end)
    end

    test "list_canonical_ingredients/1 searches by name" do
      {:ok, chicken} = Ingredients.create_canonical_ingredient(@valid_attrs)

      {:ok, _flour} =
        Ingredients.create_canonical_ingredient(%{
          name: "flour",
          display_name: "Flour"
        })

      results = Ingredients.list_canonical_ingredients(search: "chicken")
      assert Enum.any?(results, fn i -> i.id == chicken.id end)
      refute Enum.any?(results, fn i -> i.name == "flour" end)
    end

    test "get_canonical_ingredient/1 returns the ingredient with given id" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)
      assert Ingredients.get_canonical_ingredient(ingredient.id).id == ingredient.id
    end

    test "get_canonical_ingredient_by_name/1 returns ingredient by name" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)
      assert Ingredients.get_canonical_ingredient_by_name("chicken breast").id == ingredient.id
      assert Ingredients.get_canonical_ingredient_by_name("CHICKEN BREAST").id == ingredient.id
    end

    test "find_canonical_ingredient/1 finds by exact name" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)
      assert {:ok, found} = Ingredients.find_canonical_ingredient("chicken breast")
      assert found.id == ingredient.id
    end

    test "find_canonical_ingredient/1 finds by alias" do
      {:ok, ingredient} =
        Ingredients.create_canonical_ingredient(
          Map.put(@valid_attrs, :aliases, ["boneless skinless chicken breast", "bscb"])
        )

      assert {:ok, found} = Ingredients.find_canonical_ingredient("boneless skinless chicken breast")
      assert found.id == ingredient.id
    end

    test "find_canonical_ingredient/1 returns error for unknown ingredient" do
      assert {:error, :not_found} = Ingredients.find_canonical_ingredient("unknown ingredient")
    end

    test "create_canonical_ingredient/1 with valid data creates an ingredient" do
      assert {:ok, %CanonicalIngredient{} = ingredient} =
               Ingredients.create_canonical_ingredient(@valid_attrs)

      assert ingredient.name == "chicken breast"
      assert ingredient.display_name == "Chicken Breast"
      assert ingredient.category == "protein"
      assert ingredient.tags == ["meat", "poultry", "chicken"]
    end

    test "create_canonical_ingredient/1 normalizes name to lowercase" do
      attrs = Map.put(@valid_attrs, :name, "CHICKEN BREAST")
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(attrs)
      assert ingredient.name == "chicken breast"
    end

    test "create_canonical_ingredient/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Ingredients.create_canonical_ingredient(@invalid_attrs)
    end

    test "create_canonical_ingredient/1 enforces unique name" do
      {:ok, _ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Ingredients.create_canonical_ingredient(@valid_attrs)

      assert {:name, _} = List.keyfind(errors, :name, 0)
    end

    test "create_canonical_ingredient/1 validates category" do
      attrs = Map.put(@valid_attrs, :category, "invalid_category")
      assert {:error, %Ecto.Changeset{errors: errors}} = Ingredients.create_canonical_ingredient(attrs)
      assert {:category, _} = List.keyfind(errors, :category, 0)
    end

    test "create_canonical_ingredient/1 validates allergen_groups" do
      attrs = Map.put(@valid_attrs, :allergen_groups, ["invalid_group"])

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Ingredients.create_canonical_ingredient(attrs)

      assert {:allergen_groups, _} = List.keyfind(errors, :allergen_groups, 0)
    end

    test "create_canonical_ingredient/1 validates dietary_flags" do
      attrs = Map.put(@valid_attrs, :dietary_flags, ["invalid_flag"])

      assert {:error, %Ecto.Changeset{errors: errors}} =
               Ingredients.create_canonical_ingredient(attrs)

      assert {:dietary_flags, _} = List.keyfind(errors, :dietary_flags, 0)
    end

    test "update_canonical_ingredient/2 with valid data updates the ingredient" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)

      update_attrs = %{
        display_name: "Boneless Chicken Breast",
        tags: ["meat", "poultry", "chicken", "white meat"]
      }

      assert {:ok, %CanonicalIngredient{} = updated} =
               Ingredients.update_canonical_ingredient(ingredient, update_attrs)

      assert updated.display_name == "Boneless Chicken Breast"
      assert updated.tags == ["meat", "poultry", "chicken", "white meat"]
    end

    test "delete_canonical_ingredient/1 deletes the ingredient" do
      {:ok, ingredient} = Ingredients.create_canonical_ingredient(@valid_attrs)
      assert {:ok, %CanonicalIngredient{}} = Ingredients.delete_canonical_ingredient(ingredient)
      assert Ingredients.get_canonical_ingredient(ingredient.id) == nil
    end
  end

  describe "preparations" do
    @valid_attrs %{
      name: "test-brunoise",
      display_name: "Test Brunoise",
      category: "cut",
      aliases: ["test-fine-dice", "test-small-cube"]
    }

    test "list_preparations/0 returns all preparations" do
      {:ok, preparation} = Ingredients.create_preparation(@valid_attrs)
      preparations = Ingredients.list_preparations()
      assert Enum.any?(preparations, fn p -> p.id == preparation.id end)
    end

    test "list_preparations_by_category/1 filters by category" do
      {:ok, brunoise} = Ingredients.create_preparation(@valid_attrs)

      {:ok, _tempering} =
        Ingredients.create_preparation(%{
          name: "test-tempered",
          display_name: "Test Tempered",
          category: "temperature"
        })

      results = Ingredients.list_preparations_by_category("cut")
      assert Enum.any?(results, fn p -> p.id == brunoise.id end)
    end

    test "get_preparation_by_name/1 returns preparation by name" do
      {:ok, preparation} = Ingredients.create_preparation(@valid_attrs)
      assert Ingredients.get_preparation_by_name("test-brunoise").id == preparation.id
    end

    test "find_preparation/1 finds by name" do
      {:ok, preparation} = Ingredients.create_preparation(@valid_attrs)
      assert {:ok, found} = Ingredients.find_preparation("test-brunoise")
      assert found.id == preparation.id
    end

    test "find_preparation/1 finds by alias" do
      {:ok, preparation} = Ingredients.create_preparation(@valid_attrs)
      assert {:ok, found} = Ingredients.find_preparation("test-fine-dice")
      assert found.id == preparation.id
    end

    test "create_preparation/1 with valid data creates a preparation" do
      assert {:ok, %Preparation{} = preparation} = Ingredients.create_preparation(@valid_attrs)
      assert preparation.name == "test-brunoise"
      assert preparation.display_name == "Test Brunoise"
      assert preparation.category == "cut"
      assert preparation.aliases == ["test-fine-dice", "test-small-cube"]
    end

    test "create_preparation/1 validates category" do
      attrs = Map.put(@valid_attrs, :category, "invalid")
      assert {:error, %Ecto.Changeset{errors: errors}} = Ingredients.create_preparation(attrs)
      assert {:category, _} = List.keyfind(errors, :category, 0)
    end
  end

  describe "ingredient_forms" do
    setup do
      {:ok, ingredient} =
        Ingredients.create_canonical_ingredient(%{
          name: "tomato",
          display_name: "Tomato",
          category: "produce"
        })

      %{ingredient: ingredient}
    end

    test "list_forms_for_ingredient/1 returns forms for an ingredient", %{ingredient: ingredient} do
      {:ok, form} =
        Ingredients.create_ingredient_form(%{
          canonical_ingredient_id: ingredient.id,
          form_name: "canned",
          default_unit: "can",
          default_size_value: Decimal.new("14.5"),
          default_size_unit: "oz"
        })

      forms = Ingredients.list_forms_for_ingredient(ingredient.id)
      assert length(forms) == 1
      assert hd(forms).id == form.id
    end

    test "get_ingredient_form/2 returns form by ingredient and form name", %{ingredient: ingredient} do
      {:ok, form} =
        Ingredients.create_ingredient_form(%{
          canonical_ingredient_id: ingredient.id,
          form_name: "canned",
          default_unit: "can"
        })

      found = Ingredients.get_ingredient_form(ingredient.id, "canned")
      assert found.id == form.id
    end

    test "create_ingredient_form/1 with valid data creates a form", %{ingredient: ingredient} do
      attrs = %{
        canonical_ingredient_id: ingredient.id,
        form_name: "canned",
        default_unit: "can",
        default_size_value: Decimal.new("14.5"),
        default_size_unit: "oz"
      }

      assert {:ok, %IngredientForm{} = form} = Ingredients.create_ingredient_form(attrs)
      assert form.form_name == "canned"
      assert form.default_unit == "can"
      assert Decimal.equal?(form.default_size_value, Decimal.new("14.5"))
    end

    test "create_ingredient_form/1 enforces unique constraint", %{ingredient: ingredient} do
      attrs = %{
        canonical_ingredient_id: ingredient.id,
        form_name: "canned",
        default_unit: "can"
      }

      {:ok, _form} = Ingredients.create_ingredient_form(attrs)

      assert {:error, %Ecto.Changeset{}} = Ingredients.create_ingredient_form(attrs)
    end
  end

  describe "lookup functions" do
    test "build_ingredient_lookup/0 builds a lookup map with tuples" do
      {:ok, chicken} =
        Ingredients.create_canonical_ingredient(%{
          name: "chicken",
          display_name: "Chicken",
          aliases: ["poultry"]
        })

      lookup = Ingredients.build_ingredient_lookup()

      # Should map both name and alias to {canonical_name, id}
      assert Map.has_key?(lookup, "chicken")
      assert Map.has_key?(lookup, "poultry")

      # Both should return the canonical name and ID
      assert lookup["chicken"] == {"chicken", chicken.id}
      assert lookup["poultry"] == {"chicken", chicken.id}
    end

    test "build_preparation_lookup/0 builds a lookup map with tuples" do
      {:ok, test_prep} =
        Ingredients.create_preparation(%{
          name: "test-brunoise",
          display_name: "Test Brunoise",
          verb: "brunoise",
          category: "cut",
          aliases: ["test-fine-dice"]
        })

      lookup = Ingredients.build_preparation_lookup()

      assert Map.has_key?(lookup, "test-brunoise")
      assert Map.has_key?(lookup, "test-fine-dice")

      # Both should return the canonical name, ID, and metadata
      {name, id, _meta} = lookup["test-brunoise"]
      assert name == "test-brunoise"
      assert id == test_prep.id

      {alias_name, alias_id, _meta} = lookup["test-fine-dice"]
      assert alias_name == "test-brunoise"
      assert alias_id == test_prep.id
    end

    test "get_allergen_ingredients/1 returns allergen ingredient names" do
      {:ok, _milk} =
        Ingredients.create_canonical_ingredient(%{
          name: "milk",
          display_name: "Milk",
          is_allergen: true,
          allergen_groups: ["dairy"]
        })

      {:ok, _peanut} =
        Ingredients.create_canonical_ingredient(%{
          name: "peanut",
          display_name: "Peanut",
          is_allergen: true,
          allergen_groups: ["peanuts"]
        })

      dairy_ingredients = Ingredients.get_allergen_ingredients(["dairy"])
      assert "milk" in dairy_ingredients
      refute "peanut" in dairy_ingredients
    end

    test "find_related_by_tags/1 finds related ingredients" do
      {:ok, chicken_breast} =
        Ingredients.create_canonical_ingredient(%{
          name: "chicken breast",
          display_name: "Chicken Breast",
          tags: ["meat", "poultry", "chicken"]
        })

      {:ok, _chicken_thigh} =
        Ingredients.create_canonical_ingredient(%{
          name: "chicken thigh",
          display_name: "Chicken Thigh",
          tags: ["meat", "poultry", "chicken"]
        })

      {:ok, _beef} =
        Ingredients.create_canonical_ingredient(%{
          name: "beef",
          display_name: "Beef",
          tags: ["meat", "red meat"]
        })

      related = Ingredients.find_related_by_tags(chicken_breast)
      related_names = Enum.map(related, & &1.name)

      # chicken thigh shares more tags
      assert "chicken thigh" in related_names
      # beef shares "meat" tag
      assert "beef" in related_names
    end
  end

  describe "bulk_insert_canonical_ingredients/1" do
    test "inserts multiple ingredients" do
      ingredients = [
        %{name: "flour", display_name: "Flour", category: "grain"},
        %{name: "sugar", display_name: "Sugar", category: "sweetener"},
        %{name: "salt", display_name: "Salt", category: "spice"}
      ]

      {count, _} = Ingredients.bulk_insert_canonical_ingredients(ingredients)
      assert count == 3

      assert Ingredients.get_canonical_ingredient_by_name("flour")
      assert Ingredients.get_canonical_ingredient_by_name("sugar")
      assert Ingredients.get_canonical_ingredient_by_name("salt")
    end

    test "handles conflicts gracefully" do
      {:ok, _existing} =
        Ingredients.create_canonical_ingredient(%{
          name: "flour",
          display_name: "Flour"
        })

      ingredients = [
        %{name: "flour", display_name: "All-Purpose Flour"},
        %{name: "sugar", display_name: "Sugar"}
      ]

      # Should not raise, should skip conflict
      {_count, _} = Ingredients.bulk_insert_canonical_ingredients(ingredients)

      # Original flour should be unchanged
      flour = Ingredients.get_canonical_ingredient_by_name("flour")
      assert flour.display_name == "Flour"

      # Sugar should be inserted
      assert Ingredients.get_canonical_ingredient_by_name("sugar")
    end
  end
end
