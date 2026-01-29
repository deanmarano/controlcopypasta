# Pre-Steps Extraction (Mise en Place)

## Problem

Ingredients contain preparation instructions that should happen before cooking:
- "1 lb carrots, peeled and diced"
- "4 cloves garlic, minced"
- "2 cups chicken, cooked and shredded"
- "1 onion, finely chopped"

These are buried in ingredient text. Users would benefit from a "Prep List" showing all prep work before starting the recipe.

## Current State

Preparations ARE extracted and stored:
```elixir
%{
  "preparations" => ["diced", "drained"],
  "modifiers" => ["firmly", "packed"]
}
```

But they're just string lists, not actionable instructions.

---

## Proposed Solution

### PreStep Structure (Embedded in JSONB)

```elixir
%{
  "pre_steps" => [
    %{
      "action" => "dice",           # Normalized verb
      "target" => "carrots",        # What to prep
      "modifier" => "1/4 inch",     # Size/style if specified
      "category" => "cut",          # cut, cook, temperature, process
      "estimated_time_min" => 5,    # Optional time estimate
      "tool" => "knife",            # Optional tool needed
      "order_hint" => 1             # Suggested prep order (longer items first)
    }
  ]
}
```

### Preparation Classification

Expand `Preparation` module with metadata:

```elixir
@preparations_with_metadata %{
  # Cutting
  "diced" => %{verb: "dice", category: :cut, tool: "knife", time_per_cup: 2},
  "minced" => %{verb: "mince", category: :cut, tool: "knife", time_per_cup: 3},
  "julienned" => %{verb: "julienne", category: :cut, tool: "knife", time_per_cup: 5},
  "chopped" => %{verb: "chop", category: :cut, tool: "knife", time_per_cup: 1},
  "sliced" => %{verb: "slice", category: :cut, tool: "knife", time_per_cup: 1},
  "grated" => %{verb: "grate", category: :cut, tool: "grater", time_per_cup: 2},
  "shredded" => %{verb: "shred", category: :cut, tool: "grater", time_per_cup: 3},
  
  # Temperature/State
  "room temperature" => %{verb: "bring to room temperature", category: :temperature, time_min: 30},
  "softened" => %{verb: "soften", category: :temperature, time_min: 30},
  "melted" => %{verb: "melt", category: :temperature, time_min: 2},
  "chilled" => %{verb: "chill", category: :temperature, time_min: 60},
  "thawed" => %{verb: "thaw", category: :temperature, time_min: 120},
  
  # Pre-cooking
  "cooked" => %{verb: "cook", category: :cook, time_min: 15},
  "toasted" => %{verb: "toast", category: :cook, time_min: 5},
  "roasted" => %{verb: "roast", category: :cook, time_min: 30},
  "blanched" => %{verb: "blanch", category: :cook, time_min: 3},
  
  # Processing
  "drained" => %{verb: "drain", category: :process, time_min: 1},
  "rinsed" => %{verb: "rinse", category: :process, time_min: 1},
  "soaked" => %{verb: "soak", category: :process, time_min: 30},
  "dried" => %{verb: "dry", category: :process, time_min: 5},
  "peeled" => %{verb: "peel", category: :process, time_per_item: 0.5},
  "seeded" => %{verb: "seed", category: :process, time_per_item: 1},
  "cored" => %{verb: "core", category: :process, time_per_item: 0.5}
}
```

---

## PreStep Generator

```elixir
defmodule Controlcopypasta.Ingredients.PreStepGenerator do
  @moduledoc """
  Converts parsed preparations into actionable pre-steps.
  """
  
  def generate_pre_steps(parsed_ingredient) do
    parsed_ingredient.preparations
    |> Enum.map(&prep_to_step(&1, parsed_ingredient))
    |> Enum.reject(&is_nil/1)
    |> assign_order_hints()
  end
  
  defp prep_to_step(prep, ingredient) do
    case Map.get(@preparations_with_metadata, prep) do
      nil -> nil
      meta ->
        %{
          action: meta.verb,
          target: ingredient.primary_ingredient.canonical_name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: meta.category,
          estimated_time_min: estimate_time(meta, ingredient),
          tool: meta[:tool],
          original_prep: prep
        }
    end
  end
  
  # Order: temperature first (need time), then cook, then cut (can do while cooking)
  defp assign_order_hints(steps) do
    steps
    |> Enum.sort_by(fn step ->
      case step.category do
        :temperature -> 0  # Room temp butter, thaw frozen items
        :cook -> 1         # Pre-cook components
        :process -> 2      # Drain, rinse, soak
        :cut -> 3          # Chopping can happen during cooking
        _ -> 4
      end
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {step, idx} -> Map.put(step, :order_hint, idx) end)
  end
end
```

---

## Aggregate Pre-Steps for Recipe

```elixir
defmodule Controlcopypasta.Recipes.PrepList do
  @moduledoc """
  Generates a consolidated prep list from all recipe ingredients.
  """
  
  def generate(recipe) do
    recipe.ingredients
    |> Enum.flat_map(&PreStepGenerator.generate_pre_steps/1)
    |> group_by_category()
    |> sort_by_time_descending()  # Longest prep first
    |> deduplicate_similar()       # Combine "dice onion" if appears twice
  end
  
  def format_as_checklist(prep_list) do
    # Generate markdown or structured checklist
    # "□ Bring 4 tbsp butter to room temperature (30 min)"
    # "□ Dice 2 cups carrots (5 min)"
  end
  
  def total_prep_time(prep_list) do
    # Sum estimated times, accounting for parallel work
  end
end
```

---

## Frontend: Prep List Component

```svelte
<!-- PrepList.svelte -->
<script>
  export let recipe;
  let showPrepList = false;
  
  $: prepSteps = generatePrepList(recipe.ingredients);
  $: totalTime = estimateTotalTime(prepSteps);
</script>

{#if prepSteps.length > 0}
  <div class="prep-list-toggle">
    <button on:click={() => showPrepList = !showPrepList}>
      {showPrepList ? 'Hide' : 'Show'} Prep List 
      <span class="prep-time">~{totalTime} min</span>
    </button>
  </div>
  
  {#if showPrepList}
    <div class="prep-list">
      <h3>Before You Start</h3>
      
      {#each Object.entries(groupByCategory(prepSteps)) as [category, steps]}
        <div class="prep-category">
          <h4>{categoryLabel(category)}</h4>
          <ul>
            {#each steps as step}
              <li class="prep-step">
                <input type="checkbox" id="prep-{step.id}" />
                <label for="prep-{step.id}">
                  <span class="action">{step.action}</span>
                  <span class="target">{step.quantity} {step.unit} {step.target}</span>
                  {#if step.estimated_time_min}
                    <span class="time">~{step.estimated_time_min} min</span>
                  {/if}
                </label>
              </li>
            {/each}
          </ul>
        </div>
      {/each}
    </div>
  {/if}
{/if}

<style>
  .prep-list {
    background: var(--bg-surface);
    border-radius: var(--radius-md);
    padding: 1rem;
    margin: 1rem 0;
  }
  
  .prep-category h4 {
    color: var(--text-secondary);
    font-size: 0.875rem;
    text-transform: uppercase;
    margin: 1rem 0 0.5rem;
  }
  
  .prep-step {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.25rem 0;
  }
  
  .prep-step input:checked + label {
    text-decoration: line-through;
    color: var(--text-muted);
  }
  
  .time {
    color: var(--text-muted);
    font-size: 0.75rem;
  }
</style>
```

---

## Updated JSONB Structure

```elixir
%{
  "text" => "2 cups carrots, peeled and diced",
  "canonical_name" => "carrot",
  "preparations" => ["peeled", "diced"],
  "pre_steps" => [
    %{
      "action" => "peel",
      "target" => "carrot",
      "category" => "process",
      "estimated_time_min" => 2
    },
    %{
      "action" => "dice",
      "target" => "carrot", 
      "category" => "cut",
      "estimated_time_min" => 4,
      "tool" => "knife"
    }
  ]
}
```

---

## API Endpoints

```elixir
# Get prep list for a recipe
GET /api/recipes/:id/prep-list
{
  "prep_steps": [...],
  "total_estimated_time_min": 25,
  "categories": {
    "temperature": [...],
    "cut": [...],
    "process": [...]
  }
}
```
