# Parse Diagnostics Visualization

## Problem

When ingredient parsing goes wrong, it's hard to understand why. Users and developers need visibility into:
- How the ingredient was tokenized
- What labels were assigned
- Which parser handled it
- What canonical matches were considered
- Why a particular match was chosen

## Current State

No diagnostic information is captured or displayed. Debugging requires running the parser manually with test inputs.

---

## Proposed Solution

### ParseDiagnostics Struct

```elixir
defmodule Controlcopypasta.Ingredients.ParseDiagnostics do
  defstruct [
    :tokens,              # List of %Token{text, label, position}
    :token_string,        # Formatted: "[1:qty] [cup:unit] [flour:word]"
    :parser_used,         # :standard | :garlic | :citrus | :egg | :recipe_ref
    :transformations,     # List of applied transforms
    :match_candidates,    # Top 3 canonical matches considered
    :selected_match,      # The chosen match with reason
    :confidence_factors,  # What affected confidence score
    :warnings,            # Any parsing anomalies
    :parse_time_us        # Microseconds to parse
  ]
end
```

### Enhanced Token Display Format

```
Original: "2 cups fresh spinach, washed and dried"

Tokens:
┌────────┬──────────┬──────────┐
│ Token  │ Label    │ Position │
├────────┼──────────┼──────────┤
│ 2      │ qty      │ 0        │
│ cups   │ unit     │ 1        │
│ fresh  │ mod      │ 2        │
│ spinach│ word     │ 3        │
│ ,      │ punct    │ 4        │
│ washed │ prep     │ 5        │
│ and    │ conj     │ 6        │
│ dried  │ prep     │ 7        │
└────────┴──────────┴──────────┘

Parser: standard
Transformations: [singularize: false, strip_modifiers: true]
```

### Match Candidates Display

```
Match Candidates:
┌────────────────┬────────────────┬────────────┬─────────────────────────┐
│ Candidate      │ Match Type     │ Confidence │ Reason                  │
├────────────────┼────────────────┼────────────┼─────────────────────────┤
│ spinach ✓      │ exact          │ 1.00       │ Direct name match       │
│ baby spinach   │ partial        │ 0.85       │ Contains "spinach"      │
│ spinach leaves │ partial        │ 0.82       │ Contains "spinach"      │
└────────────────┴────────────────┴────────────┴─────────────────────────┘

Selected: spinach (confidence: 1.00)
```

---

## Diagnostic Capture in Parser

```elixir
def parse(text, opts \\ []) when is_binary(text) do
  start_time = System.monotonic_time(:microsecond)

  tokens = Tokenizer.tokenize(text)
  lookup = Keyword.get_lazy(opts, :lookup, fn -> Ingredients.build_ingredient_lookup() end)
  include_diagnostics = Keyword.get(opts, :diagnostics, false)

  {result, parser_used} = case try_sub_parsers(tokens, text, lookup) do
    {:ok, parsed, parser} -> {parsed, parser}
    :skip -> {parse_standard(tokens, text, lookup), :standard}
  end

  if include_diagnostics do
    diagnostics = build_diagnostics(tokens, parser_used, result, start_time)
    %{result | diagnostics: diagnostics}
  else
    result
  end
end

defp build_diagnostics(tokens, parser_used, result, start_time) do
  %ParseDiagnostics{
    tokens: tokens,
    token_string: Tokenizer.format(tokens),
    parser_used: parser_used,
    transformations: get_transformations(result),
    match_candidates: get_match_candidates(result),
    selected_match: summarize_match(result.primary_ingredient),
    confidence_factors: explain_confidence(result),
    warnings: detect_warnings(tokens, result),
    parse_time_us: System.monotonic_time(:microsecond) - start_time
  }
end
```

---

## Store Diagnostics in JSONB (Optional)

```elixir
%{
  "text" => "2 cups fresh spinach, washed and dried",
  "canonical_name" => "spinach",
  "confidence" => 1.0,
  # ... other fields ...

  "_diagnostics" => %{  # Prefixed with _ to indicate internal/debug field
    "tokens" => "[2:qty] [cups:unit] [fresh:mod] [spinach:word] [,:punct] [washed:prep] [and:conj] [dried:prep]",
    "parser" => "standard",
    "match_type" => "exact",
    "alternatives" => ["baby spinach", "spinach leaves"],
    "parse_time_us" => 234
  }
}
```

---

## Frontend: Diagnostics Table Component

```svelte
<!-- IngredientDiagnostics.svelte -->
<script>
  export let ingredients;
  let expandedIndex = null;
</script>

<details class="diagnostics-panel">
  <summary>Ingredient Parse Details ({ingredients.length} items)</summary>

  <table class="diagnostics-table">
    <thead>
      <tr>
        <th>Original Text</th>
        <th>Matched</th>
        <th>Confidence</th>
        <th>Parser</th>
        <th>Details</th>
      </tr>
    </thead>
    <tbody>
      {#each ingredients as ing, i}
        <tr class:low-confidence={ing.confidence < 0.8}>
          <td class="original-text">{ing.text}</td>
          <td class="matched-name">
            {#if ing.canonical_name}
              {ing.canonical_name}
            {:else}
              <span class="unmatched">No match</span>
            {/if}
          </td>
          <td class="confidence">
            <span class="confidence-bar" style="--width: {ing.confidence * 100}%">
              {(ing.confidence * 100).toFixed(0)}%
            </span>
          </td>
          <td class="parser-used">{ing._diagnostics?.parser || 'standard'}</td>
          <td>
            <button on:click={() => expandedIndex = expandedIndex === i ? null : i}>
              {expandedIndex === i ? '−' : '+'}
            </button>
          </td>
        </tr>

        {#if expandedIndex === i && ing._diagnostics}
          <tr class="diagnostics-detail">
            <td colspan="5">
              <div class="token-display">
                <strong>Tokens:</strong>
                <code>{ing._diagnostics.tokens}</code>
              </div>

              {#if ing._diagnostics.alternatives?.length}
                <div class="alternatives">
                  <strong>Other candidates:</strong>
                  {ing._diagnostics.alternatives.join(', ')}
                </div>
              {/if}

              {#if ing._diagnostics.warnings?.length}
                <div class="warnings">
                  {#each ing._diagnostics.warnings as warning}
                    <span class="warning-badge">{warning}</span>
                  {/each}
                </div>
              {/if}

              <div class="parse-time">
                Parsed in {ing._diagnostics.parse_time_us}μs
              </div>
            </td>
          </tr>
        {/if}
      {/each}
    </tbody>
  </table>
</details>

<style>
  .diagnostics-panel {
    margin-top: 2rem;
    border: 1px solid var(--border-light);
    border-radius: var(--radius-md);
  }

  .diagnostics-panel summary {
    padding: 1rem;
    cursor: pointer;
    background: var(--bg-surface);
    font-weight: 500;
  }

  .diagnostics-table {
    width: 100%;
    font-size: 0.875rem;
  }

  .low-confidence {
    background: rgba(255, 200, 0, 0.1);
  }

  .confidence-bar {
    display: inline-block;
    background: linear-gradient(to right,
      var(--color-basil-500) var(--width),
      var(--border-light) var(--width));
    padding: 0.25rem 0.5rem;
    border-radius: var(--radius-sm);
  }

  .unmatched {
    color: var(--color-marinara-600);
    font-style: italic;
  }

  .diagnostics-detail td {
    background: var(--bg-surface);
    padding: 1rem;
  }

  .token-display code {
    background: var(--bg-card);
    padding: 0.5rem;
    display: block;
    overflow-x: auto;
    font-family: monospace;
  }

  .warning-badge {
    background: var(--color-pasta-100);
    color: var(--color-pasta-700);
    padding: 0.25rem 0.5rem;
    border-radius: var(--radius-sm);
    font-size: 0.75rem;
  }
</style>
```

---

## Page Integration

Add to recipe pages (collapsible, bottom of page):

```svelte
<!-- recipes/[id]/+page.svelte -->
{#if recipe.ingredients?.some(i => i._diagnostics)}
  <IngredientDiagnostics ingredients={recipe.ingredients} />
{/if}
```

```svelte
<!-- browse/[domain]/[id]/+page.svelte -->
{#if recipe.ingredients?.some(i => i._diagnostics)}
  <IngredientDiagnostics ingredients={recipe.ingredients} />
{/if}
```

---

## Enable Diagnostics via Config/Admin

```elixir
# config/config.exs
config :controlcopypasta, :parsing,
  include_diagnostics: false  # Default off for performance

# Or per-request via admin toggle
```

---

## API Endpoint

```elixir
# Get recipe with diagnostics
GET /api/recipes/:id?include_diagnostics=true
```

