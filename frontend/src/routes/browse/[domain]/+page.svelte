<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { browse, type Recipe } from '$lib/api/client';

	let recipeList = $state<Recipe[]>([]);
	let loading = $state(true);
	let error = $state('');
	let searchQuery = $state('');
	let total = $state(0);
	let currentPage = $state(1);
	const pageSize = 24;

	const domain = $derived($page.params.domain);
	const totalPages = $derived(Math.ceil(total / pageSize));

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	$effect(() => {
		if (domain) {
			loadRecipes();
		}
	});

	async function loadRecipes() {
		const token = authStore.getToken();
		if (!token || !domain) return;

		loading = true;
		error = '';

		try {
			const params: { q?: string; limit: number; offset: number } = {
				limit: pageSize,
				offset: (currentPage - 1) * pageSize
			};
			if (searchQuery) params.q = searchQuery;
			const result = await browse.recipesByDomain(token, domain, params);
			recipeList = result.data;
			total = result.total;
		} catch (err) {
			error = 'Failed to load recipes';
		} finally {
			loading = false;
		}
	}

	async function handleSearch(e: Event) {
		e.preventDefault();
		currentPage = 1;
		await loadRecipes();
	}

	async function goToPage(page: number) {
		currentPage = page;
		await loadRecipes();
		window.scrollTo({ top: 0, behavior: 'smooth' });
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}
</script>

<div class="browse-domain-page">
	<header class="page-header">
		<a href="/browse" class="back-link">← Back to sources</a>
		<h1>{domain}</h1>
	</header>

	<form class="search-form" onsubmit={handleSearch}>
		<input type="search" bind:value={searchQuery} placeholder="Search recipes..." />
		<button type="submit">Search</button>
	</form>

	{#if loading}
		<div class="loading">Loading recipes...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if recipeList.length === 0}
		<div class="empty">
			<p>No recipes found{searchQuery ? ` matching "${searchQuery}"` : ' for this source'}.</p>
		</div>
	{:else}
		<div class="results-info">
			Showing {(currentPage - 1) * pageSize + 1}-{Math.min(currentPage * pageSize, total)} of {total} recipes
		</div>

		<div class="recipe-grid">
			{#each recipeList as recipe}
				<a href="/browse/{domain}/{recipe.id}" class="recipe-card">
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="recipe-image" />
					{:else}
						<div class="recipe-image placeholder">No image</div>
					{/if}
					<div class="recipe-content">
						<h2>{recipe.title}</h2>
						{#if recipe.description}
							<p class="description">{recipe.description.slice(0, 100)}...</p>
						{/if}
						<div class="recipe-meta">
							{#if recipe.total_time_minutes}
								<span class="time">{formatTime(recipe.total_time_minutes)}</span>
							{/if}
							{#if recipe.ingredients?.length}
								<span class="ingredients">{recipe.ingredients.length} ingredients</span>
							{/if}
						</div>
					</div>
				</a>
			{/each}
		</div>

		{#if totalPages > 1}
			<div class="pagination">
				<button
					onclick={() => goToPage(currentPage - 1)}
					disabled={currentPage === 1}
					class="page-btn"
				>
					← Previous
				</button>

				<div class="page-numbers">
					{#if currentPage > 2}
						<button onclick={() => goToPage(1)} class="page-btn">1</button>
						{#if currentPage > 3}
							<span class="ellipsis">...</span>
						{/if}
					{/if}

					{#each Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
						const start = Math.max(1, Math.min(currentPage - 2, totalPages - 4));
						return start + i;
					}).filter(p => p <= totalPages) as pageNum}
						<button
							onclick={() => goToPage(pageNum)}
							class="page-btn"
							class:active={pageNum === currentPage}
						>
							{pageNum}
						</button>
					{/each}

					{#if currentPage < totalPages - 1}
						{#if currentPage < totalPages - 2}
							<span class="ellipsis">...</span>
						{/if}
						<button onclick={() => goToPage(totalPages)} class="page-btn">{totalPages}</button>
					{/if}
				</div>

				<button
					onclick={() => goToPage(currentPage + 1)}
					disabled={currentPage === totalPages}
					class="page-btn"
				>
					Next →
				</button>
			</div>
		{/if}
	{/if}
</div>

<style>
	.browse-domain-page {
		max-width: 100%;
	}

	.page-header {
		margin-bottom: var(--space-8);
	}

	.back-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
		display: inline-block;
		margin-bottom: var(--space-2);
	}

	.back-link:hover {
		text-decoration: underline;
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
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

	.loading,
	.error,
	.empty {
		text-align: center;
		padding: var(--space-12);
	}

	.error {
		color: var(--color-error);
	}

	.recipe-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: var(--space-6);
	}

	.recipe-card {
		display: block;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-md);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-normal);
	}

	.recipe-card:hover {
		transform: translateY(-2px);
		box-shadow: var(--shadow-lg);
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
		color: var(--color-marinara-800);
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
	}

	.results-info {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin-bottom: var(--space-4);
	}

	.pagination {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: var(--space-2);
		margin-top: var(--space-8);
		padding-top: var(--space-8);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.page-numbers {
		display: flex;
		align-items: center;
		gap: var(--space-1);
	}

	.page-btn {
		padding: var(--space-2) var(--space-4);
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all var(--transition-fast);
	}

	.page-btn:hover:not(:disabled) {
		background: var(--bg-surface);
		border-color: var(--color-marinara-500);
	}

	.page-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.page-btn.active {
		background: var(--color-marinara-500);
		color: var(--color-white);
		border-color: var(--color-marinara-500);
	}

	.ellipsis {
		padding: 0 var(--space-2);
		color: var(--text-muted);
	}
</style>
