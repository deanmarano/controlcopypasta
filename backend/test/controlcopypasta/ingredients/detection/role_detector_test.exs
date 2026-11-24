defmodule Controlcopypasta.Ingredients.Detection.RoleDetectorTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Detection.RoleDetector

  # Every line in this file is a real stored ingredient, or a real stored
  # phrasing with the ingredient shortened. The marker frequencies they were
  # drawn from are in parser-v3/ingredient-roles.md; inventing plausible-looking
  # phrasings instead would test the regexes against themselves.

  describe "serving and garnish" do
    test "for serving, the most common marker by an order of magnitude" do
      assert %{role: :serving, optional: false} =
               RoleDetector.detect("Flaky sea salt, for serving")

      assert %{role: :serving} = RoleDetector.detect("Lime wedges (for serving)")
      assert %{role: :serving} = RoleDetector.detect("warm corn tortillas, for serving")
    end

    test "for drizzling, sprinkling, dusting, dipping, topping" do
      assert %{role: :serving} = RoleDetector.detect("Olive oil, for drizzling")
      assert %{role: :serving} = RoleDetector.detect("Flaky salt, for sprinkling")
      assert %{role: :serving} = RoleDetector.detect("Confectioners' sugar, for dusting")
      assert %{role: :serving} = RoleDetector.detect("Ranch dressing, for dipping")
      assert %{role: :serving} = RoleDetector.detect("Sour cream, for topping")
    end

    test "to serve and to top, the British phrasings" do
      assert %{role: :serving} = RoleDetector.detect("crusty bread, to serve")
      assert %{role: :serving} = RoleDetector.detect("extra chilli oil to top")
    end

    test "garnish is separated from serving" do
      assert %{role: :garnish} = RoleDetector.detect("Chopped parsley, for garnish")
      assert %{role: :garnish} = RoleDetector.detect("cilantro leaves, to garnish")
      assert %{role: :garnish} = RoleDetector.detect("mint sprigs, for garnishing")
      assert %{role: :garnish} = RoleDetector.detect("lemon slices, as a garnish")
    end

    test "a leading label counts, even though only a handful of lines use it" do
      assert %{role: :garnish} =
               RoleDetector.detect("Garnish: fresh Italian parsley and pecorino")
    end
  end

  describe "to taste" do
    test "to taste and its relatives" do
      assert %{role: :to_taste} = RoleDetector.detect("Kosher salt, to taste")
      assert %{role: :to_taste} = RoleDetector.detect("Freshly ground pepper to taste")
      assert %{role: :to_taste} = RoleDetector.detect("Water, as needed")
    end
  end

  describe "cooking medium" do
    test "fats that oil the pan rather than feed anyone" do
      assert %{role: :cooking_medium} = RoleDetector.detect("Vegetable oil, for frying")
      assert %{role: :cooking_medium} = RoleDetector.detect("Peanut oil, for deep-frying")
      assert %{role: :cooking_medium} = RoleDetector.detect("butter, for greasing")
      assert %{role: :cooking_medium} = RoleDetector.detect("Flour, for coating")
      assert %{role: :cooking_medium} = RoleDetector.detect("melted butter, for brushing")
    end

    test "cooking medium wins over serving when a line reads both ways" do
      # "for brushing" and "for drizzling" are the same shape but not the same
      # thing. This precedence is the reason the cond is ordered as it is.
      assert %{role: :cooking_medium} =
               RoleDetector.detect("Oil, for brushing and for serving alongside")
    end
  end

  describe "cooking medium named by vessel" do
    test "for the pan, surface, grill, bowl" do
      # The other half of cooking medium names the vessel, not the verb. The
      # verb patterns missed ~10,000 stored rows of this shape.
      assert %{role: :cooking_medium} =
               RoleDetector.detect("Nonstick vegetable oil spray (for pan)")

      assert %{role: :cooking_medium} = RoleDetector.detect("All-purpose flour (for surface)")
      assert %{role: :cooking_medium} = RoleDetector.detect("Vegetable oil (for grill)")
      assert %{role: :cooking_medium} = RoleDetector.detect("Butter, softened, for the pan")
      assert %{role: :cooking_medium} = RoleDetector.detect("Rice flour (for work surface)")
    end

    test "the vessel list does not generalise to for-the-anything" do
      # "for the pan" is a vessel; "for the sauce" is a component of the dish.
      # The noun list is closed on purpose.
      assert %{role: :ingredient} = RoleDetector.detect("1 cup cream, for the sauce")
      assert %{role: :ingredient} = RoleDetector.detect("2 eggs, for the filling")
    end
  end

  describe "bare seasoning lines" do
    test "an unquantified seasoning is to-taste without saying so" do
      # "Kosher salt" alone is 16,368 stored rows and "Freshly ground pepper"
      # another 16,248. Both mean season to taste.
      assert %{role: :to_taste} = RoleDetector.detect("Kosher salt")
      assert %{role: :to_taste} = RoleDetector.detect("Freshly ground pepper")
      assert %{role: :to_taste} = RoleDetector.detect("Flaky sea salt")
      assert %{role: :to_taste} = RoleDetector.detect("Kosher salt, freshly ground pepper")
      assert %{role: :to_taste} = RoleDetector.detect("Coarsely ground black pepper")
    end

    test "a measured seasoning is left alone" do
      # The no-digits rule. In the corpus this split is absolute: the bare
      # forms never carry a number and the measured forms always do.
      assert %{role: :ingredient} = RoleDetector.detect("1 tsp. freshly ground pepper")
      assert %{role: :ingredient} = RoleDetector.detect("2 teaspoons kosher salt")
      assert %{role: :ingredient} = RoleDetector.detect("½ tsp. Morton kosher salt")
    end

    test "a seasoning that is part of a longer line is not a bare seasoning" do
      refute RoleDetector.bare_seasoning?("chicken thighs, salt and pepper")
      refute RoleDetector.bare_seasoning?("salted butter")
      refute RoleDetector.bare_seasoning?("salt-cured anchovies")
    end

    test "an explicit purpose beats the bare-seasoning convention" do
      # Checked last for exactly this reason.
      assert %{role: :serving} = RoleDetector.detect("Flaky sea salt, for serving")
      assert %{role: :garnish} = RoleDetector.detect("Flaky sea salt, for garnish")
    end
  end

  describe "top-up clauses" do
    test "plus-more describes the top-up, not the line" do
      # "2 cups flour, plus more for surface" is two cups of flour you bake
      # with, not a dusting agent. These were 18,080 rows labelled :serving and
      # 5,665 labelled :cooking_medium.
      assert %{role: :ingredient} =
               RoleDetector.detect("2 cups buckwheat flour, plus more for surface")

      assert %{role: :ingredient} = RoleDetector.detect("1 cup sugar, plus more for serving")

      assert %{role: :ingredient} =
               RoleDetector.detect(
                 "1 cup (2 sticks) unsalted butter, room temperature, plus more for pan"
               )
    end

    test "the bare more-for spelling counts too" do
      assert %{role: :ingredient} =
               RoleDetector.detect(
                 "12 tablespoons unsalted butter, softened, more for greasing pan"
               )
    end

    test "or-more quantities are not top-up clauses" do
      # "or more water" is a quantity range, not a purpose clause. The bare
      # spelling requires a following for/to precisely to leave these alone.
      assert %{role: :cooking_medium} = RoleDetector.detect("1 cup or more oil, for frying")
    end

    test "a purpose before the top-up still counts" do
      assert %{role: :serving} =
               RoleDetector.detect("Hot sauce, for serving, plus more for the table")
    end

    test "optionality still reads the whole line" do
      # The top-up tail is removed for role detection only: "(optional)" can
      # legitimately sit after a top-up clause.
      assert %{optional: true} =
               RoleDetector.detect("1/2 cup nuts, plus more for serving (optional)")
    end
  end

  describe "optional" do
    test "parenthesised, trailing, and leading forms" do
      assert %{optional: true, role: :ingredient} =
               RoleDetector.detect("1 tsp cayenne (optional)")

      assert %{optional: true} = RoleDetector.detect("2 tbsp sundried tomatoes, optional")
      assert %{optional: true} = RoleDetector.detect("optional: 1 ounce feta, crumbled")
    end

    test "the if-family is deliberately not treated as optionality" do
      # These all read as optional and are not: the clause qualifies a
      # preparation, and the ingredient itself is required. See the comment in
      # RoleDetector for why no heuristic is used to rescue the real ones.
      assert %{optional: false} =
               RoleDetector.detect("1 Fresno chile, seeded if desired, finely chopped")

      assert %{optional: false} =
               RoleDetector.detect("12 oz. green beans, trimmed, patted dry if needed")

      assert %{optional: false} =
               RoleDetector.detect("1 box confectioners' sugar (3 3/4 cups), plus more if needed")

      assert %{optional: false} =
               RoleDetector.detect("1 bunch kale (remove the stems if using kale), chopped")
    end

    test "the known cost: a genuinely conditional line is missed" do
      # Recorded rather than hidden. If this ever becomes worth fixing, it needs
      # a preparation-aware parse, not another regex.
      assert %{optional: false} = RoleDetector.detect("Lime wedges, if desired")
    end

    test "the marker is normalised rather than stored as prose" do
      # "(optional. For the record, my kids hate when I add this part, ha!)" is
      # a real stored line. Capturing the whole parenthetical would write that
      # sentence into a million-row JSONB column.
      assert %{optional: true, markers: ["optional"]} =
               RoleDetector.detect("1/2 cup hazelnuts (optional. For the record, ha!)")
    end

    test "optional and a role are recorded together, not collapsed" do
      # 2,648 stored lines carry both. Folding optionality into the role enum
      # would have to discard one of them.
      assert %{role: :serving, optional: true} =
               RoleDetector.detect("Sherry (for serving; optional)")

      assert %{role: :garnish, optional: true} =
               RoleDetector.detect("Crushed red pepper flakes (for garnish (optional))")
    end
  end

  describe "ordinary ingredients" do
    test "the common case says nothing and is left alone" do
      assert RoleDetector.detect("2 cups all-purpose flour") == RoleDetector.default()
      assert RoleDetector.detect("1 (15 oz) can black beans") == RoleDetector.default()
      assert RoleDetector.detect("3 cloves garlic, minced") == RoleDetector.default()
    end

    test "divided is not a role" do
      # It means one quantity split across steps -- a statement about the
      # instructions, not about what the ingredient is for.
      assert RoleDetector.detect("1 cup chicken broth, divided") == RoleDetector.default()
    end

    test "a preparation that merely contains a role word is not a role" do
      # "garnish" and "serving" appear inside ordinary words and phrases; the
      # patterns require the purpose construction ("for"/"to"/"as"), not just
      # the noun.
      assert RoleDetector.detect("2 servings cooked rice") == RoleDetector.default()
      assert RoleDetector.detect("1 cup frying oil") == RoleDetector.default()
    end

    test "nil is tolerated" do
      assert RoleDetector.detect(nil) == RoleDetector.default()
    end
  end

  describe "markers" do
    test "the matched words are reported, so a verdict can be checked" do
      assert %{markers: ["for serving"]} = RoleDetector.detect("Hot sauce, for serving")

      assert %{markers: markers} = RoleDetector.detect("Sherry (for serving; optional)")
      assert "for serving" in markers
      assert "optional" in markers
    end

    test "markers are empty when nothing matched" do
      assert %{markers: []} = RoleDetector.detect("1 cup whole milk")
    end
  end

  describe "quantity_optional?/1" do
    test "roles that explain a missing quantity" do
      for role <- [:serving, :garnish, :to_taste, :cooking_medium] do
        assert RoleDetector.quantity_optional?(role), "expected #{role} to excuse a nil quantity"
      end
    end

    test "a plain ingredient does not get to skip its quantity" do
      refute RoleDetector.quantity_optional?(:ingredient)
    end
  end
end
