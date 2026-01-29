<script lang="ts">
	import type { Ingredient, IngredientDecision } from '$lib/api/client';

	interface Props {
		ingredient: Ingredient;
		index: number;
		currentDecision?: IngredientDecision | null;
		ondecide?: (detail: {
			ingredientIndex: number;
			selectedId: string;
			selectedName: string;
		}) => void;
	}

	let { ingredient, index, currentDecision = null, ondecide }: Props = $props();

	interface Option {
		id: string | null;
		name: string | null;
		isPrimary: boolean;
		nutritionDiff?: {
			calories?: number;
			fat_total_g?: number;
			fat_saturated_g?: number;
			carbohydrates_g?: number;
			protein_g?: number;
		};
	}

	const options = $derived.by(() => {
		const opts: Option[] = [
			{
				id: ingredient.canonical_id ?? null,
				name: ingredient.canonical_name ?? null,
				isPrimary: true
			}
		];

		if (ingredient.alternatives) {
			for (const alt of ingredient.alternatives) {
				opts.push({
					id: alt.canonical_id,
					name: alt.canonical_name,
					isPrimary: false,
					nutritionDiff: alt.nutrition_diff
				});
			}
		}

		return opts;
	});

	const selectedId = $derived(currentDecision?.selected_canonical_id ?? ingredient.canonical_id);

	function selectOption(option: Option) {
		if (option.id && option.name && ondecide) {
			ondecide({
				ingredientIndex: index,
				selectedId: option.id,
				selectedName: option.name
			});
		}
	}

	function formatCalorieDiff(diff: number | undefined): string {
		if (diff === undefined || diff === 0) return '';
		return diff > 0 ? `+${diff}` : `${diff}`;
	}
</script>

{#if ingredient.is_alternative && ingredient.alternatives && ingredient.alternatives.length > 0}
	<div class="decision-selector">
		<span class="decision-label">Choose:</span>
		<div class="decision-options">
			{#each options as option}
				{#if option.id && option.name}
					<button
						class="decision-option"
						class:selected={selectedId === option.id}
						onclick={() => selectOption(option)}
					>
						<span class="option-name">{option.name}</span>
						{#if option.nutritionDiff?.calories && selectedId !== option.id}
							<span class="nutrition-hint">
								{formatCalorieDiff(option.nutritionDiff.calories)} cal
							</span>
						{/if}
						{#if option.isPrimary}
							<span class="primary-badge">default</span>
						{/if}
					</button>
				{/if}
			{/each}
		</div>
	</div>
{/if}

<style>
	.decision-selector {
		margin: var(--space-2) 0;
		padding: var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		border-left: 3px solid var(--color-pasta-400);
	}

	.decision-label {
		font-size: var(--text-xs);
		color: var(--text-muted);
		text-transform: uppercase;
		letter-spacing: 0.05em;
	}

	.decision-options {
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
		margin-top: var(--space-2);
	}

	.decision-option {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-2) var(--space-3);
		border: 1px solid var(--border-default);
		border-radius: var(--radius-md);
		background: var(--bg-card);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all 0.15s ease;
	}

	.decision-option:hover {
		border-color: var(--color-basil-400);
		background: var(--color-basil-50);
	}

	.decision-option.selected {
		border-color: var(--color-basil-500);
		background: var(--color-basil-100);
		font-weight: var(--font-medium);
	}

	.option-name {
		text-transform: capitalize;
	}

	.nutrition-hint {
		font-size: var(--text-xs);
		color: var(--text-muted);
		padding: 2px var(--space-2);
		background: var(--bg-surface);
		border-radius: var(--radius-sm);
	}

	.primary-badge {
		font-size: 10px;
		color: var(--text-muted);
		text-transform: uppercase;
	}

	/* Don't show in print */
	@media print {
		.decision-selector {
			display: none;
		}
	}
</style>
