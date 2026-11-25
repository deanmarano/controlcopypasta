# Ingredient Roles: optional, garnish, to-taste

**Status: built.** Backend, nutrition and the display badge have landed.
Shopping-list grouping has not — see "Not built" at the bottom.

## The problem

The parser already *detects* these phrases and then throws the finding away.

`"Flaky sea salt (for serving)"` parses to canonical `sea salt` with no quantity.
`"1 tsp cayenne (optional)"` parses to canonical `cayenne`, quantity 1 tsp.
Both are correct. Neither records that one is a garnish and the other is skippable.

This is **not** a match-rate problem. Measured over the 1,055,642 stored
ingredient rows:

| Marker family | Rows | Distinct texts | Already match a canonical |
|---|---|---|---|
| serving / garnish / topping / drizzling | 63,708 | 2,660 | 63,059 (99.0%) |
| optional / if desired / if you like / if using | 13,563 | 1,067 | 12,469 (91.9%) |
| both | 2,648 | 235 | 2,171 |

TODO.md sizes these at ~443 and ~1,202 because those numbers came from the
*unmatched* ingredient analysis — they only ever counted the lines that failed.
The lines that matter are the ones that succeed and lose information.

Note the distinct-text column: 129k rows but only ~3.5k distinct phrasings. The
rule surface is small; a handful of patterns covers nearly all of it.

### Why it is worth doing

Of the 108,077 matched ingredients with no quantity, **40,665 (38%) carry a
role marker** — they are quantity-less by design, not by failure. Today
`Calculator.process_ingredient/3` gives every one of them
`status: :no_quantity, error: "No quantity found"`, and
`generate_warnings/2` reports them as "could not be calculated" alongside
genuine failures. A recipe whose only gap is "cilantro, for serving" reads as
incomplete nutrition. That is the single biggest measurable win here.

## Where the information is lost

Two places in `TokenParser.preprocess_text/2`, both deliberate:

- `strip_leading_optional/1` (token_parser.ex:310) — drops a leading `optional:`
- `strip_trailing_flavor_notes/1` (token_parser.ex:530) — drops trailing
  `for serving|garnish|garnishing|topping|drizzling|dipping|finishing`,
  `to serve`, `to dust`, `for frying`

Both must keep stripping: that is how the remainder matches the catalog.

`Tokenizer` also has `@notes ~w(optional divided)` and a 40-entry
`@note_phrases` list, and labels those tokens `:note` (tokenizer.ex:603,642).
But `analyze/1` never extracts them, and `ParsedIngredient` has a `notes` field
that is hardcoded to `[]` at both construction sites (token_parser.ex:156, 850)
and asserted by no test. So the label exists and is dropped on the floor.

Critically: because stripping happens *before* tokenizing, for most lines the
`:note` token never forms at all — the phrase is already gone. Detection cannot
be bolted onto the tokenizer; it has to read the original text.

## Proposed design

### 1. A detector on the original text

New `Ingredients.Detection.RoleDetector`, alongside the existing
`EquipmentDetector`:

```elixir
@spec detect(String.t()) :: %{optional: boolean(), role: role(), markers: [String.t()]}
# role :: :ingredient | :garnish | :serving | :to_taste | :cooking_medium
```

It runs on `original_text`, which `parse_preprocessed/5` already has in hand.
It does not touch the preprocessing pipeline, the tokenizer, or the matcher —
so **no existing match can change**. That is the main reason to do it this way
rather than threading state through the strippers.

Roles worth separating (they behave differently downstream):

- `:garnish` / `:serving` — real food, eaten, usually unquantified
- `:to_taste` — real food, unquantifiable by nature (2,536 rows)
- `:cooking_medium` — `oil for frying`; mostly discarded, not consumed
- `:ingredient` — everything else

`optional` is orthogonal to role, not a role value: `sherry (for serving;
optional)` is both. 2,648 rows prove the overlap is real, so it is two fields.

### 2. Plumbing

- `ParsedIngredient`: add `:optional` (boolean) and `:role` (atom). Populate
  `:notes` with the matched markers while we are there, since it is sitting
  there empty.
- Apply in `parse_preprocessed/5` **after** the sub-parser branch, so garlic /
  citrus / egg results get it too without touching four more modules.
- `to_jsonb_map/1` (token_parser.ex:879): emit `"optional"` and `"role"`, only
  when non-default, to keep the 1M-row corpus from growing for nothing.
- `recipe_json.ex:182` is `ingredients: recipe.ingredients` — raw passthrough,
  so the new keys reach the frontend with no view change.
- Frontend `Ingredient` interface (client.ts:223): add `optional?: boolean`,
  `role?: string`.

### 3. Consumers

**Nutrition** re-parses from `"text"` on every request
(`Calculator.process_ingredient/3`, calculator.ex:164) and ignores stored
structure entirely. So it picks the role up with **no backfill at all**. Change:
a quantity-less ingredient whose role is `:garnish`, `:serving` or `:to_taste`
gets `status: :not_counted` instead of `:no_quantity`, and
`count_calculated/1` excludes it from the denominator rather than counting it
as a miss.

**Shopping lists** go through the much simpler `Similarity.IngredientParser`
and read the stored maps (shopping_lists.ex:195), so they need the stored flag.
Garnishes still belong on the list — you do have to buy the cilantro — so the
change is presentational: group them under a "garnishes & extras" heading.

**Display**: a small badge on the ingredient row.

### 4. Backfill

`mix parse_ingredients --force` already exists and re-serializes every recipe
through `to_jsonb_map/1` in 200-row batches. No migration, no new tooling —
ingredients are JSONB with no embedded schema.

## Two defaults, as built

Both reversible, and the data argues for them:

1. **Optional ingredients still count toward nutrition.** The recipe as written
   includes them, and most have a real canonical and a real quantity.
   Excluding them would silently understate. The flag makes it *possible* to
   exclude later, per-user; it does not do so by default.

2. **Garnishes count when quantified, are excluded when not.** `1 tbsp chopped
   parsley, for garnish` has real calories; count it. `parsley leaves (for
   serving)` has none, and inventing one is worse than reporting "not counted".

## What the corpus changed about the plan

### The `if ...` family is not optionality

`if desired`, `if needed`, `if using` read exactly like optionality markers and
the scope above assumed they were. They are not. In the stored corpus they
almost always qualify a **preparation**, and the ingredient is mandatory:

```
1 Fresno chile, seeded if desired, finely chopped      <- chile required
whole milk ricotta, drained if needed                  <- ricotta required
confectioners' sugar (3 3/4 cups), plus more if needed <- sugar required
1 bunch kale (remove the stems if using kale), chopped  <- kale required
```

Treating them as optional would have marked ~150 mandatory lines skippable.

Two successive heuristics were tried — require the clause to end the line, then
also exclude a preceding past participle and the "plus more" shape. That got it
to 27 distinct lines out of 36,374, still mostly wrong (`plus more juice if
desired`, `(or less, if desired)`). Both were deleted. `optional` on its own
covers 1,204 of the 1,231 distinct optional lines with no judgment call to
defend, and the known cost — missing `Lime wedges, if desired` — has a test
recording it rather than a comment hiding it.

### Markers are normalised

`role_markers` records the bare word, not the matched span.
`(optional. For the record, my kids hate when I add this part, ha!)` is a real
stored line; capturing the parenthetical would write that sentence into a
million-row JSONB column.

## Measured result

Role census over all 1,055,642 stored rows:

| Role | Rows |
|---|---|
| `:ingredient` | 946,973 |
| `:to_taste` | 51,678 |
| `:serving` | 44,041 |
| `:cooking_medium` | 12,442 |
| `:garnish` | 508 |
| optional (any role) | 22,418 |

**100,667 of the 108,077 matched-but-quantity-less ingredients (93%) come back
`:not_counted` instead of `:no_quantity`** — excluded from the completeness
denominator rather than counted as failures.

Proof the change is additive: parsing all 36,374 distinct stored ingredient
lines on this branch and on pre-roles trunk produces **byte-identical**
`canonical_id`, `quantity`, `quantity_min`, `quantity_max`, `unit`,
`container`, `preparations` and `is_alternative`.

## Second pass: three patterns the first pass missed

The first pass took the 108,077 figure from 108,077 to 42,431 excluded. Looking
at what was left showed it was not a long tail — it was three more shapes of the
same thing.

### Cooking medium is also named by vessel

The verb patterns (`for frying`, `for greasing`) missed the ~10,000 rows that
name the *vessel* instead: `nonstick vegetable oil spray (for pan)`,
`flour (for work surface)`, `vegetable oil (for grill)`,
`butter, softened, for the pan`.

The noun list is closed on purpose. `for the pan` is a vessel; `for the sauce`
is a component of the dish, so this cannot generalise to `for the <anything>`.

### A bare seasoning line is "to taste" without saying so

`Kosher salt` on its own line is 16,368 stored rows. `Freshly ground pepper` is
another 16,248. Both mean season to taste; the author omitted the words because
the convention is understood. With the other bare forms it is ~48,000 rows,
every one of which was reported as a nutrition failure.

The rule requires the line to contain **no digits**, so `1 tsp. freshly ground
pepper` is untouched. In the corpus this split is absolute: the bare forms have
zero quantified occurrences and the measured forms always carry a number.

It is checked last, so an explicit purpose always wins — `flaky sea salt, for
serving` stays `:serving`.

### "plus more for X" describes the top-up, not the line

This one was a **bug in the first pass**, not a missing pattern.

```
2 cups buckwheat flour, plus more for surface   -> was :cooking_medium
1 cup sugar, plus more for serving              -> was :serving
```

Both are ordinary ingredients with an unmeasured extra. 18,080 rows were
labelled `:serving` this way and 5,665 `:cooking_medium`. It never affected
nutrition — they all have a quantity, so the role never suppressed anything —
but it put a wrong badge on an ordinary ingredient.

The top-up tail is now removed before role detection, and **only** before role
detection: `(optional)` can legitimately sit after a top-up clause, so
optionality still reads the whole line.

This is the same error as the `if desired` family one level up: a clause that
qualifies part of a line, read as if it qualified the line.

### What is still left

Both follow-ups named below have since landed: `pinch` is read as a quantity
and converts to grams, and a semicolon inside a parenthetical no longer
truncates the line (which was costing ~6,300 rows the ingredient itself).

The remaining cohorts are re-measured in the equipment pass that follows this
one, which changes the picture enough that counting them twice here would only
go stale.

## Not built

- **Shopping-list grouping.** Shopping lists read the *stored* maps, so this
  cannot work until `mix parse_ingredients --force` has run in production.
  Better as a follow-up behind the backfill than as dead code in this change.
- **Tightening the completeness test to reject bare `:no_quantity`.** The
  cohort is down to 4,610 rows and well understood, but the equipment pass
  above should land first -- it is the larger source of false failures.

## Out of scope

`divided` is the third big cohort — 52,107 rows, 1,440 distinct texts, 98.7%
matching. It looks similar but it is a different feature: it means "this one
quantity is split across several steps", which is a question about
instructions, not about roles. Worth its own pass.

## Verification plan

Same shape as the last two parser changes, which is what caught the problems in
both:

1. Unit tests for `RoleDetector` over the real distinct phrasings, pulled from
   the corpus rather than invented.
2. Differential run over all 1,055,642 stored lines asserting that
   `canonical_id`, `quantity` and `unit` are **byte-identical** before and
   after. The detector is additive; anything else changing is a bug.
3. Nutrition completeness before/after on the existing
   `recipe_nutrition_completeness_test.exs` fixtures, to show the metric moves
   for the right reason.

## Rough size

Detector + plumbing + tests is the bulk; the nutrition status change is small
but needs the completeness assertions redone. Shopping-list grouping and the
UI badge are independent and could land separately.
