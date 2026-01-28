<script lang="ts">
	import type { RecipeNutrition, NutrientData, NutrientRange } from '$lib/api/client';
	import { getNutrientValue, isNutrientRange } from '$lib/api/client';
	import NutrientRangeBar from './NutrientRangeBar.svelte';

	interface Props {
		nutrition: RecipeNutrition | null;
		loading?: boolean;
		error?: string;
		showRangeBars?: boolean;
	}

	let { nutrition, loading = false, error = '', showRangeBars = true }: Props = $props();

	// Extract "best" value from a NutrientRange or scalar
	function getValue(value: NutrientRange | number | null): number | null {
		return getNutrientValue(value);
	}

	function formatNumber(value: NutrientRange | number | null, decimals: number = 0): string {
		const num = getValue(value);
		if (num === null || num === undefined) return '-';
		return num.toFixed(decimals);
	}

	// Format a range showing min-max if there's meaningful variation
	function formatRange(value: NutrientRange | number | null, decimals: number = 0): string {
		if (value === null) return '-';
		if (!isNutrientRange(value)) return value.toFixed(decimals);

		const range = value;
		if (range.best === null) return '-';

		// If min and max are the same (or very close), just show the single value
		if (range.min === null || range.max === null ||
		    Math.abs(range.max - range.min) < 0.5) {
			return range.best.toFixed(decimals);
		}

		const minStr = range.min.toFixed(decimals);
		const maxStr = range.max.toFixed(decimals);
		const bestStr = range.best.toFixed(decimals);

		return `${bestStr} (${minStr}-${maxStr})`;
	}

	// Get NutrientRange object from a value (converts scalars to range format)
	function toRange(value: NutrientRange | number | null): NutrientRange | null {
		if (value === null) return null;
		if (isNutrientRange(value)) return value;
		return { min: value, best: value, max: value, confidence: 1.0 };
	}

	// Check if a nutrient has meaningful range variation
	function hasRange(value: NutrientRange | number | null): boolean {
		if (value === null || !isNutrientRange(value)) return false;
		if (value.min === null || value.max === null) return false;
		return Math.abs(value.max - value.min) >= 0.5;
	}

	function getStatusColor(status: string): string {
		switch (status) {
			case 'calculated':
				return 'var(--color-basil-500)';
			case 'no_match':
			case 'no_quantity':
				return 'var(--color-marinara-500)';
			case 'no_density':
			case 'no_nutrition':
				return 'var(--color-pasta-600)';
			default:
				return 'var(--color-gray-500)';
		}
	}

	function getStatusText(status: string): string {
		switch (status) {
			case 'calculated':
				return 'Calculated';
			case 'no_match':
				return 'Not matched';
			case 'no_quantity':
				return 'No quantity';
			case 'no_density':
				return 'No density data';
			case 'no_nutrition':
				return 'No nutrition data';
			case 'error':
				return 'Error';
			default:
				return status;
		}
	}

	// Daily values for % calculation (FDA reference)
	const dailyValues: Partial<Record<keyof NutrientData, number>> = {
		calories: 2000,
		fat_total_g: 78,
		fat_saturated_g: 20,
		cholesterol_mg: 300,
		sodium_mg: 2300,
		carbohydrates_g: 275,
		fiber_g: 28,
		sugar_g: 50,
		protein_g: 50,
		vitamin_d_mcg: 20,
		calcium_mg: 1300,
		iron_mg: 18,
		potassium_mg: 4700
	};

	function getDailyPercent(key: keyof NutrientData, value: NutrientRange | number | null): string | null {
		const dv = dailyValues[key];
		const num = getValue(value);
		if (!dv || num === null) return null;
		const percent = Math.round((num / dv) * 100);
		return `${percent}%`;
	}

	// Get average confidence across all nutrient ranges
	const avgConfidence = $derived(() => {
		if (!nutrition) return 1.0;
		const nutrients = nutrition.per_serving;
		let total = 0;
		let count = 0;

		for (const key of Object.keys(nutrients) as (keyof NutrientData)[]) {
			const value = nutrients[key];
			if (isNutrientRange(value) && value.confidence !== undefined) {
				total += value.confidence;
				count++;
			}
		}

		return count > 0 ? total / count : 1.0;
	});
</script>

{#if loading}
	<div class="nutrition-loading">
		<span class="spinner"></span>
		Calculating nutrition...
	</div>
{:else if error}
	<div class="nutrition-error">{error}</div>
{:else if nutrition}
	<div class="nutrition-panel">
		{#if nutrition.warnings.length > 0}
			<div class="warnings">
				{#each nutrition.warnings as warning}
					<div class="warning">{warning}</div>
				{/each}
			</div>
		{/if}

		<div class="nutrition-layout">
			<div class="facts-column">
				<div class="nutrition-header">
					<h3>Nutrition Facts</h3>
					<div class="serving-info">
						<span class="servings">{nutrition.servings} serving{nutrition.servings !== 1 ? 's' : ''}</span>
						{#if nutrition.completeness < 1}
							<span class="completeness" title="Percentage of ingredients with nutrition data">
								{Math.round(nutrition.completeness * 100)}% calculated
							</span>
						{/if}
					</div>
				</div>

				<div class="nutrition-facts">
			<div class="calories-row">
				<span class="label">Calories</span>
				<span class="value">{formatNumber(nutrition.per_serving.calories)}</span>
				{#if hasRange(nutrition.per_serving.calories)}
					<span class="range-indicator" title="Range: {formatRange(nutrition.per_serving.calories)}">~</span>
				{/if}
			</div>

			{#if showRangeBars && toRange(nutrition.per_serving.calories)}
				{@const calRange = toRange(nutrition.per_serving.calories)}
				{#if calRange}
					<div class="calories-range-bar">
						<NutrientRangeBar range={calRange} unit="" label="" maxValue={2000} />
					</div>
				{/if}
			{/if}

			<div class="divider thick"></div>

			<div class="daily-value-header">% Daily Value*</div>

			<div class="nutrient-row">
				<span class="label bold">Total Fat</span>
				<span class="value">{formatNumber(nutrition.per_serving.fat_total_g)}g</span>
				<span class="daily">{getDailyPercent('fat_total_g', nutrition.per_serving.fat_total_g) || '-'}</span>
			</div>

			<div class="nutrient-row indent">
				<span class="label">Saturated Fat</span>
				<span class="value">{formatNumber(nutrition.per_serving.fat_saturated_g)}g</span>
				<span class="daily">{getDailyPercent('fat_saturated_g', nutrition.per_serving.fat_saturated_g) || '-'}</span>
			</div>

			<div class="nutrient-row">
				<span class="label bold">Cholesterol</span>
				<span class="value">{formatNumber(nutrition.per_serving.cholesterol_mg)}mg</span>
				<span class="daily">{getDailyPercent('cholesterol_mg', nutrition.per_serving.cholesterol_mg) || '-'}</span>
			</div>

			<div class="nutrient-row">
				<span class="label bold">Sodium</span>
				<span class="value">{formatNumber(nutrition.per_serving.sodium_mg)}mg</span>
				<span class="daily">{getDailyPercent('sodium_mg', nutrition.per_serving.sodium_mg) || '-'}</span>
			</div>

			<div class="nutrient-row">
				<span class="label bold">Total Carbohydrate</span>
				<span class="value">{formatNumber(nutrition.per_serving.carbohydrates_g)}g</span>
				<span class="daily">{getDailyPercent('carbohydrates_g', nutrition.per_serving.carbohydrates_g) || '-'}</span>
			</div>

			<div class="nutrient-row indent">
				<span class="label">Dietary Fiber</span>
				<span class="value">{formatNumber(nutrition.per_serving.fiber_g)}g</span>
				<span class="daily">{getDailyPercent('fiber_g', nutrition.per_serving.fiber_g) || '-'}</span>
			</div>

			<div class="nutrient-row indent">
				<span class="label">Total Sugars</span>
				<span class="value">{formatNumber(nutrition.per_serving.sugar_g)}g</span>
				<span class="daily"></span>
			</div>

			<div class="nutrient-row">
				<span class="label bold">Protein</span>
				<span class="value">{formatNumber(nutrition.per_serving.protein_g)}g</span>
				<span class="daily">{getDailyPercent('protein_g', nutrition.per_serving.protein_g) || '-'}</span>
			</div>

			<div class="divider thick"></div>

			<div class="vitamins-minerals">
				<div class="vitamin-row">
					<span class="label">Vitamin D</span>
					<span class="value">{formatNumber(nutrition.per_serving.vitamin_d_mcg, 1)}mcg</span>
					<span class="daily">{getDailyPercent('vitamin_d_mcg', nutrition.per_serving.vitamin_d_mcg) || '-'}</span>
				</div>
				<div class="vitamin-row">
					<span class="label">Calcium</span>
					<span class="value">{formatNumber(nutrition.per_serving.calcium_mg)}mg</span>
					<span class="daily">{getDailyPercent('calcium_mg', nutrition.per_serving.calcium_mg) || '-'}</span>
				</div>
				<div class="vitamin-row">
					<span class="label">Iron</span>
					<span class="value">{formatNumber(nutrition.per_serving.iron_mg, 1)}mg</span>
					<span class="daily">{getDailyPercent('iron_mg', nutrition.per_serving.iron_mg) || '-'}</span>
				</div>
				<div class="vitamin-row">
					<span class="label">Potassium</span>
					<span class="value">{formatNumber(nutrition.per_serving.potassium_mg)}mg</span>
					<span class="daily">{getDailyPercent('potassium_mg', nutrition.per_serving.potassium_mg) || '-'}</span>
				</div>
			</div>

			{#if avgConfidence() < 0.9}
				<div class="confidence-note">
					Data confidence: {Math.round(avgConfidence() * 100)}%
				</div>
			{/if}

			<div class="footnote">
					*The % Daily Value (DV) tells you how much a nutrient in a serving of food contributes to a daily diet. 2,000 calories a day is used for general nutrition advice.
				</div>
			</div>
		</div>

		<div class="breakdown-column">
			<div class="breakdown-header">
				<h3>Ingredient Breakdown</h3>
			</div>
			<div class="ingredient-breakdown">
				<table>
					<thead>
						<tr>
							<th>Original</th>
							<th>Matched</th>
							<th class="num">Qty</th>
							<th class="num">Grams</th>
							<th class="num">Cal</th>
							<th>Status</th>
						</tr>
					</thead>
					<tbody>
						{#each nutrition.ingredients as ing}
							<tr class="status-{ing.status}">
								<td class="original-text" title={ing.original}>
									{ing.original}
								</td>
								<td class="ingredient-name">
									{#if ing.canonical_id}
										<a href="/ingredients/{ing.canonical_id}">{ing.canonical_name}</a>
									{:else if ing.canonical_name}
										{ing.canonical_name}
									{:else}
										<span class="no-match">-</span>
									{/if}
								</td>
								<td class="num qty-cell">
									{#if ing.quantity}
										{ing.quantity}
										{#if ing.quantity_min !== ing.quantity_max && ing.quantity_min && ing.quantity_max}
											<span class="qty-range">({ing.quantity_min}-{ing.quantity_max})</span>
										{/if}
										{#if ing.unit}{ing.unit}{/if}
									{:else}
										-
									{/if}
								</td>
								<td class="num">{ing.grams ? formatNumber(ing.grams, 0) : '-'}</td>
								<td class="num">{ing.calories ? formatNumber(ing.calories, 0) : '-'}</td>
								<td>
									<span class="status-badge" style="color: {getStatusColor(ing.status)}">
										{getStatusText(ing.status)}
									</span>
								</td>
							</tr>
						{/each}
					</tbody>
					<tfoot>
						<tr class="total-row">
							<td colspan="2"><strong>Total</strong></td>
							<td class="num"></td>
							<td class="num">
								<strong>
									{formatNumber(
										nutrition.ingredients.reduce((sum, i) => sum + (getValue(i.grams) || 0), 0),
										0
									)}
								</strong>
							</td>
							<td class="num">
								<strong>{formatNumber(nutrition.total.calories, 0)}</strong>
							</td>
							<td></td>
						</tr>
					</tfoot>
				</table>
			</div>
		</div>
	</div>
</div>
{/if}

<style>
	.nutrition-loading {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-4);
		color: var(--text-secondary);
		font-size: var(--text-sm);
	}

	.spinner {
		width: 16px;
		height: 16px;
		border: 2px solid var(--border-light);
		border-top-color: var(--color-marinara-500);
		border-radius: 50%;
		animation: spin 0.8s linear infinite;
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	.nutrition-error {
		padding: var(--space-4);
		color: var(--color-marinara-600);
		font-size: var(--text-sm);
	}

	.nutrition-panel {
		background: var(--bg-card);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		font-size: var(--text-sm);
	}

	.nutrition-layout {
		display: grid;
		grid-template-columns: minmax(280px, 320px) 1fr;
		gap: var(--space-6);
		align-items: start;
	}

	@media (max-width: 900px) {
		.nutrition-layout {
			grid-template-columns: 1fr;
		}
	}

	.facts-column {
		min-width: 0;
	}

	.breakdown-column {
		min-width: 0;
		overflow-x: auto;
	}

	.nutrition-header,
	.breakdown-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: var(--space-3);
	}

	.nutrition-header h3,
	.breakdown-header h3 {
		margin: 0;
		font-size: var(--text-lg);
		font-weight: var(--font-bold);
	}

	.serving-info {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: var(--space-1);
	}

	.servings {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.completeness {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		background: var(--color-pasta-200);
		border-radius: var(--radius-full);
		color: var(--color-pasta-700);
	}

	.warnings {
		margin-bottom: var(--space-3);
	}

	.warning {
		padding: var(--space-2);
		background: var(--color-pasta-100);
		border-left: 3px solid var(--color-pasta-500);
		font-size: var(--text-xs);
		color: var(--color-pasta-700);
		margin-bottom: var(--space-1);
	}

	.nutrition-facts {
		border: 1px solid var(--text-primary);
		padding: var(--space-2);
	}

	.calories-row {
		display: flex;
		justify-content: space-between;
		font-size: var(--text-lg);
		font-weight: var(--font-bold);
		padding: var(--space-1) 0;
	}

	.divider {
		border-top: 1px solid var(--text-primary);
		margin: var(--space-1) 0;
	}

	.divider.thick {
		border-top-width: 8px;
	}

	.daily-value-header {
		text-align: right;
		font-size: var(--text-xs);
		font-weight: var(--font-bold);
		padding: var(--space-1) 0;
	}

	.nutrient-row {
		display: flex;
		gap: var(--space-2);
		padding: var(--space-1) 0;
		border-top: 1px solid var(--border-light);
	}

	.nutrient-row .label {
		flex: 1;
	}

	.nutrient-row .label.bold {
		font-weight: var(--font-bold);
	}

	.nutrient-row .value {
		min-width: 60px;
		text-align: right;
	}

	.nutrient-row .daily {
		min-width: 40px;
		text-align: right;
		font-weight: var(--font-bold);
	}

	.nutrient-row.indent .label {
		padding-left: var(--space-4);
	}

	.vitamins-minerals {
		padding-top: var(--space-2);
	}

	.vitamin-row {
		display: flex;
		gap: var(--space-2);
		padding: var(--space-1) 0;
	}

	.vitamin-row .label {
		flex: 1;
	}

	.vitamin-row .value {
		min-width: 60px;
		text-align: right;
	}

	.vitamin-row .daily {
		min-width: 40px;
		text-align: right;
	}

	.footnote {
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-top: var(--space-2);
		line-height: var(--leading-snug);
	}

	.ingredient-breakdown {
		overflow-x: auto;
	}

	.ingredient-breakdown table {
		width: 100%;
		border-collapse: collapse;
		font-size: var(--text-xs);
	}

	.ingredient-breakdown th,
	.ingredient-breakdown td {
		padding: var(--space-2);
		text-align: left;
		border-bottom: 1px solid var(--border-light);
	}

	.ingredient-breakdown th {
		background: var(--bg-surface);
		font-weight: var(--font-medium);
	}

	.ingredient-breakdown .num {
		text-align: right;
	}

	.original-text {
		max-width: 200px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		color: var(--text-secondary);
		font-size: var(--text-xs);
	}

	.ingredient-name {
		max-width: 120px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.ingredient-name a {
		color: var(--color-marinara-600);
		text-decoration: none;
	}

	.ingredient-name a:hover {
		text-decoration: underline;
	}

	.no-match {
		color: var(--text-muted);
	}

	.status-badge {
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.total-row {
		background: var(--bg-surface);
	}

	.total-row td {
		border-top: 2px solid var(--border-default);
	}

	.range-indicator {
		color: var(--color-pasta-500);
		font-size: var(--text-xs);
		margin-left: var(--space-1);
	}

	.calories-range-bar {
		margin: var(--space-1) 0;
	}

	.confidence-note {
		font-size: var(--text-xs);
		color: var(--text-muted);
		text-align: right;
		padding: var(--space-1) 0;
		font-style: italic;
	}

	.qty-cell {
		white-space: nowrap;
	}

	.qty-range {
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-left: 2px;
	}

	/* Print styles */
	@media print {
		.nutrition-panel {
			border: 1px solid #000;
			page-break-inside: avoid;
		}

		.nutrition-layout {
			grid-template-columns: 1fr;
		}
	}
</style>
