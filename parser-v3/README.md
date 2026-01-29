# Parser V3: Deep Ingredient Structure

## Overview

Enhance the ingredient parsing system to extract richer semantic information:

| Feature | Description | Status |
|---------|-------------|--------|
| [Nested Recipes](./nested-recipes.md) | Parse "see recipe below/above" and create parent-child relationships | Planned |
| [Pre-Steps](./pre-steps.md) | Convert preparations into actionable prep instructions | Planned |
| [Diagnostics](./diagnostics.md) | Visual representation of tokenization and matching | Planned |
| [Simple Decisions](./simple-decisions.md) | Let users choose between alternatives, update nutrition | Planned |

---

## Implementation Order

### Phase 1: Diagnostics (Foundation)
1. Create `ParseDiagnostics` struct
2. Add diagnostic capture to `TokenParser.parse/2`
3. Update JSONB to include `_diagnostics` when enabled
4. Build `IngredientDiagnostics.svelte` component
5. Add to recipe display pages (collapsible, bottom of page)
6. Admin toggle to enable/disable

**Why first:** Diagnostics help debug the other features during development.

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
