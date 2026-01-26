<script lang="ts">
	import type { RecipeNutrition, NutrientData } from '$lib/api/client';

	interface Props {
		nutrition: RecipeNutrition | null;
		loading?: boolean;
		error?: string;
	}

	let { nutrition, loading = false, error = '' }: Props = $props();

	let showIngredientDetails = $state(false);

	function formatNumber(value: number | null, decimals: number = 0): string {
		if (value === null || value === undefined) return '-';
		return value.toFixed(decimals);
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

	function getDailyPercent(key: keyof NutrientData, value: number | null): string | null {
		const dv = dailyValues[key];
		if (!dv || value === null) return null;
		const percent = Math.round((value / dv) * 100);
		return `${percent}%`;
	}
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

		{#if nutrition.warnings.length > 0}
			<div class="warnings">
				{#each nutrition.warnings as warning}
					<div class="warning">{warning}</div>
				{/each}
			</div>
		{/if}

		<div class="nutrition-facts">
			<div class="calories-row">
				<span class="label">Calories</span>
				<span class="value">{formatNumber(nutrition.per_serving.calories)}</span>
			</div>

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

			<div class="footnote">
				*The % Daily Value (DV) tells you how much a nutrient in a serving of food contributes to a daily diet. 2,000 calories a day is used for general nutrition advice.
			</div>
		</div>

		<button
			class="details-toggle"
			onclick={() => (showIngredientDetails = !showIngredientDetails)}
		>
			{showIngredientDetails ? 'Hide' : 'Show'} ingredient breakdown
			<span class="arrow">{showIngredientDetails ? '▲' : '▼'}</span>
		</button>

		{#if showIngredientDetails}
			<div class="ingredient-breakdown">
				<table>
					<thead>
						<tr>
							<th>Ingredient</th>
							<th class="num">Grams</th>
							<th class="num">Cal</th>
							<th>Status</th>
						</tr>
					</thead>
					<tbody>
						{#each nutrition.ingredients as ing}
							<tr class="status-{ing.status}">
								<td class="ingredient-name" title={ing.original}>
									{ing.canonical_name || ing.original}
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
							<td><strong>Total</strong></td>
							<td class="num">
								<strong>
									{formatNumber(
										nutrition.ingredients.reduce((sum, i) => sum + (i.grams || 0), 0),
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
		{/if}
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

	.nutrition-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: var(--space-3);
	}

	.nutrition-header h3 {
		margin: 0;
		font-size: var(--text-xl);
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

	.details-toggle {
		width: 100%;
		margin-top: var(--space-3);
		padding: var(--space-2);
		background: var(--bg-surface);
		border: var(--border-width-thin) solid var(--border-light);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		display: flex;
		justify-content: center;
		align-items: center;
		gap: var(--space-2);
		transition: all var(--transition-fast);
	}

	.details-toggle:hover {
		background: var(--color-pasta-100);
	}

	.arrow {
		font-size: var(--text-xs);
	}

	.ingredient-breakdown {
		margin-top: var(--space-3);
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

	.ingredient-name {
		max-width: 150px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
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

	/* Print styles */
	@media print {
		.details-toggle {
			display: none;
		}

		.nutrition-panel {
			border: 1px solid #000;
			page-break-inside: avoid;
		}
	}
</style>
