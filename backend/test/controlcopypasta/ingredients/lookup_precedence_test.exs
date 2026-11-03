defmodule Controlcopypasta.Ingredients.LookupPrecedenceTest do
  use Controlcopypasta.DataCase

  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.CanonicalIngredient
  alias Controlcopypasta.Repo

  # The real catalog has 158 keys claimed more than once. These three rows
  # reproduce the two harmful shapes: "coriander" is the spice's own name and
  # also an alias of cilantro, and "chinese cabbage" is claimed as an alias by
  # two different ingredients.
  setup do
    Repo.delete_all(CanonicalIngredient)

    for attrs <- [
          %{name: "coriander", display_name: "Coriander", aliases: ["coriander seeds"]},
          %{name: "cilantro", display_name: "Cilantro", aliases: ["coriander", "fresh cilantro"]},
          %{name: "napa cabbage", display_name: "Napa Cabbage", aliases: ["chinese cabbage"]},
          %{name: "bok choy", display_name: "Bok Choy", aliases: ["chinese cabbage", "pak choi"]}
        ] do
      %CanonicalIngredient{}
      |> CanonicalIngredient.changeset(attrs)
      |> Repo.insert!()
    end

    :ok
  end

  describe "build_ingredient_lookup/0" do
    test "a canonical ingredient's own name beats another ingredient's alias" do
      lookup = Ingredients.build_ingredient_lookup()

      assert {"coriander", _id} = Map.fetch!(lookup, "coriander"),
             "the spice owns the name 'coriander'; cilantro only aliases it"

      # The alias is still reachable on its own key.
      assert {"cilantro", _} = Map.fetch!(lookup, "fresh cilantro")
    end

    test "two aliases claiming one key resolve to the alphabetically first canonical" do
      lookup = Ingredients.build_ingredient_lookup()

      assert {"bok choy", _} = Map.fetch!(lookup, "chinese cabbage")
    end

    test "resolution does not depend on row order" do
      first = Ingredients.build_ingredient_lookup()

      # Updating rows changes their physical order in Postgres, which is what
      # last-writer-wins over an unordered query was sensitive to.
      Repo.update_all(CanonicalIngredient, set: [usage_count: 7])

      assert Ingredients.build_ingredient_lookup() == first
    end

    test "the rules variant applies the same precedence" do
      plain = Ingredients.build_ingredient_lookup()
      with_rules = Ingredients.build_ingredient_lookup_with_rules()

      assert map_size(with_rules) == map_size(plain)

      for key <- ["coriander", "chinese cabbage"] do
        {plain_name, _} = Map.fetch!(plain, key)
        {rules_name, _, _} = Map.fetch!(with_rules, key)
        assert plain_name == rules_name
      end
    end
  end
end
