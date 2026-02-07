<script lang="ts">
	import type { Ingredient, PreStep } from '$lib/api/client';

	interface Props {
		ingredients: Ingredient[];
		expanded?: boolean;
	}

	let { ingredients, expanded: initialExpanded = false }: Props = $props();
	let showPrepList = $state(initialExpanded);
	let checkedSteps = $state<Set<string>>(new Set());

	const categoryLabels: Record<string, string> = {
		temperature: 'Temperature Prep',
		cook: 'Pre-cooking',
		process: 'Processing',
		cut: 'Cutting & Chopping',
		other: 'Other Prep'
	};

	const categoryOrder = ['temperature', 'cook', 'process', 'cut', 'other'];

	// Extract and deduplicate pre_steps from all ingredients
	const allSteps = $derived.by(() => {
		const steps: PreStep[] = [];
		for (const ing of ingredients) {
			if (ing.pre_steps) {
				steps.push(...ing.pre_steps);
			}
		}
		return deduplicateSteps(steps);
	});

	// Group steps by category
	const stepsByCategory = $derived.by(() => {
		const grouped: Record<string, PreStep[]> = {};
		for (const step of allSteps) {
			const cat = step.category || 'other';
			if (!grouped[cat]) grouped[cat] = [];
			grouped[cat].push(step);
		}
		return grouped;
	});

	// Calculate total time
	const totalTime = $derived(
		allSteps.reduce((sum, step) => sum + (step.estimated_time_min || 0), 0)
	);

	// Calculate parallel time (temperature can happen while other work is done)
	const parallelTime = $derived.by(() => {
		const tempTime = Math.max(
			...(stepsByCategory.temperature || []).map((s) => s.estimated_time_min || 0),
			0
		);
		const otherTime = categoryOrder
			.filter((c) => c !== 'temperature')
			.flatMap((c) => stepsByCategory[c] || [])
			.reduce((sum, s) => sum + (s.estimated_time_min || 0), 0);
		return Math.max(tempTime, otherTime);
	});

	function deduplicateSteps(steps: PreStep[]): PreStep[] {
		const seen = new Map<string, PreStep>();
		for (const step of steps) {
			const key = `${step.action}-${step.target}`;
			const existing = seen.get(key);
			if (existing) {
				// Merge quantities
				if (existing.quantity && step.quantity && existing.unit === step.unit) {
					existing.quantity += step.quantity;
					// Recalculate time estimate
					if (existing.estimated_time_min && step.estimated_time_min) {
						existing.estimated_time_min += step.estimated_time_min;
					}
				}
			} else {
				seen.set(key, { ...step });
			}
		}
		return Array.from(seen.values()).sort((a, b) => (a.order_hint || 99) - (b.order_hint || 99));
	}

	function getStepId(step: PreStep, index: number): string {
		return `prep-${step.action}-${step.target}-${index}`;
	}

	function toggleStep(stepId: string) {
		if (checkedSteps.has(stepId)) {
			checkedSteps.delete(stepId);
		} else {
			checkedSteps.add(stepId);
		}
		checkedSteps = new Set(checkedSteps);
	}

	function formatQuantity(qty: number | null, unit: string | null): string {
		if (!qty) return '';
		const qtyStr = formatNumber(qty);
		return unit ? `${qtyStr} ${unit} ` : `${qtyStr} `;
	}

	function formatNumber(num: number): string {
		// Convert to nice Unicode fractions for common values
		const fractions: [number, string][] = [
			[0.125, '⅛'],
			[0.2, '⅕'],
			[0.25, '¼'],
			[0.333, '⅓'],
			[0.375, '⅜'],
			[0.4, '⅖'],
			[0.5, '½'],
			[0.6, '⅗'],
			[0.625, '⅝'],
			[0.667, '⅔'],
			[0.75, '¾'],
			[0.8, '⅘'],
			[0.833, '⅚'],
			[0.875, '⅞']
		];

		const whole = Math.floor(num);
		const frac = num - whole;

		// Check if the fractional part is close to a common fraction
		for (const [val, str] of fractions) {
			if (Math.abs(frac - val) < 0.03) {
				return whole > 0 ? `${whole}${str}` : str;
			}
		}

		// Check for very small fractional part (essentially whole number)
		if (frac < 0.03) {
			return whole.toString();
		}

		// Otherwise, round to 1 decimal place
		return Number.isInteger(num) ? num.toString() : num.toFixed(1);
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes >= 60) {
			const hrs = Math.floor(minutes / 60);
			const mins = minutes % 60;
			return mins > 0 ? `${hrs}h ${mins}m` : `${hrs}h`;
		}
		return `${minutes}m`;
	}
</script>

{#if allSteps.length > 0}
	<div class="prep-list-container" class:expanded={initialExpanded}>
		{#if !initialExpanded}
			<button class="prep-list-toggle" onclick={() => (showPrepList = !showPrepList)}>
				<span class="toggle-icon">{showPrepList ? '−' : '+'}</span>
				<span class="toggle-text">{showPrepList ? 'Hide' : 'Show'} Prep List</span>
				{#if totalTime > 0}
					<span class="prep-time">
						~{formatTime(parallelTime)}
						{#if parallelTime !== totalTime}
							<span class="time-note">(sequential: {formatTime(totalTime)})</span>
						{/if}
					</span>
				{/if}
			</button>
		{:else if totalTime > 0}
			<div class="prep-time-summary">
				Estimated time: ~{formatTime(parallelTime)}
				{#if parallelTime !== totalTime}
					<span class="time-note">(sequential: {formatTime(totalTime)})</span>
				{/if}
			</div>
		{/if}

		{#if showPrepList}
			<div class="prep-list">
				<h3>Before You Start</h3>

				{#each categoryOrder as category}
					{#if stepsByCategory[category]?.length}
						<div class="prep-category">
							<h4>{categoryLabels[category]}</h4>
							<ul>
								{#each stepsByCategory[category] as step, i}
									{@const stepId = getStepId(step, i)}
									<li class="prep-step" class:checked={checkedSteps.has(stepId)}>
										<input
											type="checkbox"
											id={stepId}
											checked={checkedSteps.has(stepId)}
											onchange={() => toggleStep(stepId)}
										/>
										<label for={stepId}>
											<span class="action">{step.action}</span>
											<span class="target">
												{formatQuantity(step.quantity, step.unit)}{step.target || 'ingredient'}
											</span>
											{#if step.tool}
												<span class="tool">({step.tool})</span>
											{/if}
											{#if step.estimated_time_min}
												<span class="time">~{formatTime(step.estimated_time_min)}</span>
											{/if}
										</label>
									</li>
								{/each}
							</ul>
						</div>
					{/if}
				{/each}
			</div>
		{/if}
	</div>
{/if}

<style>
	.prep-list-container {
		margin: var(--space-4) 0;
	}

	.prep-list-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-3) var(--space-4);
		background: var(--bg-surface);
		border: 1px solid var(--border-light);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		width: 100%;
		text-align: left;
		transition: background-color 0.15s ease;
	}

	.prep-list-toggle:hover {
		background: var(--bg-surface-hover, var(--bg-surface));
	}

	.toggle-icon {
		font-size: var(--text-lg);
		font-weight: var(--font-bold);
		color: var(--text-secondary);
		width: 1.5em;
		text-align: center;
	}

	.toggle-text {
		flex: 1;
	}

	.prep-time {
		color: var(--color-basil-600);
		font-weight: var(--font-medium);
	}

	.time-note {
		color: var(--text-muted);
		font-size: var(--text-xs);
		font-weight: var(--font-normal);
	}

	.prep-list {
		background: var(--bg-surface);
		border: 1px solid var(--border-light);
		border-top: none;
		border-radius: 0 0 var(--radius-md) var(--radius-md);
		padding: var(--space-4);
	}

	.prep-list h3 {
		font-size: var(--text-base);
		font-weight: var(--font-semibold);
		margin: 0 0 var(--space-4);
		color: var(--text-primary);
	}

	.prep-category {
		margin-bottom: var(--space-4);
	}

	.prep-category:last-child {
		margin-bottom: 0;
	}

	.prep-category h4 {
		color: var(--text-secondary);
		font-size: var(--text-xs);
		text-transform: uppercase;
		letter-spacing: 0.05em;
		margin: 0 0 var(--space-2);
		font-weight: var(--font-medium);
	}

	.prep-category ul {
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.prep-step {
		display: flex;
		align-items: flex-start;
		gap: var(--space-2);
		padding: var(--space-2) 0;
		border-bottom: 1px solid var(--border-light);
	}

	.prep-step:last-child {
		border-bottom: none;
	}

	.prep-step input[type='checkbox'] {
		margin-top: 2px;
		cursor: pointer;
	}

	.prep-step label {
		flex: 1;
		cursor: pointer;
		font-size: var(--text-sm);
		line-height: 1.4;
	}

	.prep-step.checked label {
		text-decoration: line-through;
		color: var(--text-muted);
	}

	.action {
		font-weight: var(--font-medium);
		text-transform: capitalize;
	}

	.target {
		color: var(--text-secondary);
	}

	.tool {
		color: var(--text-muted);
		font-size: var(--text-xs);
	}

	.time {
		color: var(--text-muted);
		font-size: var(--text-xs);
		margin-left: var(--space-2);
	}

	/* Expanded state (used in split view) */
	.prep-list-container.expanded {
		margin: 0;
	}

	.prep-list-container.expanded .prep-list {
		border: none;
		border-radius: 0;
		padding: 0;
		background: transparent;
	}

	.prep-time-summary {
		font-size: var(--text-sm);
		color: var(--color-basil-600);
		font-weight: var(--font-medium);
		margin-bottom: var(--space-3);
	}

	.prep-time-summary .time-note {
		color: var(--text-muted);
		font-size: var(--text-xs);
		font-weight: var(--font-normal);
	}

	/* Print styles - show prep list when printing */
	@media print {
		.prep-list-toggle {
			display: none;
		}

		.prep-list {
			border: 1px solid var(--border-light);
			border-radius: var(--radius-md);
			page-break-inside: avoid;
		}

		.prep-step input[type='checkbox'] {
			/* Show empty checkbox for print */
			-webkit-appearance: none;
			appearance: none;
			width: 14px;
			height: 14px;
			border: 1px solid var(--text-secondary);
			border-radius: 2px;
			background: white;
		}
	}
</style>
