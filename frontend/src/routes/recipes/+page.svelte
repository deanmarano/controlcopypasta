<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, type Recipe } from '$lib/api/client';

	let recipeList = $state<Recipe[]>([]);
	let loading = $state(true);
	let error = $state('');
	let searchQuery = $state('');
	let showArchived = $state(false);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadRecipes();
	});

	async function loadRecipes() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const params: { q?: string; archived?: 'true' | 'all' } = {};
			if (searchQuery) params.q = searchQuery;
			if (showArchived) params.archived = 'true';
			const result = await recipes.list(token, Object.keys(params).length > 0 ? params : undefined);
			recipeList = result.data;
		} catch (err) {
			error = 'Failed to load recipes';
		} finally {
			loading = false;
		}
	}

	async function handleSearch(e: Event) {
		e.preventDefault();
		await loadRecipes();
	}

	async function deleteRecipe(id: string) {
		if (!confirm('Are you sure you want to delete this recipe?')) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			await recipes.delete(token, id);
			recipeList = recipeList.filter((r) => r.id !== id);
		} catch {
			alert('Failed to delete recipe');
		}
	}

	async function archiveRecipe(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await recipes.archive(token, id);
			// Remove from current list (it's now archived)
			recipeList = recipeList.filter((r) => r.id !== id);
		} catch {
			alert('Failed to archive recipe');
		}
	}

	async function unarchiveRecipe(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await recipes.unarchive(token, id);
			// Remove from archived list (it's now active)
			recipeList = recipeList.filter((r) => r.id !== id);
		} catch {
			alert('Failed to unarchive recipe');
		}
	}

	async function toggleShowArchived() {
		showArchived = !showArchived;
		await loadRecipes();
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}
</script>

<div class="recipes-page">
	<header class="page-header">
		<h1>My Recipes</h1>
		<div class="header-actions">
			<a href="/recipes/compare" class="btn-secondary">Compare</a>
			<a href="/recipes/new" class="btn-primary">Add Recipe</a>
		</div>
	</header>

	<form class="search-form" onsubmit={handleSearch}>
		<input type="search" bind:value={searchQuery} placeholder="Search recipes..." />
		<button type="submit">Search</button>
	</form>

	<div class="filter-bar">
		<button class="filter-btn" class:active={!showArchived} onclick={() => { if (showArchived) toggleShowArchived(); }}>
			Active
		</button>
		<button class="filter-btn" class:active={showArchived} onclick={() => { if (!showArchived) toggleShowArchived(); }}>
			Archived
		</button>
	</div>

	{#if loading}
		<div class="loading">Loading recipes...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if recipeList.length === 0}
		<div class="empty">
			<p>No recipes yet!</p>
			<a href="/recipes/new">Add your first recipe</a>
		</div>
	{:else}
		<div class="recipe-grid">
			{#each recipeList as recipe}
				<div class="recipe-card">
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="recipe-image" />
					{:else}
						<div class="recipe-image placeholder">No image</div>
					{/if}
					<div class="recipe-content">
						<h2><a href="/recipes/{recipe.id}">{recipe.title}</a></h2>
						{#if recipe.description}
							<p class="description">{recipe.description.slice(0, 100)}...</p>
						{/if}
						<div class="recipe-meta">
							{#if recipe.total_time_minutes}
								<span class="time">{formatTime(recipe.total_time_minutes)}</span>
							{/if}
							{#if recipe.source_domain}
								<span class="source">{recipe.source_domain}</span>
							{/if}
						</div>
						{#if recipe.contains_avoided && recipe.avoided_ingredients && recipe.avoided_ingredients.length > 0}
							<div class="avoided-warning">
								Contains: {recipe.avoided_ingredients.map((i) => i.name).join(', ')}
							</div>
						{/if}
						{#if recipe.tags.length > 0}
							<div class="tags">
								{#each recipe.tags as tag}
									<span class="tag">{tag.name}</span>
								{/each}
							</div>
						{/if}
						<div class="actions">
							<a href="/recipes/{recipe.id}/edit">Edit</a>
							{#if showArchived}
								<button onclick={() => unarchiveRecipe(recipe.id)} class="action-restore">Restore</button>
							{:else}
								<button onclick={() => archiveRecipe(recipe.id)} class="action-archive">Archive</button>
							{/if}
							<button onclick={() => deleteRecipe(recipe.id)}>Delete</button>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.recipes-page {
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

	.btn-primary {
		background: var(--color-basil-500);
		color: var(--color-white);
		padding: var(--space-3) var(--space-6);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.btn-primary:hover {
		background: var(--color-basil-600);
		box-shadow: var(--shadow-basil);
	}

	.header-actions {
		display: flex;
		gap: var(--space-3);
	}

	.btn-secondary {
		background: var(--bg-card);
		color: var(--color-marinara-600);
		padding: var(--space-3) var(--space-6);
		text-decoration: none;
		border-radius: var(--radius-md);
		border: var(--border-width-thin) solid var(--color-marinara-500);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.btn-secondary:hover {
		background: var(--color-marinara-50);
	}

	.search-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-8);
	}

	.search-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		transition: all var(--transition-fast);
	}

	.search-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.search-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.search-form button:hover {
		background: var(--color-marinara-600);
	}

	.filter-bar {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-6);
	}

	.filter-btn {
		padding: var(--space-2) var(--space-4);
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		color: var(--text-secondary);
		transition: all var(--transition-fast);
	}

	.filter-btn:hover {
		background: var(--bg-surface);
	}

	.filter-btn.active {
		background: var(--color-marinara-500);
		color: var(--color-white);
		border-color: var(--color-marinara-500);
	}

	.loading,
	.error,
	.empty {
		text-align: center;
		padding: var(--space-12);
		color: var(--text-secondary);
	}

	.error {
		color: var(--color-error);
	}

	.empty a {
		display: inline-block;
		margin-top: var(--space-4);
		color: var(--color-marinara-600);
	}

	.recipe-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: var(--space-6);
	}

	.recipe-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-md);
		transition: all var(--transition-normal);
	}

	.recipe-card:hover {
		box-shadow: var(--shadow-lg);
		transform: translateY(-2px);
	}

	.recipe-image {
		width: 100%;
		height: 180px;
		object-fit: cover;
	}

	.recipe-image.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
		min-height: 180px;
	}

	.recipe-content {
		padding: var(--space-4);
	}

	h2 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-lg);
	}

	h2 a {
		color: var(--color-marinara-800);
		text-decoration: none;
	}

	h2 a:hover {
		color: var(--color-marinara-600);
	}

	.description {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-2);
	}

	.recipe-meta {
		display: flex;
		gap: var(--space-4);
		font-size: var(--text-sm);
		color: var(--text-muted);
		margin-bottom: var(--space-2);
	}

	.avoided-warning {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		padding: var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		margin-bottom: var(--space-2);
		border: var(--border-width-thin) solid var(--color-pasta-400);
	}

	.tags {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-1);
		margin-bottom: var(--space-2);
	}

	.tag {
		background: var(--color-gray-200);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.actions {
		display: flex;
		gap: var(--space-4);
		padding-top: var(--space-2);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.actions a {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
	}

	.actions a:hover {
		text-decoration: underline;
	}

	.actions button {
		background: none;
		border: none;
		color: var(--color-marinara-600);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: 0;
	}

	.actions .action-archive {
		color: var(--text-muted);
	}

	.actions .action-archive:hover {
		color: var(--text-secondary);
	}

	.actions .action-restore {
		color: var(--color-basil-500);
	}

	.actions .action-restore:hover {
		color: var(--color-basil-600);
	}
</style>
