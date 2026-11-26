<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, tags as tagsApi, type Recipe, type Tag } from '$lib/api/client';
	import { truncate } from '$lib/text';

	const PAGE_SIZE = 24;

	let recipeList = $state<Recipe[]>([]);
	let tagList = $state<Tag[]>([]);
	let loading = $state(true);
	let loadingMore = $state(false);
	let hasMore = $state(false);
	let error = $state('');
	let searchQuery = $state('');
	let showArchived = $state(false);

	// The tag filter lives in the URL (/recipes?tag=dinner) so tag chips anywhere can link to it.
	const activeTag = $derived($page.url.searchParams.get('tag') || '');
	let loadedTag: string | null = null;

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	// Loads on first render and again whenever the tag in the URL changes.
	$effect(() => {
		const tag = activeTag;
		if (!$isAuthenticated || tag === loadedTag) return;
		loadedTag = tag;
		untrack(() => loadRecipes());
	});

	onMount(async () => {
		const token = authStore.getToken();
		if (!token) return;
		try {
			tagList = (await tagsApi.list(token)).data;
		} catch {
			// The tag filter is optional; the page works without it.
		}
	});

	async function loadRecipes(append = false) {
		const token = authStore.getToken();
		if (!token) return;

		if (append) loadingMore = true;
		else loading = true;
		error = '';

		try {
			const params: { q?: string; tag?: string; archived?: 'true' | 'all'; limit: number; offset?: number } = {
				limit: PAGE_SIZE
			};
			if (append) params.offset = recipeList.length;
			if (searchQuery) params.q = searchQuery;
			if (activeTag) params.tag = activeTag;
			if (showArchived) params.archived = 'true';
			const result = await recipes.list(token, params);
			recipeList = append ? [...recipeList, ...result.data] : result.data;
			hasMore = result.data.length === PAGE_SIZE;
		} catch (err) {
			error = 'Failed to load recipes';
		} finally {
			loading = false;
			loadingMore = false;
		}
	}

	async function handleSearch(e: Event) {
		e.preventDefault();
		await loadRecipes();
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

	{#if tagList.length > 0}
		<nav class="tag-filter" aria-label="Filter by tag">
			<a href="/recipes" class="tag-chip" class:active={!activeTag}>All</a>
			{#each tagList as tag}
				<a
					href="/recipes?tag={encodeURIComponent(tag.name)}"
					class="tag-chip"
					class:active={activeTag === tag.name}
				>{tag.name}</a>
			{/each}
			<a href="/tags" class="manage-tags">Manage tags</a>
		</nav>
	{:else}
		<p class="tag-filter-empty"><a href="/tags" class="manage-tags">Manage tags</a></p>
	{/if}

	{#if loading}
		<div class="loading">Loading recipes...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if recipeList.length === 0}
		<div class="empty">
			{#if activeTag || searchQuery || showArchived}
				<p>No recipes match{activeTag ? ` the tag "${activeTag}"` : ''}.</p>
				{#if activeTag}<a href="/recipes">Show all recipes</a>{/if}
			{:else}
				<p>No recipes yet!</p>
				<a href="/recipes/new">Add your first recipe</a>
			{/if}
		</div>
	{:else}
		<div class="recipe-grid">
			{#each recipeList as recipe}
				<div class="recipe-card">
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="recipe-image" loading="lazy" />
					{:else}
						<div class="recipe-image placeholder">No image</div>
					{/if}
					<div class="recipe-content">
						<h2><a href="/recipes/{recipe.id}">{recipe.title}</a></h2>
						{#if recipe.description}
							<p class="description">{truncate(recipe.description, 100)}</p>
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
									<a href="/recipes?tag={encodeURIComponent(tag.name)}" class="tag">{tag.name}</a>
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
						</div>
					</div>
				</div>
			{/each}
		</div>
		{#if hasMore}
			<div class="load-more">
				<button onclick={() => loadRecipes(true)} disabled={loadingMore}>
					{loadingMore ? 'Loading...' : 'Show more recipes'}
				</button>
			</div>
		{/if}
	{/if}
</div>

<style>
	.recipes-page {
		max-width: 100%;
	}

	.page-header {
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		align-items: center;
		gap: var(--space-3);
		margin-bottom: var(--space-8);
	}

	@media (max-width: 640px) {
		.page-header {
			margin-bottom: var(--space-5);
		}

		.btn-primary,
		.btn-secondary {
			padding: var(--space-2) var(--space-4);
			font-size: var(--text-sm);
		}
	}

	.tag-filter {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: var(--space-2);
		margin-bottom: var(--space-6);
	}

	.tag-chip {
		padding: var(--space-1) var(--space-3);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-full, 999px);
		background: var(--bg-card);
		color: var(--text-secondary);
		font-size: var(--text-sm);
		text-decoration: none;
		transition: all var(--transition-fast);
	}

	.tag-chip:hover {
		background: var(--bg-surface);
	}

	.tag-chip.active {
		background: var(--color-marinara-500);
		border-color: var(--color-marinara-500);
		color: var(--color-white);
	}

	.manage-tags {
		margin-left: auto;
		font-size: var(--text-sm);
		color: var(--color-marinara-600);
	}

	.tag-filter-empty {
		margin: 0 0 var(--space-6);
		text-align: right;
	}

	.load-more {
		display: flex;
		justify-content: center;
		margin-top: var(--space-8);
	}

	.load-more button {
		padding: var(--space-3) var(--space-6);
		background: var(--bg-card);
		color: var(--color-marinara-600);
		border: var(--border-width-thin) solid var(--color-marinara-500);
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
		cursor: pointer;
	}

	.load-more button:hover:not(:disabled) {
		background: var(--color-marinara-50);
	}

	.load-more button:disabled {
		opacity: 0.6;
		cursor: default;
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
	}

	.btn-primary {
		background: var(--color-marinara-600);
		color: var(--color-white);
		padding: var(--space-3) var(--space-6);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.btn-primary:hover {
		background: var(--color-marinara-700);
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
		margin-bottom: var(--space-5);
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
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
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
		margin-bottom: var(--space-4);
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
		text-decoration: none;
	}

	a.tag:hover {
		background: var(--color-gray-300);
		color: var(--text-primary);
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
