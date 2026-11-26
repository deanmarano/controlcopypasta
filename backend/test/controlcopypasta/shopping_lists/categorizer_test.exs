defmodule Controlcopypasta.ShoppingLists.CategorizerTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.ShoppingLists.Categorizer

  test "sorts everyday ingredients into their aisle" do
    assert Categorizer.categorize("kale") == "produce"
    assert Categorizer.categorize("sweet potatoes") == "produce"
    assert Categorizer.categorize("hard boiled eggs") == "protein"
    assert Categorizer.categorize("heavy cream") == "dairy"
    assert Categorizer.categorize("tortillas") == "bakery"
    assert Categorizer.categorize("dried thyme") == "spices"
    assert Categorizer.categorize("soy sauce") == "condiments"
    assert Categorizer.categorize("water") == "beverages"
    assert Categorizer.categorize("quinoa") == "pantry"
  end

  test "matches whole words, not fragments of other words" do
    # "ground" used to mean ground meat, "egg" matched eggplant, "corn" matched cornstarch
    assert Categorizer.categorize("stone ground mustard") == "condiments"
    assert Categorizer.categorize("eggplant") == "produce"
    assert Categorizer.categorize("cornstarch") == "pantry"
    assert Categorizer.categorize("graham crackers") == "pantry"
    assert Categorizer.categorize("chickpeas") == "pantry"
  end

  test "a longer phrase beats a single word inside it" do
    assert Categorizer.categorize("olive oil and salt") == "condiments"
    assert Categorizer.categorize("peanut butter") == "pantry"
    assert Categorizer.categorize("coconut milk") == "pantry"
    assert Categorizer.categorize("tomato paste") == "pantry"
    assert Categorizer.categorize("garlic powder") == "spices"
    assert Categorizer.categorize("chicken broth") == "pantry"
    assert Categorizer.categorize("ice cream") == "frozen"
  end

  test "handles plurals, capitals and punctuation" do
    assert Categorizer.categorize("Avocados") == "produce"
    assert Categorizer.categorize("2 Lemons, juiced") == "produce"
    assert Categorizer.categorize("salt & pepper") == "spices"
  end

  test "falls back sensibly" do
    assert Categorizer.categorize(nil) == "other"
    assert Categorizer.categorize("") == "pantry"
  end
end
