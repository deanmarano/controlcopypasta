<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { ingredients as ingredientsApi, type CanonicalIngredient } from '$lib/api/client';

	let ingredientList = $state<CanonicalIngredient[]>([]);
	let filteredList = $state<CanonicalIngredient[]>([]);
	let loading = $state(true);
	let error = $state('');
	let searchQuery = $state('');
	let categoryFilter = $state('');
	let sortBy = $state<'popularity' | 'name'>('popularity');
	let prevSortBy = $state<'popularity' | 'name'>('popularity');
	let categories = $state<string[]>([]);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadIngredients();
	});

	async function loadIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await ingredientsApi.list(token, { order_by: sortBy });
			ingredientList = result.data;

			// Extract unique categories
			const cats = new Set<string>();
			ingredientList.forEach((i) => {
				if (i.category) cats.add(i.category);
			});
			categories = Array.from(cats).sort();

			applyFilters();
		} catch {
			error = 'Failed to load ingredients';
		} finally {
			loading = false;
		}
	}

	function applyFilters() {
		let filtered = ingredientList;

		if (searchQuery.trim()) {
			const query = searchQuery.toLowerCase();
			filtered = filtered.filter(
				(i) =>
					i.name.toLowerCase().includes(query) ||
					i.display_name.toLowerCase().includes(query) ||
					i.aliases.some((a) => a.toLowerCase().includes(query))
			);
		}

		if (categoryFilter) {
			filtered = filtered.filter((i) => i.category === categoryFilter);
		}

		// Sort by selected option (preserve API order for popularity since it's pre-sorted)
		if (sortBy === 'name') {
			filtered = filtered.sort((a, b) => a.display_name.localeCompare(b.display_name));
		}
		// For popularity, keep API order (already sorted by usage_count desc)
		filteredList = filtered;
	}

	async function handleSortChange() {
		await loadIngredients();
	}

	$effect(() => {
		searchQuery;
		categoryFilter;
		applyFilters();
	});

	// Reload when sort changes (only when sortBy actually changes)
	$effect(() => {
		if (sortBy !== prevSortBy) {
			prevSortBy = sortBy;
			handleSortChange();
		}
	});

	function formatNutrition(ingredient: CanonicalIngredient): string {
		if (!ingredient.nutrition) return 'No nutrition data';
		const n = ingredient.nutrition;
		const parts = [];
		if (n.calories !== null) parts.push(`${Math.round(n.calories)} cal`);
		if (n.protein_g !== null) parts.push(`${n.protein_g.toFixed(1)}g protein`);
		if (n.carbohydrates_g !== null) parts.push(`${n.carbohydrates_g.toFixed(1)}g carbs`);
		if (n.fat_total_g !== null) parts.push(`${n.fat_total_g.toFixed(1)}g fat`);
		return parts.length > 0 ? parts.join(' | ') : 'No macro data';
	}
</script>

<div class="ingredients-page">
	<div class="header">
		<h1>Ingredients</h1>
		<p class="subtitle">{ingredientList.length} ingredients in catalog</p>
	</div>

	<div class="filters">
		<input
			type="text"
			bind:value={searchQuery}
			placeholder="Search ingredients..."
			class="search-input"
		/>

		<select bind:value={categoryFilter} class="category-select">
			<option value="">All Categories</option>
			{#each categories as cat}
				<option value={cat}>{cat}</option>
			{/each}
		</select>

		<select bind:value={sortBy} class="sort-select">
			<option value="popularity">Most Used</option>
			<option value="name">A-Z</option>
		</select>
	</div>

	{#if error}
		<div class="error">{error}</div>
	{/if}

	{#if loading}
		<div class="loading">Loading ingredients...</div>
	{:else if filteredList.length === 0}
		<div class="empty">
			<p>No ingredients found matching your search.</p>
		</div>
	{:else}
		<div class="ingredients-grid">
			{#each filteredList as ingredient}
				<a href="/ingredients/{ingredient.id}" class="ingredient-card">
					{#if ingredient.image_url}
						<div class="ingredient-image">
							<img src={ingredient.image_url} alt={ingredient.display_name} />
						</div>
					{/if}
					<div class="ingredient-content">
						<div class="ingredient-header">
							<h3>{ingredient.display_name}</h3>
							{#if ingredient.usage_count > 0}
								<span class="badge usage">{ingredient.usage_count.toLocaleString()} uses</span>
							{/if}
							{#if ingredient.is_branded}
								<span class="badge branded">Branded</span>
							{/if}
							{#if ingredient.is_allergen}
								<span class="badge allergen">Allergen</span>
							{/if}
						</div>

					{#if ingredient.category}
						<div class="category">
							{ingredient.category}
							{#if ingredient.subcategory}
								/ {ingredient.subcategory}
							{/if}
						</div>
					{/if}

					<div class="nutrition-preview">
						{formatNutrition(ingredient)}
					</div>

					{#if ingredient.dietary_flags.length > 0}
						<div class="dietary-flags">
							{#each ingredient.dietary_flags.slice(0, 3) as flag}
								<span class="flag">{flag}</span>
							{/each}
							{#if ingredient.dietary_flags.length > 3}
								<span class="flag more">+{ingredient.dietary_flags.length - 3}</span>
							{/if}
						</div>
					{/if}
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>

<style>
	.ingredients-page {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
	}

	.header {
		margin-bottom: var(--space-6);
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
	}

	.subtitle {
		color: var(--text-secondary);
		margin: var(--space-1) 0 0;
	}

	.filters {
		display: flex;
		gap: var(--space-4);
		margin-bottom: var(--space-6);
	}

	.search-input {
		flex: 1;
		padding: var(--space-3) var(--space-4);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.search-input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.category-select,
	.sort-select {
		padding: var(--space-3) var(--space-4);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		min-width: 140px;
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
	}

	.loading,
	.empty {
		text-align: center;
		padding: var(--space-12);
		color: var(--text-secondary);
	}

	.ingredients-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: var(--space-4);
	}

	.ingredient-card {
		display: flex;
		border: var(--border-width-thin) solid var(--border-light);
		border-radius: var(--radius-lg);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-normal);
		overflow: hidden;
	}

	.ingredient-card:hover {
		border-color: var(--color-marinara-500);
		box-shadow: 0 2px 8px rgba(220, 74, 61, 0.15);
	}

	.ingredient-image {
		width: 80px;
		min-height: 80px;
		background: var(--color-gray-100);
		flex-shrink: 0;
	}

	.ingredient-image img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.ingredient-content {
		padding: var(--space-4);
		flex: 1;
		min-width: 0;
	}

	.ingredient-header {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		flex-wrap: wrap;
	}

	.ingredient-header h3 {
		margin: 0;
		font-size: var(--text-lg);
	}

	.badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
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

	.badge.usage {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		font-size: 0.65rem;
	}

	.category {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		margin-top: var(--space-2);
		text-transform: capitalize;
	}

	.nutrition-preview {
		font-size: var(--text-sm);
		color: var(--text-muted);
		margin-top: var(--space-2);
		padding-top: var(--space-2);
		border-top: var(--border-width-thin) solid var(--color-gray-100);
	}

	.dietary-flags {
		display: flex;
		gap: var(--space-1);
		flex-wrap: wrap;
		margin-top: var(--space-2);
	}

	.flag {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		background: var(--color-gray-100);
		border-radius: var(--radius-sm);
		color: var(--text-secondary);
	}

	.flag.more {
		background: var(--color-gray-200);
	}
</style>
