<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { ingredients as ingredientsApi, type CanonicalIngredient, type IngredientNutrition } from '$lib/api/client';

	let ingredient = $state<CanonicalIngredient | null>(null);
	let loading = $state(true);
	let error = $state('');
	let selectedSourceIndex = $state(0);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadIngredient();
	});

	async function loadIngredient() {
		const token = authStore.getToken();
		if (!token) return;

		const id = $page.params.id;
		if (!id) {
			error = 'No ingredient ID provided';
			loading = false;
			return;
		}

		loading = true;
		error = '';

		try {
			const result = await ingredientsApi.get(token, id);
			ingredient = result.data;
			// Select the primary nutrition source by default
			const primaryIndex = ingredient.all_nutrition?.findIndex(n => n.is_primary) ?? -1;
			selectedSourceIndex = primaryIndex >= 0 ? primaryIndex : 0;
		} catch {
			error = 'Failed to load ingredient';
		} finally {
			loading = false;
		}
	}

	function formatValue(value: number | null, unit: string, decimals: number = 1): string {
		if (value === null) return '-';
		return `${value.toFixed(decimals)}${unit}`;
	}

	function getSourceLabel(source: string): string {
		const labels: Record<string, string> = {
			usda: 'USDA',
			manual: 'Manual',
			open_food_facts: 'Open Food Facts',
			nutritionix: 'Nutritionix',
			fatsecret: 'FatSecret',
			estimated: 'Estimated'
		};
		return labels[source] || source;
	}

	function getSourceColor(source: string): string {
		const colors: Record<string, string> = {
			usda: 'var(--color-basil-600)',
			fatsecret: 'var(--color-marinara-600)',
			open_food_facts: 'var(--color-pasta-600)',
			manual: 'var(--color-gray-600)',
			estimated: 'var(--color-gray-400)'
		};
		return colors[source] || 'var(--color-gray-500)';
	}

	let selectedNutrition = $derived(
		ingredient?.all_nutrition?.[selectedSourceIndex] || ingredient?.nutrition || null
	);

	let nutritionSources = $derived(ingredient?.all_nutrition || []);
</script>

<div class="ingredient-page">
	{#if loading}
		<div class="loading">Loading ingredient...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if ingredient}
		<div class="header">
			<a href="/ingredients" class="back-link">&larr; All Ingredients</a>
			<div class="header-content">
				{#if ingredient.image_url}
					<div class="header-image">
						<img src={ingredient.image_url} alt={ingredient.display_name} />
					</div>
				{/if}
				<div class="header-text">
					<h1>{ingredient.display_name}</h1>
					<div class="badges">
						{#if ingredient.is_branded}
							<span class="badge branded">Branded</span>
						{/if}
						{#if ingredient.is_allergen}
							<span class="badge allergen">Allergen</span>
						{/if}
						{#if ingredient.category}
							<span class="badge category">{ingredient.category}</span>
						{/if}
					</div>
				</div>
			</div>
		</div>

		<div class="content-grid">
			<!-- Nutrition Facts Panel -->
			<div class="nutrition-panel">
				{#if nutritionSources.length > 1}
					<div class="source-tabs">
						{#each nutritionSources as source, index}
							<button
								class="source-tab"
								class:active={selectedSourceIndex === index}
								style="--source-color: {getSourceColor(source.source)}"
								onclick={() => selectedSourceIndex = index}
							>
								{getSourceLabel(source.source)}
								{#if source.is_primary}
									<span class="primary-badge">Primary</span>
								{/if}
							</button>
						{/each}
					</div>
				{/if}

				<div class="nutrition-label">
					<h2>Nutrition Facts</h2>
					{#if selectedNutrition}
						<p class="serving-size">
							Serving Size: {selectedNutrition.serving_size_value}{selectedNutrition.serving_size_unit}
							{#if selectedNutrition.serving_description}
								({selectedNutrition.serving_description})
							{/if}
						</p>

						<div class="nutrition-divider thick"></div>

						<div class="nutrient-row calories">
							<span class="label">Calories</span>
							<span class="value"
								>{selectedNutrition.calories !== null
									? Math.round(selectedNutrition.calories)
									: '-'}</span
							>
						</div>

						<div class="nutrition-divider thick"></div>

						<div class="nutrient-row">
							<span class="label bold">Total Fat</span>
							<span class="value">{formatValue(selectedNutrition.fat_total_g, 'g')}</span>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Saturated Fat</span>
							<span class="value">{formatValue(selectedNutrition.fat_saturated_g, 'g')}</span>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Trans Fat</span>
							<span class="value">{formatValue(selectedNutrition.fat_trans_g, 'g')}</span>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Polyunsaturated Fat</span>
							<span class="value"
								>{formatValue(selectedNutrition.fat_polyunsaturated_g, 'g')}</span
							>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Monounsaturated Fat</span>
							<span class="value"
								>{formatValue(selectedNutrition.fat_monounsaturated_g, 'g')}</span
							>
						</div>

						<div class="nutrition-divider"></div>

						<div class="nutrient-row">
							<span class="label bold">Cholesterol</span>
							<span class="value">{formatValue(selectedNutrition.cholesterol_mg, 'mg', 0)}</span>
						</div>
						<div class="nutrient-row">
							<span class="label bold">Sodium</span>
							<span class="value">{formatValue(selectedNutrition.sodium_mg, 'mg', 0)}</span>
						</div>

						<div class="nutrition-divider"></div>

						<div class="nutrient-row">
							<span class="label bold">Total Carbohydrate</span>
							<span class="value">{formatValue(selectedNutrition.carbohydrates_g, 'g')}</span>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Dietary Fiber</span>
							<span class="value">{formatValue(selectedNutrition.fiber_g, 'g')}</span>
						</div>
						<div class="nutrient-row indent">
							<span class="label">Total Sugars</span>
							<span class="value">{formatValue(selectedNutrition.sugar_g, 'g')}</span>
						</div>
						{#if selectedNutrition.sugar_added_g !== null}
							<div class="nutrient-row indent-2">
								<span class="label">Includes Added Sugars</span>
								<span class="value">{formatValue(selectedNutrition.sugar_added_g, 'g')}</span>
							</div>
						{/if}

						<div class="nutrition-divider"></div>

						<div class="nutrient-row">
							<span class="label bold">Protein</span>
							<span class="value">{formatValue(selectedNutrition.protein_g, 'g')}</span>
						</div>

						<div class="nutrition-divider thick"></div>

						<!-- Vitamins & Minerals -->
						<div class="vitamins-minerals">
							<div class="nutrient-row">
								<span class="label">Vitamin A</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_a_mcg, 'mcg', 0)}</span
								>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin C</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_c_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin D</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_d_mcg, 'mcg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin E</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_e_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin K</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_k_mcg, 'mcg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin B6</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_b6_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Vitamin B12</span>
								<span class="value">{formatValue(selectedNutrition.vitamin_b12_mcg, 'mcg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Thiamin</span>
								<span class="value">{formatValue(selectedNutrition.thiamin_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Riboflavin</span>
								<span class="value">{formatValue(selectedNutrition.riboflavin_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Niacin</span>
								<span class="value">{formatValue(selectedNutrition.niacin_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Folate</span>
								<span class="value">{formatValue(selectedNutrition.folate_mcg, 'mcg', 0)}</span>
							</div>

							<div class="nutrition-divider"></div>

							<div class="nutrient-row">
								<span class="label">Calcium</span>
								<span class="value">{formatValue(selectedNutrition.calcium_mg, 'mg', 0)}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Iron</span>
								<span class="value">{formatValue(selectedNutrition.iron_mg, 'mg')}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Potassium</span>
								<span class="value">{formatValue(selectedNutrition.potassium_mg, 'mg', 0)}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Magnesium</span>
								<span class="value">{formatValue(selectedNutrition.magnesium_mg, 'mg', 0)}</span>
							</div>
							<div class="nutrient-row">
								<span class="label">Phosphorus</span>
								<span class="value"
									>{formatValue(selectedNutrition.phosphorus_mg, 'mg', 0)}</span
								>
							</div>
							<div class="nutrient-row">
								<span class="label">Zinc</span>
								<span class="value">{formatValue(selectedNutrition.zinc_mg, 'mg')}</span>
							</div>
						</div>

						<div class="nutrition-divider"></div>

						<div class="source">
							<p>
								Source: {getSourceLabel(selectedNutrition.source)}
								{#if selectedNutrition.source_url}
									<a href={selectedNutrition.source_url} target="_blank" rel="noopener"
										>View source</a
									>
								{/if}
							</p>
						</div>
					{:else}
						<div class="no-nutrition">
							<p>No nutrition data available for this ingredient.</p>
						</div>
					{/if}
				</div>
			</div>

			<!-- Details Panel -->
			<div class="details-panel">
				<section class="detail-section">
					<h3>Details</h3>
					<dl>
						<dt>Canonical Name</dt>
						<dd>{ingredient.name}</dd>

						{#if ingredient.category}
							<dt>Category</dt>
							<dd>
								{ingredient.category}
								{#if ingredient.subcategory} / {ingredient.subcategory}{/if}
							</dd>
						{/if}

						{#if ingredient.brand}
							<dt>Brand</dt>
							<dd>{ingredient.brand}</dd>
						{/if}

						{#if ingredient.parent_company}
							<dt>Parent Company</dt>
							<dd>{ingredient.parent_company}</dd>
						{/if}
					</dl>
				</section>

				{#if ingredient.aliases.length > 0}
					<section class="detail-section">
						<h3>Also Known As</h3>
						<div class="tag-list">
							{#each ingredient.aliases as alias}
								<span class="tag">{alias}</span>
							{/each}
						</div>
					</section>
				{/if}

				{#if ingredient.allergen_groups.length > 0}
					<section class="detail-section">
						<h3>Allergen Groups</h3>
						<div class="tag-list">
							{#each ingredient.allergen_groups as group}
								<span class="tag allergen">{group}</span>
							{/each}
						</div>
					</section>
				{/if}

				{#if ingredient.dietary_flags.length > 0}
					<section class="detail-section">
						<h3>Dietary Info</h3>
						<div class="tag-list">
							{#each ingredient.dietary_flags as flag}
								<span class="tag dietary">{flag}</span>
							{/each}
						</div>
					</section>
				{/if}

				{#if ingredient.tags.length > 0}
					<section class="detail-section">
						<h3>Tags</h3>
						<div class="tag-list">
							{#each ingredient.tags as tag}
								<span class="tag">{tag}</span>
							{/each}
						</div>
					</section>
				{/if}

				{#if ingredient.package_sizes && ingredient.package_sizes.length > 0}
					<section class="detail-section">
						<h3>Package Sizes</h3>
						<ul class="package-list">
							{#each ingredient.package_sizes as pkg}
								<li>
									{pkg.label}
									{#if pkg.is_default}
										<span class="default-badge">Default</span>
									{/if}
								</li>
							{/each}
						</ul>
					</section>
				{/if}
			</div>
		</div>
	{/if}
</div>

<style>
	.ingredient-page {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
	}

	.loading,
	.error {
		text-align: center;
		padding: var(--space-12);
	}

	.error {
		color: var(--color-error);
		background: var(--color-error-bg);
		border-radius: var(--radius-md);
	}

	.back-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
	}

	.back-link:hover {
		text-decoration: underline;
	}

	.header-content {
		display: flex;
		gap: var(--space-6);
		margin-top: var(--space-2);
		align-items: flex-start;
	}

	.header-image {
		width: 120px;
		height: 120px;
		border-radius: var(--radius-lg);
		overflow: hidden;
		background: var(--color-gray-100);
		flex-shrink: 0;
	}

	.header-image img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.header-text h1 {
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-800);
	}

	.badges {
		display: flex;
		gap: var(--space-2);
		margin-top: var(--space-2);
	}

	.badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-3);
		border-radius: var(--radius-sm);
		font-weight: var(--font-medium);
	}

	.badge.branded {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.badge.allergen {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.badge.category {
		background: var(--color-gray-100);
		color: var(--text-secondary);
		text-transform: capitalize;
	}

	.content-grid {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: var(--space-8);
		margin-top: var(--space-8);
	}

	@media (max-width: 768px) {
		.content-grid {
			grid-template-columns: 1fr;
		}
	}

	/* Nutrition Label Styling */
	.nutrition-panel {
		position: sticky;
		top: var(--space-4);
	}

	.source-tabs {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
	}

	.source-tab {
		padding: var(--space-2) var(--space-3);
		border: 2px solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		cursor: pointer;
		transition: all var(--transition-fast);
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.source-tab:hover {
		border-color: var(--source-color, var(--color-marinara-500));
	}

	.source-tab.active {
		border-color: var(--source-color, var(--color-marinara-500));
		background: color-mix(in srgb, var(--source-color, var(--color-marinara-500)) 10%, white);
	}

	.primary-badge {
		font-size: var(--text-xs);
		padding: 2px 6px;
		background: var(--color-basil-500);
		color: white;
		border-radius: var(--radius-sm);
	}

	.nutrition-label {
		border: var(--border-width-thin) solid var(--color-marinara-800);
		padding: var(--space-2);
		font-family: Arial, Helvetica, sans-serif;
		max-width: 280px;
	}

	.nutrition-label h2 {
		font-size: var(--text-3xl);
		font-weight: 900;
		margin: 0;
		color: var(--color-marinara-800);
	}

	.serving-size {
		font-size: var(--text-sm);
		margin: var(--space-1) 0;
	}

	.nutrition-divider {
		border-bottom: var(--border-width-thin) solid var(--color-marinara-800);
		margin: var(--space-1) 0;
	}

	.nutrition-divider.thick {
		border-bottom-width: 8px;
	}

	.nutrient-row {
		display: flex;
		justify-content: space-between;
		padding: var(--space-1) 0;
		font-size: var(--text-sm);
	}

	.nutrient-row.calories {
		font-size: var(--text-2xl);
		font-weight: 900;
	}

	.nutrient-row.indent {
		padding-left: var(--space-4);
	}

	.nutrient-row.indent-2 {
		padding-left: var(--space-8);
	}

	.nutrient-row .label.bold {
		font-weight: var(--font-bold);
	}

	.vitamins-minerals .nutrient-row {
		font-size: var(--text-sm);
	}

	.source {
		font-size: var(--text-xs);
		color: var(--text-secondary);
		margin-top: var(--space-2);
	}

	.source a {
		color: var(--color-marinara-600);
	}

	.no-nutrition {
		padding: var(--space-4);
		text-align: center;
		color: var(--text-secondary);
	}

	/* Details Panel */
	.details-panel {
		display: flex;
		flex-direction: column;
		gap: var(--space-6);
	}

	.detail-section {
		border: var(--border-width-thin) solid var(--border-light);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
	}

	.detail-section h3 {
		margin: 0 0 var(--space-3);
		font-size: var(--text-base);
		color: var(--color-marinara-700);
	}

	.detail-section dl {
		display: grid;
		grid-template-columns: 140px 1fr;
		gap: var(--space-2);
		margin: 0;
	}

	.detail-section dt {
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.detail-section dd {
		margin: 0;
	}

	.tag-list {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
	}

	.tag {
		font-size: var(--text-sm);
		padding: var(--space-1) var(--space-3);
		background: var(--color-gray-100);
		border-radius: var(--radius-sm);
		color: var(--text-secondary);
	}

	.tag.allergen {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.tag.dietary {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.package-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.package-list li {
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--border-light);
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.package-list li:last-child {
		border-bottom: none;
	}

	.default-badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-500);
		color: var(--color-white);
		border-radius: var(--radius-sm);
	}
</style>
