# Parser V3: Deep Ingredient Structure

## Overview

Enhance the ingredient parsing system to extract richer semantic information:

| Feature | Description | Status |
|---------|-------------|--------|
| [Nested Recipes](./nested-recipes.md) | Parse "see recipe below/above" and create parent-child relationships | Planned |
| [Pre-Steps](./pre-steps.md) | Convert preparations into actionable prep instructions | Planned |
| [Diagnostics](./diagnostics.md) | Visual representation of tokenization and matching | Done |
| [Simple Decisions](./simple-decisions.md) | Let users choose between alternatives, update nutrition | Planned |

---

## Implementation Order

### Phase 1: Diagnostics (Foundation) — done

1. ~~Create `ParseDiagnostics` struct~~
2. ~~Add diagnostic capture to `TokenParser.parse/2`~~
3. ~~Update JSONB to include `_diagnostics` when enabled~~ — **dropped.** Diagnostics
   are computed on read, not stored. See below.
4. ~~Build `IngredientDiagnostics.svelte` component~~
5. ~~Add to recipe display pages (collapsible, bottom of page)~~
6. ~~Admin toggle to enable/disable~~ — `?diagnostics=1` on the recipe page,
   admin-only, served by `GET /api/recipes/:id?include_diagnostics=true`.

**Why first:** Diagnostics help debug the other features during development.

#### How it actually works

`Ingredients.attach_parse_diagnostics/1` **re-parses** the recipe's ingredient
text on every request, against the current canonicals and the current parser.
Nothing is persisted. This was chosen over the JSONB design in step 3 because:

- Stored diagnostics describe the parser as it was on the day the recipe was
  saved, and go stale on the next parser change. Re-parsing always describes
  the parser you are debugging.
- No migration, no backfill of the existing corpus, no ~500 bytes per
  ingredient of JSONB growth.
- It makes **parser drift** visible: the stored `canonical_name` and the
  freshly parsed one are both reported, with a `drifted` flag when they
  disagree. That disagreement is the most useful single signal in the panel.

The cost is a parse per ingredient per request, which is why it is opt-in and
admin-gated rather than on by default.

#### Two fields to be careful about

- `match_strategy` is **recorded by the `Matcher` at the branch that matched**,
  not inferred from the confidence. It cannot be inferred: `:dropped_leading_word`
  and `:dropped_trailing_word` both use 0.9, and `IngredientScorer` overwrites
  the confidence with its own score afterwards.
- `alternatives` holds the other ingredients found on the **same line** (the
  "salt" and "pepper" of one entry), *not* near-miss canonicals that lost the
  match. The UI labels it "Also On This Line" to avoid implying otherwise.
- `match_trail` is the field that actually explains a match. See below.

#### Why there is a trail and not a candidate ranking

The original design asked for the "top 3 canonical matches considered" with a
confidence and a reason each. The `Matcher` cannot produce that, because it
does not score candidates and pick a winner — it is a **short-circuiting
cascade**. It rewrites the input (singularize, strip modifiers, drop a word,
split a compound) and does an exact lookup of each rewrite in turn, returning
the first one that resolves. Nothing is ever ranked, and no canonical is ever
"considered and rejected" on quality.

So the honest artifact is the **attempt trail**: every key the matcher looked
up, under which strategy, in order, and whether it hit. Reading it top to
bottom is the answer to "why did this line match that canonical", because each
earlier line is a rewrite that found nothing.

```
"3 sprigs of lovage" -> no match
  miss  exact                 "sprigs of lovage"
  miss  stripped_modifiers    "sprigs of lovage"
  miss  dropped_leading_word  "of lovage"
  miss  dropped_trailing_word "sprigs of"
  miss  dropped_leading_word  "lovage"
  miss  single_word           "lovage"
  miss  compound_split        "4 split positions of \"lovage\""
  miss  fuzzy_prefix          "lovage"
```

Implementation notes:

- The trail is collected by `Matcher.match/3` with `trace: true`. Without it
  the accumulator is `nil` and every record is a no-op, so the bulk-scan path
  (hundreds of thousands of lines) allocates nothing extra.
- Attempts are recorded in `try_key/4`, the one place a lookup happens, so the
  trail cannot drift out of step with the control flow that produced it.
- `compound_split` probes every split position and `fuzzy_prefix` scans the
  whole lookup; both are collapsed to a single summary entry so they do not
  bury the rest of the trail.
- Diagnostics get the trail by **replaying** the primary ingredient's match
  with tracing on, rather than threading a trace flag through every parsing
  path. Matching is pure and `primary.name` is the exact string the matcher was
  given, so the replay reproduces the original decision; if the replayed
  strategy disagrees, the trail is dropped rather than displayed next to a
  strategy it does not explain.

A genuine "what else was close" view is a different feature and already exists
separately as `POST /admin/ingredients/test-scorer`, which scores the whole
catalogue for one input.

#### Also fixed here

Lines dropped by `preprocess_text/2` (kitchen equipment, section headers, a
bare "salt and pepper") previously returned before diagnostics were built, so
the most interesting case — a line that silently vanished — produced nothing to
look at. They now report which rule dropped them, so a nil canonical can be
told apart from a parse failure.

### Phase 2: Pre-Steps
1. Expand `Preparation` module with metadata
2. Create `PreStepGenerator` module
3. Add `pre_steps` to JSONB structure
4. Create `PrepList` aggregation module
5. Build `PrepList.svelte` component
6. Add toggle to recipe pages

**Why second:** Relatively self-contained, uses existing preparation data.

### Phase 3: Simple Decisions
1. Create `ingredient_decisions` migration
2. Create `IngredientDecision` schema
3. Add nutrition diff calculation to alternative enrichment
4. Build `IngredientDecision.svelte` component
5. Create decision API endpoints
6. Integrate with nutrition calculator
7. Add decisions summary panel

**Why third:** Leverages existing alternative detection, high user value.

### Phase 4: Nested Recipes
1. Create `recipe_references` migration
2. Create `RecipeReference` schema
3. Build `SubParsers.RecipeReference` module
4. Add reference detection to parsing flow
5. Implement sub-recipe extraction from page sections
6. Build resolution/linking logic
7. Frontend: recipe reference links
8. Handle scaling of sub-recipes

**Why last:** Most complex, requires new database structure and multi-recipe handling.

---

## Shared Database Migrations

```elixir
# All migrations in order:

# 1. Diagnostics flag (optional)
alter table(:recipes) do
  add :include_diagnostics, :boolean, default: false
end

# 2. Recipe references
create table(:recipe_references, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :parent_recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all)
  add :child_recipe_id, references(:recipes, type: :binary_id, on_delete: :nilify_all)
  add :ingredient_index, :integer
  add :reference_type, :string
  add :reference_text, :string
  add :extracted_name, :string
  add :resolved_at, :utc_datetime
  add :is_optional, :boolean, default: false
  timestamps()
end

# 3. Ingredient decisions
create table(:ingredient_decisions, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all)
  add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
  add :ingredient_index, :integer, null: false
  add :selected_canonical_id, :binary_id, null: false
  add :selected_name, :string
  timestamps()
end
```

---

## Performance Considerations

1. **Diagnostics overhead**: Only capture when explicitly enabled
2. **Pre-step generation**: Cache at parse time, not per-request
3. **Sub-recipe queries**: Use preloading to avoid N+1
4. **JSONB size**: `_diagnostics` field adds ~500 bytes per ingredient
5. **Nutrition diffs**: Pre-compute during parsing, not on every request

---

## Future Enhancements

- **AI-assisted matching**: Use embeddings for fuzzy ingredient matching
- **Prep video links**: Link preparations to technique videos
- **Smart timing**: Factor prep steps into recipe total time
- **Shopping list integration**: Generate shopping list with prep notes
- **Collaborative correction**: Allow users to fix parsing errors
