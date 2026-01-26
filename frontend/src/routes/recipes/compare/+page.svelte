<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, type Recipe, type RecipeComparison } from '$lib/api/client';

	let recipe1 = $state<Recipe | null>(null);
	let recipe2 = $state<Recipe | null>(null);
	let comparison = $state<RecipeComparison | null>(null);
	let loading = $state(true);
	let error = $state('');

	// Recipe selection state
	let allRecipes = $state<Recipe[]>([]);
	let selectedId1 = $state('');
	let selectedId2 = $state('');
	let loadingRecipes = $state(false);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		const token = authStore.getToken();
		if (!token) return;

		loadingRecipes = true;
		try {
			const result = await recipes.list(token, { limit: 100 });
			allRecipes = result.data;

			// Check if IDs were provided in URL
			const url = new URL(window.location.href);
			const id1 = url.searchParams.get('id1');
			const id2 = url.searchParams.get('id2');

			if (id1 && id2) {
				selectedId1 = id1;
				selectedId2 = id2;
				await loadComparison();
			}
		} catch {
			error = 'Failed to load recipes';
		} finally {
			loadingRecipes = false;
			loading = false;
		}
	});

	async function loadComparison() {
		if (!selectedId1 || !selectedId2 || selectedId1 === selectedId2) {
			comparison = null;
			return;
		}

		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await recipes.compare(token, selectedId1, selectedId2);
			comparison = result.data;
			recipe1 = comparison.recipe1;
			recipe2 = comparison.recipe2;

			// Update URL
			const url = new URL(window.location.href);
			url.searchParams.set('id1', selectedId1);
			url.searchParams.set('id2', selectedId2);
			window.history.replaceState({}, '', url.toString());
		} catch {
			error = 'Failed to compare recipes';
		} finally {
			loading = false;
		}
	}

	function handleCompare() {
		loadComparison();
	}

	function formatPercent(value: number): string {
		return `${(value * 100).toFixed(1)}%`;
	}

	function getBarWidth(value: number): string {
		return `${Math.min(value * 100 * 2, 100)}%`;
	}
</script>

<div class="compare-page">
	<header class="page-header">
		<h1>Compare Recipes</h1>
		<a href="/recipes" class="btn">Back to Recipes</a>
	</header>

	<div class="selector-section">
		<div class="selector">
			<label for="recipe1">First Recipe</label>
			<select id="recipe1" bind:value={selectedId1} disabled={loadingRecipes}>
				<option value="">Select a recipe...</option>
				{#each allRecipes as r}
					<option value={r.id} disabled={r.id === selectedId2}>{r.title}</option>
				{/each}
			</select>
		</div>

		<div class="vs">vs</div>

		<div class="selector">
			<label for="recipe2">Second Recipe</label>
			<select id="recipe2" bind:value={selectedId2} disabled={loadingRecipes}>
				<option value="">Select a recipe...</option>
				{#each allRecipes as r}
					<option value={r.id} disabled={r.id === selectedId1}>{r.title}</option>
				{/each}
			</select>
		</div>

		<button class="btn btn-primary" onclick={handleCompare} disabled={!selectedId1 || !selectedId2 || selectedId1 === selectedId2}>
			Compare
		</button>
	</div>

	{#if loading && selectedId1 && selectedId2}
		<div class="loading">Comparing recipes...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if comparison && recipe1 && recipe2}
		<div class="comparison-result">
			<div class="score-overview">
				<div class="main-score">
					<span class="score-value">{Math.round(comparison.score * 100)}%</span>
					<span class="score-label">Overall Similarity</span>
				</div>
				<div class="score-details">
					<div class="score-item">
						<span class="score-name">Ingredient Overlap</span>
						<span class="score-num">{Math.round(comparison.overlap_score * 100)}%</span>
					</div>
					<div class="score-item">
						<span class="score-name">Proportion Match</span>
						<span class="score-num">{Math.round(comparison.proportion_score * 100)}%</span>
					</div>
				</div>
			</div>

			<div class="recipe-headers">
				<div class="recipe-header">
					<a href="/recipes/{recipe1.id}">{recipe1.title}</a>
				</div>
				<div class="recipe-header center">Ingredients</div>
				<div class="recipe-header">
					<a href="/recipes/{recipe2.id}">{recipe2.title}</a>
				</div>
			</div>

			{#if comparison.shared_ingredients.length > 0}
				<div class="ingredient-section">
					<h3>Shared Ingredients ({comparison.shared_ingredients.length})</h3>
					<div class="ingredient-list shared">
						{#each comparison.shared_ingredients as ing}
							<div class="ingredient-row">
								<div class="proportion left">
									<div class="bar" style="width: {getBarWidth(ing.proportion1)}"></div>
									<span>{formatPercent(ing.proportion1)}</span>
								</div>
								<div class="ingredient-name">{ing.name}</div>
								<div class="proportion right">
									<span>{formatPercent(ing.proportion2)}</span>
									<div class="bar" style="width: {getBarWidth(ing.proportion2)}"></div>
								</div>
							</div>
						{/each}
					</div>
				</div>
			{/if}

			{#if comparison.only_in_first.length > 0 || comparison.only_in_second.length > 0}
				<div class="unique-sections">
					<div class="unique-section">
						<h3>Only in {recipe1.title}</h3>
						{#if comparison.only_in_first.length === 0}
							<p class="none">None</p>
						{:else}
							<ul>
								{#each comparison.only_in_first as ing}
									<li>
										<span class="name">{ing.name}</span>
										<span class="proportion">{formatPercent(ing.proportion)}</span>
									</li>
								{/each}
							</ul>
						{/if}
					</div>

					<div class="unique-section">
						<h3>Only in {recipe2.title}</h3>
						{#if comparison.only_in_second.length === 0}
							<p class="none">None</p>
						{:else}
							<ul>
								{#each comparison.only_in_second as ing}
									<li>
										<span class="name">{ing.name}</span>
										<span class="proportion">{formatPercent(ing.proportion)}</span>
									</li>
								{/each}
							</ul>
						{/if}
					</div>
				</div>
			{/if}
		</div>
	{:else if !loading}
		<div class="empty">
			<p>Select two recipes above to compare their ingredients.</p>
		</div>
	{/if}
</div>

<style>
	.compare-page {
		max-width: 100%;
	}

	.page-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-8);
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
	}

	.btn {
		padding: var(--space-2) var(--space-4);
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		text-decoration: none;
		color: var(--text-primary);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all var(--transition-fast);
	}

	.btn:hover {
		background: var(--bg-surface);
	}

	.btn-primary {
		background: var(--color-marinara-500);
		color: var(--color-white);
		border-color: var(--color-marinara-500);
	}

	.btn-primary:hover {
		background: var(--color-marinara-600);
	}

	.btn-primary:disabled {
		background: var(--color-gray-400);
		border-color: var(--color-gray-400);
		cursor: not-allowed;
	}

	.selector-section {
		display: flex;
		align-items: flex-end;
		gap: var(--space-4);
		margin-bottom: var(--space-8);
		padding: var(--space-6);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-lg);
		flex-wrap: wrap;
	}

	.selector {
		flex: 1;
		min-width: 200px;
	}

	.selector label {
		display: block;
		margin-bottom: var(--space-2);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.selector select {
		width: 100%;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		background: var(--bg-card);
	}

	.vs {
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--text-muted);
		padding-bottom: var(--space-3);
	}

	.loading,
	.error,
	.empty {
		text-align: center;
		padding: var(--space-12);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
	}

	.error {
		color: var(--color-error);
	}

	.comparison-result {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
	}

	.score-overview {
		display: flex;
		align-items: center;
		gap: var(--space-8);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		margin-bottom: var(--space-6);
	}

	.main-score {
		display: flex;
		flex-direction: column;
		align-items: center;
	}

	.score-value {
		font-size: var(--text-5xl);
		font-weight: var(--font-bold);
		color: var(--color-basil-500);
	}

	.score-label {
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	.score-details {
		display: flex;
		gap: var(--space-8);
	}

	.score-item {
		display: flex;
		flex-direction: column;
	}

	.score-name {
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	.score-num {
		font-size: var(--text-2xl);
		font-weight: var(--font-medium);
	}

	.recipe-headers {
		display: grid;
		grid-template-columns: 1fr auto 1fr;
		gap: var(--space-4);
		margin-bottom: var(--space-4);
		padding-bottom: var(--space-2);
		border-bottom: var(--border-width-default) solid var(--color-marinara-500);
	}

	.recipe-header {
		font-weight: var(--font-semibold);
	}

	.recipe-header a {
		color: var(--color-marinara-600);
		text-decoration: none;
	}

	.recipe-header a:hover {
		text-decoration: underline;
	}

	.recipe-header.center {
		text-align: center;
		color: var(--text-muted);
	}

	.ingredient-section {
		margin-bottom: var(--space-8);
	}

	.ingredient-section h3 {
		color: var(--color-basil-600);
		margin-bottom: var(--space-4);
	}

	.ingredient-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.ingredient-row {
		display: grid;
		grid-template-columns: 1fr auto 1fr;
		gap: var(--space-4);
		align-items: center;
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--color-gray-100);
	}

	.proportion {
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.proportion.left {
		justify-content: flex-end;
	}

	.proportion.right {
		justify-content: flex-start;
	}

	.proportion .bar {
		height: 8px;
		background: var(--color-marinara-500);
		border-radius: var(--radius-sm);
		min-width: 4px;
	}

	.proportion.left .bar {
		order: -1;
	}

	.proportion span {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		min-width: 50px;
	}

	.proportion.left span {
		text-align: right;
	}

	.ingredient-name {
		text-align: center;
		font-weight: var(--font-medium);
		min-width: 120px;
	}

	.unique-sections {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-8);
	}

	.unique-section h3 {
		color: var(--color-pasta-700);
		margin-bottom: var(--space-4);
		font-size: var(--text-base);
	}

	.unique-section ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.unique-section li {
		display: flex;
		justify-content: space-between;
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--color-gray-100);
	}

	.unique-section .name {
		color: var(--text-primary);
	}

	.unique-section .proportion {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.unique-section .none {
		color: var(--text-muted);
		font-style: italic;
	}

	@media (max-width: 768px) {
		.selector-section {
			flex-direction: column;
			align-items: stretch;
		}

		.vs {
			text-align: center;
			padding: var(--space-2) 0;
		}

		.score-overview {
			flex-direction: column;
			text-align: center;
		}

		.recipe-headers,
		.ingredient-row {
			grid-template-columns: 1fr;
			text-align: center;
		}

		.proportion {
			justify-content: center !important;
		}

		.unique-sections {
			grid-template-columns: 1fr;
		}
	}
</style>
