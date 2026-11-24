defmodule Controlcopypasta.Ingredients.Detection.RoleDetector do
  @moduledoc """
  Detects the *role* an ingredient line plays in a recipe, and whether it is
  optional.

  Recipe lines carry two kinds of information: what the ingredient is, and what
  it is there for. The parser's job is the former, and to do it well it strips
  the latter — `TokenParser.strip_trailing_flavor_notes/1` removes
  "for serving" so that "Flaky sea salt, for serving" can match the `sea salt`
  canonical, and `strip_leading_optional/1` removes a leading "optional:" for
  the same reason. Both are correct and must keep happening.

  The cost is that the purpose was discarded along with the words. This module
  recovers it, by reading the **original** line rather than the preprocessed
  one. It deliberately does not participate in preprocessing: it looks at the
  text and returns a verdict, so no match can change because of it.

  ## Roles

  | Role | Meaning | Example |
  |---|---|---|
  | `:ingredient` | part of the dish proper | `2 cups flour` |
  | `:serving` | added at the table, usually unquantified | `cilantro, for serving` |
  | `:garnish` | explicitly decorative | `parsley, for garnish` |
  | `:to_taste` | real food, unquantifiable by nature | `salt, to taste` |
  | `:cooking_medium` | mostly discarded, not eaten | `oil, for frying` |

  `:serving` and `:garnish` are kept apart because recipes use them
  differently — "for serving" is overwhelmingly a side or condiment
  ("warm tortillas, for serving"), while "for garnish" is decoration. They are
  treated the same by nutrition today, but the distinction is free to record
  and expensive to recover later.

  ## Optionality is not a role

  `optional` is a separate boolean, not a role value, because the two are
  genuinely orthogonal: "sherry (for serving; optional)" is both at once, and
  that combination appears on thousands of stored lines. Collapsing them into
  one field would force a lossy choice on exactly the lines that say the most.
  """

  @type role :: :ingredient | :serving | :garnish | :to_taste | :cooking_medium

  @type t :: %{
          role: role(),
          optional: boolean(),
          markers: [String.t()]
        }

  # Patterns are ordered most-specific-first within each group, and every one
  # of them was taken from the stored corpus rather than invented -- see
  # parser-v3/ingredient-roles.md for the frequency table they came from.

  # "oil for frying", "butter for greasing the pan". Matched before the serving
  # patterns because "for brushing" and "for drizzling" read alike but mean
  # different things: one oils the tin, the other finishes the plate.
  @cooking_medium_verb ~r/\bfor\s+(?:deep[-\s]?)?(?:frying|greasing|coating|brushing|dredging|oiling|searing|grilling|saut(?:e|é)ing|browning)\b/i

  # The other half of cooking medium names the *vessel* instead of the verb:
  # "nonstick vegetable oil spray (for pan)", "flour (for work surface)",
  # "vegetable oil (for grill)". Nearly 10,000 stored rows use this shape and
  # the verb patterns above miss all of them. The noun list is closed on
  # purpose -- "for the pan" is a vessel, but "for the sauce" is an ingredient
  # of the sauce, so this cannot generalise to "for the <anything>".
  @cooking_medium_vessel ~r/\bfor\s+(?:the\s+)?(?:pan|pans|skillet|skillets|bowl|bowls|pot|pots|grill|grills|griddle|surface|work\s+surface|baking\s+sheet|baking\s+sheets|sheet|sheets|tin|tins|mold|molds|moulds?|spatula|dish|dishes|waffle\s+iron|ramekins?|parchment)\b/i

  @garnish ~r/\b(?:for|to|as)\s+(?:a\s+|the\s+)?garnish(?:ing|es)?\b|^\s*garnish\s*[:–-]/i

  @serving ~r/\bfor\s+(?:serving|topping|toppings|sprinkling|dusting|dipping|drizzling|finishing|spooning|smearing)\b|\bto\s+(?:serve|top|finish|dust|drizzle)\b|^\s*(?:to\s+serve|for\s+serving)\s*[:–-]/i

  @to_taste ~r/\b(?:to|according\s+to)\s+taste\b|\bas\s+needed\b|\bas\s+desired\b/i

  # A bare seasoning line is "to taste" without saying so. "Kosher salt" on its
  # own line (16,368 stored rows) and "Freshly ground pepper" (16,248) mean
  # season to taste; the author omitted the words because the convention is
  # understood. Together with the other bare forms this is ~48,000 rows, every
  # one of which was being reported as a nutrition failure.
  #
  # The rule is textual and conservative in the one way that matters: the line
  # must contain no digits, so "1 tsp. freshly ground pepper" is untouched. In
  # the corpus the split is absolute -- the bare forms have zero quantified
  # occurrences and the quantified forms always carry a number.
  @seasoning_nouns ~w(salt pepper peppercorn peppercorns)
  @seasoning_modifiers ~w(
    kosher sea flaky fine finely coarse coarsely freshly fresh ground
    cracked black white table maldon flake flakes grey gray
    and or plus more of a pinch optional to taste
  )

  # "optional" is unambiguous wherever it appears: as a parenthetical, as a
  # trailing clause, or as a leading label.
  @optional ~r/\boptional\b/i

  # The "if ..." family -- "if desired", "if needed", "if using" -- looks like
  # optionality and is deliberately NOT treated as it. The corpus says it is
  # almost always qualifying a *preparation*, not the ingredient:
  #
  #   "1 Fresno chile, seeded if desired, finely chopped"   -- chile required
  #   "whole milk ricotta, drained if needed"               -- ricotta required
  #   "confectioners' sugar (3 3/4 cups), plus more if needed"
  #   "1 bunch kale (remove the stems if using kale), chopped"
  #
  # Requiring the clause to end the line, then excluding a preceding participle
  # and the "plus more" shape, got it down to 27 distinct lines across the whole
  # 36k-line corpus -- still mostly wrong ("plus more juice if desired",
  # "(or less, if desired)"). Two stacked heuristics earning 27 lines of mostly
  # bad verdicts is a worse trade than missing the handful of real ones like
  # "Lime wedges, if desired", so the family is left alone. `optional` on its
  # own covers 1,204 of the 1,231 lines with no judgment call to defend.

  # A purpose clause introduced by "plus more" describes the *top-up*, not the
  # line. "2 cups buckwheat flour, plus more for surface" is two cups of flour
  # you bake with and an unmeasured extra you dust the counter with -- the
  # ingredient is the flour, and calling the whole line :cooking_medium is
  # wrong. Likewise "1 cup sugar, plus more for serving" is sugar, not a
  # condiment.
  #
  # This affects 18,080 rows that were being labelled :serving and 5,665
  # labelled :cooking_medium. It never changed their nutrition -- they have a
  # quantity, so the role never suppressed anything -- but it put a wrong badge
  # on an ordinary ingredient.
  #
  # The tail is removed for ROLE detection only. Optionality keeps reading the
  # whole line, because "(optional)" can legitimately sit after a top-up.
  # Both spellings: "plus more for pan" and the bare "more for greasing pan".
  # The bare form requires a following purpose word so that "1 cup or more
  # water" is not mistaken for a top-up clause.
  @top_up ~r/,?\s*\b(?:(?:plus|and)\s+(?:more|additional|extra|a\s+few|\d)|(?:more|additional|extra)\s+(?:for|to)\b).*$/is

  defp strip_top_up(text), do: String.replace(text, @top_up, "")

  @doc """
  Classifies an ingredient line.

  Always returns a verdict; `:ingredient` with `optional: false` is the
  (overwhelmingly common) default.

      iex> RoleDetector.detect("Flaky sea salt, for serving")
      %{role: :serving, optional: false, markers: ["for serving"]}

      iex> RoleDetector.detect("1 tsp cayenne (optional)")
      %{role: :ingredient, optional: true, markers: ["(optional)"]}

      iex> RoleDetector.detect("2 cups all-purpose flour")
      %{role: :ingredient, optional: false, markers: []}
  """
  @spec detect(String.t() | nil) :: t()
  def detect(nil), do: default()

  def detect(text) when is_binary(text) do
    {role, role_markers} = detect_role(text)
    {optional, optional_markers} = detect_optional(text)

    %{
      role: role,
      optional: optional,
      markers: Enum.uniq(role_markers ++ optional_markers)
    }
  end

  @doc "The verdict for a line that says nothing about its role."
  @spec default() :: t()
  def default, do: %{role: :ingredient, optional: false, markers: []}

  @doc """
  True when a line is not expected to carry a quantity.

  A garnish or a to-taste line with no quantity is complete as written, not
  broken -- which is the distinction the nutrition calculator needs in order to
  stop reporting "cilantro, for serving" as a failed ingredient.
  """
  @spec quantity_optional?(role()) :: boolean()
  def quantity_optional?(role), do: role in [:serving, :garnish, :to_taste, :cooking_medium]

  # Role is single-valued, so the order here is the precedence. A line that says
  # both "for frying" and "to taste" is about the frying.
  defp detect_role(text) do
    text = strip_top_up(text)

    cond do
      m = first_match(@cooking_medium_verb, text) -> {:cooking_medium, [m]}
      m = first_match(@cooking_medium_vessel, text) -> {:cooking_medium, [m]}
      m = first_match(@garnish, text) -> {:garnish, [m]}
      m = first_match(@serving, text) -> {:serving, [m]}
      m = first_match(@to_taste, text) -> {:to_taste, [m]}
      # Checked last: an explicit purpose always beats the convention, so
      # "flaky sea salt, for serving" stays :serving rather than becoming
      # :to_taste on account of being a bare seasoning.
      bare_seasoning?(text) -> {:to_taste, ["bare seasoning"]}
      true -> {:ingredient, []}
    end
  end

  @doc """
  True when a line is nothing but a seasoning name and its modifiers, with no
  amount anywhere in it.

  Exposed because it is the one rule here that reads as a guess rather than a
  quotation, and it is worth being able to check directly.
  """
  @spec bare_seasoning?(String.t()) :: boolean()
  def bare_seasoning?(text) when is_binary(text) do
    if String.match?(text, ~r/[0-9¼½¾⅓⅔⅛⅜⅝⅞]/) do
      false
    else
      words =
        text
        |> String.downcase()
        |> String.split(~r/[^a-z]+/, trim: true)

      words != [] and
        Enum.any?(words, &(&1 in @seasoning_nouns)) and
        Enum.all?(words, &(&1 in @seasoning_nouns or &1 in @seasoning_modifiers))
    end
  end

  def bare_seasoning?(_), do: false

  # The marker is normalised to the bare word rather than the matched span:
  # "(optional. For the record, my kids hate when I add this part, ha!)" is a
  # real stored line, and capturing the whole parenthetical would write that
  # sentence into a million-row JSONB column.
  defp detect_optional(text) do
    if first_match(@optional, text), do: {true, ["optional"]}, else: {false, []}
  end

  # Returns the matched text itself, not just a boolean, so `markers` can show
  # which words drove the verdict. That is the difference between a flag you
  # can debug and one you have to take on faith.
  defp first_match(regex, text) do
    case Regex.run(regex, text) do
      [match | _] -> match |> String.trim() |> String.downcase()
      nil -> nil
    end
  end
end
