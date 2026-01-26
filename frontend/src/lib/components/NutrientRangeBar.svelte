<script lang="ts">
  import type { NutrientRange } from '$lib/api/client';

  interface Props {
    range: NutrientRange;
    unit: string;
    label: string;
    maxValue?: number;
    showConfidence?: boolean;
  }

  let { range, unit, label, maxValue, showConfidence = false }: Props = $props();

  // Calculate percentages for positioning
  const scale = $derived(maxValue || (range.max ? range.max * 1.3 : 100));

  const minPct = $derived(range.min !== null ? Math.max(0, (range.min / scale) * 100) : 0);
  const bestPct = $derived(range.best !== null ? Math.max(0, (range.best / scale) * 100) : 0);
  const maxPct = $derived(range.max !== null ? Math.min(100, (range.max / scale) * 100) : 0);
  const rangePct = $derived(maxPct - minPct);

  // Format the value for display
  const formattedValue = $derived(
    range.best !== null ? (range.best >= 100 ? Math.round(range.best) : range.best.toFixed(1)) : '—'
  );

  // Check if there's meaningful variation
  const hasRange = $derived(
    range.min !== null && range.max !== null && range.min !== range.max
  );

  // Confidence affects opacity
  const confidenceOpacity = $derived(0.3 + (range.confidence * 0.7));
</script>

<div class="nutrient-range">
  <div class="label-row">
    <span class="label">{label}</span>
    <span class="value">
      {formattedValue}{unit}
      {#if hasRange && range.min !== null && range.max !== null}
        <span class="range-text">
          ({range.min >= 100 ? Math.round(range.min) : range.min.toFixed(1)}–{range.max >= 100 ? Math.round(range.max) : range.max.toFixed(1)})
        </span>
      {/if}
    </span>
  </div>

  <div class="bar-container">
    {#if hasRange}
      <!-- Range bar showing min to max -->
      <div
        class="range-bar"
        style="left: {minPct}%; width: {rangePct}%; opacity: {confidenceOpacity};"
      ></div>
    {/if}

    {#if range.best !== null}
      <!-- Best estimate dot -->
      <div
        class="best-dot"
        style="left: {bestPct}%;"
        title="Best estimate: {formattedValue}{unit}"
      ></div>
    {/if}
  </div>

  {#if showConfidence}
    <div class="confidence">
      <span class="confidence-label">Confidence:</span>
      <span class="confidence-value">{Math.round(range.confidence * 100)}%</span>
    </div>
  {/if}
</div>

<style>
  .nutrient-range {
    margin-bottom: 0.75rem;
  }

  .label-row {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    margin-bottom: 0.25rem;
    font-size: 0.875rem;
  }

  .label {
    font-weight: 500;
    color: var(--color-text, #333);
  }

  .value {
    font-weight: 600;
    color: var(--color-text, #333);
  }

  .range-text {
    font-weight: 400;
    font-size: 0.75rem;
    color: var(--color-text-secondary, #666);
    margin-left: 0.25rem;
  }

  .bar-container {
    position: relative;
    height: 16px;
    background: var(--color-bg-secondary, #f0f0f0);
    border-radius: 8px;
    overflow: hidden;
  }

  .range-bar {
    position: absolute;
    height: 100%;
    background: var(--color-success-light, #90c090);
    border-radius: 8px;
    transition: all 0.2s ease;
  }

  .best-dot {
    position: absolute;
    width: 10px;
    height: 10px;
    background: var(--color-success, #2d5a2d);
    border-radius: 50%;
    top: 50%;
    transform: translate(-50%, -50%);
    border: 2px solid white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
    z-index: 1;
  }

  .confidence {
    display: flex;
    justify-content: flex-end;
    gap: 0.25rem;
    margin-top: 0.25rem;
    font-size: 0.7rem;
  }

  .confidence-label {
    color: var(--color-text-secondary, #888);
  }

  .confidence-value {
    color: var(--color-text-secondary, #666);
    font-weight: 500;
  }

  /* Print styles */
  @media print {
    .bar-container {
      border: 1px solid #ccc;
      background: #fff;
    }

    .range-bar {
      background: #ddd;
    }

    .best-dot {
      background: #333;
    }
  }
</style>
