# Nested/Child Recipes

## Problem

Ingredients often reference other recipes:
- "1 cup Homemade Marinara Sauce (see recipe below)"
- "2 cups chicken stock (recipe follows)"
- "1/2 cup pesto, homemade or store-bought"
- "For the spice blend, see notes"

Currently these patterns are detected as `:note` tokens but not structured. The referenced recipe exists in the same page but isn't linked.

## Current State

The Tokenizer already detects these patterns (tokenizer.ex lines 93-103):
```elixir
@note_phrases [
  "recipe above", "from above",
  "recipe below", "recipe follows", "homemade recipe below",
  # ...
]
```

But they're discarded as notes, not captured as recipe references.

---

## Proposed Solution

### RecipeReference Schema

```elixir
# lib/controlcopypasta/recipes/recipe_reference.ex
defmodule Controlcopypasta.Recipes.RecipeReference do
  use Ecto.Schema
  
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "recipe_references" do
    belongs_to :parent_recipe, Recipe      # The recipe containing the ingredient
    belongs_to :child_recipe, Recipe       # The referenced sub-recipe (nullable until resolved)
    
    field :ingredient_index, :integer      # Which ingredient line contains the reference
    field :reference_type, :string         # "below", "above", "notes", "link", "inline"
    field :reference_text, :string         # Original text: "see recipe below"
    field :extracted_name, :string         # Parsed name: "Homemade Marinara Sauce"
    field :resolved_at, :utc_datetime      # When child_recipe was linked
    field :is_optional, :boolean           # "homemade or store-bought" = optional
    
    timestamps()
  end
end
```

### Enhanced ParsedIngredient

```elixir
defstruct [
  # ... existing fields ...
  :recipe_reference,  # NEW: %{type: :below, name: "marinara sauce", text: "see recipe below"}
]
```

### Reference Detection Patterns

| Pattern | Type | Example |
|---------|------|---------|
| "see recipe below" | `:below` | "1 cup pesto (see recipe below)" |
| "recipe follows" | `:below` | "chicken stock, recipe follows" |
| "see recipe above" | `:above` | "use the spice blend (recipe above)" |
| "see notes" / "in notes" | `:notes` | "1 tbsp spice mix (see notes)" |
| "homemade" + "(recipe...)" | `:inline` | "homemade mayo (recipe on page 42)" |
| URL pattern | `:link` | "salsa verde (https://...)" |
| "or store-bought" | `:optional` | Flag as optional, not required sub-recipe |

---

## Sub-Recipe Parser

```elixir
# lib/controlcopypasta/ingredients/sub_parsers/recipe_reference.ex
defmodule SubParsers.RecipeReference do
  @behaviour SubParser
  
  @reference_patterns [
    ~r/\b(?:see\s+)?recipe\s+(below|above|follows)\b/i,
    ~r/\b(?:see\s+)?notes?\b/i,
    ~r/\bhomemade\s+recipe\b/i,
    ~r/\(recipe\s+(?:below|above|on\s+page)\)/i
  ]
  
  def match?(tokens) do
    # Check for recipe reference patterns in token text
  end
  
  def parse(tokens, original, lookup) do
    # Extract: ingredient name, reference type, optional flag
    # Return: {:ok, %ParsedIngredient{recipe_reference: %{...}}}
  end
end
```

---

## Resolution Flow

```
Scrape Recipe Page
       ↓
Parse Ingredients → Detect "see recipe below" → Store reference
       ↓
Parse Page Sections → Find sub-recipe blocks (h2/h3 with ingredients)
       ↓
Create Child Recipe Records
       ↓
Link parent.recipe_references[n].child_recipe_id = child.id
```

---

## Frontend Display

```svelte
<!-- In ingredient list -->
{#if ingredient.recipe_reference}
  <span class="ingredient-text">{ingredient.text}</span>
  {#if ingredient.recipe_reference.child_recipe_id}
    <a href="#sub-recipe-{ingredient.recipe_reference.child_recipe_id}" 
       class="recipe-link">
      Jump to recipe ↓
    </a>
  {:else}
    <span class="unresolved-reference">(recipe not found)</span>
  {/if}
{/if}
```

---

## Migration

```elixir
def change do
  create table(:recipe_references, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :parent_recipe_id, references(:recipes, type: :binary_id, on_delete: :delete_all)
    add :child_recipe_id, references(:recipes, type: :binary_id, on_delete: :nilify_all)
    add :ingredient_index, :integer
    add :reference_type, :string  # below, above, notes, link, inline
    add :reference_text, :string
    add :extracted_name, :string
    add :resolved_at, :utc_datetime
    add :is_optional, :boolean, default: false
    timestamps()
  end
  
  create index(:recipe_references, [:parent_recipe_id])
  create index(:recipe_references, [:child_recipe_id])
end
```

---

## API Endpoints

```elixir
# Get sub-recipes for a recipe
GET /api/recipes/:id/sub-recipes
{
  "sub_recipes": [
    {
      "ingredient_index": 3,
      "reference_text": "see recipe below",
      "child_recipe": { ... }  # Full recipe object
    }
  ]
}
```

---

## Test Cases

```elixir
test_cases = [
  {"1 cup pesto (see recipe below)", %{type: :below, name: "pesto"}},
  {"homemade mayo, recipe follows", %{type: :below, name: "mayo"}},
  {"use the spice blend (recipe above)", %{type: :above, name: "spice blend"}},
  {"1 tbsp garam masala (see notes)", %{type: :notes, name: "garam masala"}},
  {"chicken stock, homemade or store-bought", %{type: :below, optional: true}},
]
```
