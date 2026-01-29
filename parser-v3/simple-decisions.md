# Simple Decisions (Alternative Ingredients)

## Problem

Many ingredients offer alternatives:
- "1 cup avocado oil or coconut oil"
- "2 cups chicken or vegetable stock"
- "1/2 cup Greek yogurt or sour cream"
- "butter or margarine"

Currently these are parsed and stored as `alternatives` in the JSONB, but:
1. Users can't indicate which option they're actually using
2. Nutrition calculations use the primary ingredient only
3. No way to see how the choice affects the recipe

## Current State

The parser already detects "or" patterns:
```elixir
%{
  "canonical_name" => "avocado oil",
  "alternatives" => [
    %{"name" => "coconut oil", "canonical_name" => "coconut oil", "canonical_id" => "..."}
  ],
  "is_alternative" => true
}
```

But this data isn't surfaced to users or used in calculations.

---

## Proposed Solution

### User Decisions Schema

```elixir
# lib/controlcopypasta/recipes/ingredient_decision.ex
defmodule Controlcopypasta.Recipes.IngredientDecision do
  @moduledoc """
  Stores user decisions for alternative ingredients in their saved recipes.
  """
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "ingredient_decisions" do
    belongs_to :recipe, Recipe
    belongs_to :user, User

    field :ingredient_index, :integer       # Which ingredient line
    field :selected_canonical_id, :binary_id # The chosen alternative
    field :selected_name, :string           # Display name of selection

    timestamps()
  end
end
```

### Decision Context for Nutrition

```elixir
defmodule Controlcopypasta.Nutrition.DecisionContext do
  @moduledoc """
  Applies user decisions to nutrition calculations.
  """

  def apply_decisions(recipe, user_id) do
    decisions = get_decisions(recipe.id, user_id)

    recipe.ingredients
    |> Enum.with_index()
    |> Enum.map(fn {ingredient, idx} ->
      case Map.get(decisions, idx) do
        nil -> ingredient  # No decision, use primary
        decision -> apply_decision(ingredient, decision)
      end
    end)
  end

  defp apply_decision(ingredient, decision) do
    # Swap the primary ingredient with the selected alternative
    %{ingredient |
      canonical_name: decision.selected_name,
      canonical_id: decision.selected_canonical_id
    }
  end
end
```

---

## Enhanced JSONB with Decision Metadata

```elixir
%{
  "text" => "1 cup avocado oil or coconut oil",
  "canonical_name" => "avocado oil",
  "canonical_id" => "uuid-avocado",
  "is_alternative" => true,
  "alternatives" => [
    %{
      "name" => "coconut oil",
      "canonical_name" => "coconut oil",
      "canonical_id" => "uuid-coconut",
      "nutrition_diff" => %{           # NEW: Pre-computed difference
        "calories" => -4,              # Coconut has 4 fewer cal/tbsp
        "fat_saturated_g" => +7.2      # But more saturated fat
      }
    }
  ],
  "decision" => null  # Populated per-user at runtime
}
```

---

## Frontend: Decision Selector Component

```svelte
<!-- IngredientDecision.svelte -->
<script>
  import { createEventDispatcher } from 'svelte';

  export let ingredient;
  export let index;
  export let currentDecision = null;

  const dispatch = createEventDispatcher();

  $: options = [
    {
      id: ingredient.canonical_id,
      name: ingredient.canonical_name,
      isPrimary: true
    },
    ...ingredient.alternatives.map(alt => ({
      id: alt.canonical_id,
      name: alt.canonical_name,
      nutritionDiff: alt.nutrition_diff
    }))
  ];

  $: selectedId = currentDecision?.selected_canonical_id || ingredient.canonical_id;

  function selectOption(option) {
    dispatch('decide', {
      ingredientIndex: index,
      selectedId: option.id,
      selectedName: option.name
    });
  }
</script>

{#if ingredient.is_alternative && ingredient.alternatives?.length > 0}
  <div class="decision-selector">
    <span class="decision-label">Choose:</span>
    <div class="decision-options">
      {#each options as option}
        <button
          class="decision-option"
          class:selected={selectedId === option.id}
          on:click={() => selectOption(option)}
        >
          <span class="option-name">{option.name}</span>
          {#if option.nutritionDiff && selectedId !== option.id}
            <span class="nutrition-hint">
              {#if option.nutritionDiff.calories > 0}+{/if}{option.nutritionDiff.calories} cal
            </span>
          {/if}
          {#if option.isPrimary}
            <span class="primary-badge">recipe default</span>
          {/if}
        </button>
      {/each}
    </div>
  </div>
{/if}

<style>
  .decision-selector {
    margin: 0.5rem 0;
    padding: 0.75rem;
    background: var(--bg-surface);
    border-radius: var(--radius-md);
    border-left: 3px solid var(--color-pasta-400);
  }

  .decision-label {
    font-size: 0.75rem;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .decision-options {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;
    margin-top: 0.5rem;
  }

  .decision-option {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    border: 1px solid var(--border-default);
    border-radius: var(--radius-md);
    background: var(--bg-card);
    cursor: pointer;
    transition: all 0.15s ease;
  }

  .decision-option:hover {
    border-color: var(--color-basil-400);
    background: var(--color-basil-50);
  }

  .decision-option.selected {
    border-color: var(--color-basil-500);
    background: var(--color-basil-100);
    font-weight: 500;
  }

  .nutrition-hint {
    font-size: 0.75rem;
    color: var(--text-muted);
    padding: 0.125rem 0.375rem;
    background: var(--bg-surface);
    border-radius: var(--radius-sm);
  }

  .primary-badge {
    font-size: 0.625rem;
    color: var(--text-muted);
    text-transform: uppercase;
  }
</style>
```

---

## Recipe Page Integration

```svelte
<!-- In recipes/[id]/+page.svelte -->
<script>
  import IngredientDecision from '$lib/components/IngredientDecision.svelte';

  let decisions = {};  // Map of ingredientIndex -> decision

  async function handleDecision(event) {
    const { ingredientIndex, selectedId, selectedName } = event.detail;

    // Optimistic update
    decisions[ingredientIndex] = {
      selected_canonical_id: selectedId,
      selected_name: selectedName
    };

    // Persist to backend
    await api.recipes.saveDecision(recipe.id, ingredientIndex, selectedId);

    // Recalculate nutrition with new decisions
    await refreshNutrition();
  }

  async function refreshNutrition() {
    const result = await api.recipes.getNutrition(recipe.id, {
      decisions: Object.entries(decisions).map(([idx, d]) => ({
        ingredient_index: parseInt(idx),
        selected_canonical_id: d.selected_canonical_id
      }))
    });
    nutritionData = result.data;
  }
</script>

<section class="ingredients">
  <h2>Ingredients</h2>
  {#each recipe.ingredients as ingredient, i}
    <div class="ingredient-row">
      <span class="ingredient-text">{scaleIngredient(ingredient.text)}</span>

      <IngredientDecision
        {ingredient}
        index={i}
        currentDecision={decisions[i]}
        on:decide={handleDecision}
      />
    </div>
  {/each}
</section>

<!-- Nutrition panel updates based on decisions -->
<section class="nutrition">
  <h2>Nutrition <span class="per-serving">per serving</span></h2>
  {#if hasDecisions}
    <p class="decisions-note">
      Calculated with your ingredient choices
    </p>
  {/if}
  <!-- nutrition display -->
</section>
```

---

## Decisions Summary Panel

```svelte
<!-- DecisionsSummary.svelte -->
<script>
  export let ingredients;
  export let decisions;

  $: activeDecisions = Object.entries(decisions)
    .filter(([idx, d]) => {
      const ing = ingredients[parseInt(idx)];
      return d.selected_canonical_id !== ing.canonical_id;
    });
</script>

{#if activeDecisions.length > 0}
  <div class="decisions-summary">
    <h4>Your Choices</h4>
    <ul>
      {#each activeDecisions as [idx, decision]}
        {@const original = ingredients[parseInt(idx)]}
        <li>
          <span class="swap">
            <s>{original.canonical_name}</s> -> {decision.selected_name}
          </span>
        </li>
      {/each}
    </ul>
    <button class="reset-btn" on:click={resetAllDecisions}>
      Reset to recipe defaults
    </button>
  </div>
{/if}
```

---

## API Endpoints

```elixir
# Save a decision
POST /api/recipes/:id/decisions
{
  "ingredient_index": 0,
  "selected_canonical_id": "uuid-coconut-oil"
}

# Get nutrition with decisions applied
GET /api/recipes/:id/nutrition?decisions[0]=uuid-coconut&decisions[2]=uuid-vegetable-stock

# Get all user decisions for a recipe
GET /api/recipes/:id/decisions
{
  "decisions": [
    {"ingredient_index": 0, "selected_canonical_id": "uuid-coconut", "selected_name": "coconut oil"}
  ]
}

# Clear all decisions (reset to defaults)
DELETE /api/recipes/:id/decisions
```

---

## Nutrition Calculation with Decisions

```elixir
defmodule Controlcopypasta.Nutrition.Calculator do
  def calculate_for_recipe(recipe, opts \\ []) do
    decisions = Keyword.get(opts, :decisions, %{})
    servings = Keyword.get(opts, :servings, recipe.servings || 1)

    recipe.ingredients
    |> Enum.with_index()
    |> Enum.map(fn {ingredient, idx} ->
      # Apply decision if present
      canonical_id = case Map.get(decisions, idx) do
        nil -> ingredient["canonical_id"]
        decision -> decision.selected_canonical_id
      end

      calculate_ingredient_nutrition(canonical_id, ingredient["quantity"])
    end)
    |> sum_nutrition()
    |> divide_by_servings(servings)
  end
end
```

---

## Pre-compute Nutrition Differences

When parsing, calculate the nutrition difference between alternatives:

```elixir
defmodule Controlcopypasta.Ingredients.AlternativeEnricher do
  def enrich_alternatives(parsed_ingredient) do
    primary = parsed_ingredient.primary_ingredient
    primary_nutrition = get_nutrition(primary.canonical_id)

    alternatives = Enum.map(parsed_ingredient.ingredients, fn alt ->
      if alt.canonical_id != primary.canonical_id do
        alt_nutrition = get_nutrition(alt.canonical_id)
        diff = calculate_diff(primary_nutrition, alt_nutrition)
        Map.put(alt, :nutrition_diff, diff)
      else
        alt
      end
    end)

    %{parsed_ingredient | ingredients: alternatives}
  end

  defp calculate_diff(primary, alt) do
    %{
      calories: (alt.calories || 0) - (primary.calories || 0),
      fat_total_g: (alt.fat_total_g || 0) - (primary.fat_total_g || 0),
      fat_saturated_g: (alt.fat_saturated_g || 0) - (primary.fat_saturated_g || 0),
      carbohydrates_g: (alt.carbohydrates_g || 0) - (primary.carbohydrates_g || 0),
      protein_g: (alt.protein_g || 0) - (primary.protein_g || 0)
    }
  end
end
```

---

## Migration

```elixir
def change do
  create table(:ingredient_decisions, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all), null: false
    add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
    add :ingredient_index, :integer, null: false
    add :selected_canonical_id, :binary_id, null: false
    add :selected_name, :string

    timestamps()
  end

  create unique_index(:ingredient_decisions, [:recipe_id, :user_id, :ingredient_index])
  create index(:ingredient_decisions, [:user_id])
end
```

