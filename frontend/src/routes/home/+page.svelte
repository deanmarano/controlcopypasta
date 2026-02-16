<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { dashboard, recipes as recipesApi, type DashboardData, type DashboardRecipe } from '$lib/api/client';

	let data = $state<DashboardData | null>(null);
	let loading = $state(true);
	let error = $state('');
	let addUrl = $state('');
	let shuffling = $state(false);
	let savingId = $state<string | null>(null);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else {
			loadDashboard();
		}
	});

	async function loadDashboard() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await dashboard.get(token);
			data = result.data;
		} catch {
			error = 'Failed to load dashboard';
		} finally {
			loading = false;
		}
	}

	async function shuffle() {
		const token = authStore.getToken();
		if (!token) return;

		shuffling = true;
		try {
			const result = await dashboard.get(token);
			if (data) {
				data.dinner_ideas = result.data.dinner_ideas;
			}
		} catch {
			// ignore shuffle errors
		} finally {
			shuffling = false;
		}
	}

	async function saveRecipe(e: Event, recipeId: string) {
		e.preventDefault();
		e.stopPropagation();
		const token = authStore.getToken();
		if (!token) return;

		savingId = recipeId;
		try {
			const result = await recipesApi.copy(token, recipeId);
			goto(`/recipes/${result.data.id}`);
		} catch {
			alert('Failed to save recipe');
		} finally {
			savingId = null;
		}
	}

	function handleAddRecipe(e: Event) {
		e.preventDefault();
		if (!addUrl) return;
		goto(`/recipes/new?url=${encodeURIComponent(addUrl)}`);
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}

	function isEmpty(d: DashboardData): boolean {
		return d.dinner_ideas.length === 0 && d.recently_added.length === 0 && d.this_time_last_year.length === 0;
	}
</script>

<div class="dashboard">
	{#if loading}
		<div class="loading">Loading...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if data && isEmpty(data)}
		<div class="empty-state">
			<h1>Welcome to ControlCopyPasta</h1>
			<p>You haven't added any recipes yet. Paste a URL below to get started!</p>
			<form class="add-recipe-form" onsubmit={handleAddRecipe}>
				<input
					type="url"
					bind:value={addUrl}
					placeholder="Paste a recipe URL..."
				/>
				<button type="submit" disabled={!addUrl}>Add Recipe</button>
			</form>
			<p class="alt-action">or <a href="/recipes/new">create one manually</a></p>
		</div>
	{:else if data}
		<section class="add-recipe-section">
			<form class="add-recipe-form" onsubmit={handleAddRecipe}>
				<input
					type="url"
					bind:value={addUrl}
					placeholder="Paste a recipe URL to add..."
				/>
				<button type="submit" disabled={!addUrl}>Add Recipe</button>
			</form>
		</section>

		<section class="section">
			<div class="section-header">
				<h2>Dinner Ideas</h2>
				<button class="shuffle-btn" onclick={shuffle} disabled={shuffling}>
					{shuffling ? 'Shuffling...' : 'Shuffle'}
				</button>
			</div>
			{#if data.dinner_ideas.length === 0}
				<p class="section-empty">No recipes to suggest yet.</p>
			{:else}
				<div class="card-grid">
					{#each data.dinner_ideas as recipe}
						{@render recipeCard(recipe)}
					{/each}
				</div>
			{/if}
		</section>

		<section class="section">
			<h2>Recently Added</h2>
			{#if data.recently_added.length === 0}
				<p class="section-empty">No recent recipes.</p>
			{:else}
				<div class="card-grid">
					{#each data.recently_added as recipe}
						{@render recipeCard(recipe)}
					{/each}
				</div>
			{/if}
		</section>

		{#if data.this_time_last_year.length > 0}
			<section class="section">
				<h2>This Time Last Year</h2>
				<div class="card-grid">
					{#each data.this_time_last_year as recipe}
						{@render recipeCard(recipe)}
					{/each}
				</div>
			</section>
		{/if}
	{/if}
</div>

{#snippet recipeCard(recipe: DashboardRecipe)}
	<a href="/recipes/{recipe.id}" class="recipe-card">
		{#if recipe.image_url}
			<img src={recipe.image_url} alt={recipe.title} class="recipe-image" />
		{:else}
			<div class="recipe-image placeholder">No image</div>
		{/if}
		<div class="recipe-content">
			<h3>{recipe.title}</h3>
			<div class="recipe-meta">
				{#if recipe.total_time_minutes}
					<span class="time">{formatTime(recipe.total_time_minutes)}</span>
				{/if}
				{#if recipe.source_domain}
					<span class="source">{recipe.source_domain}</span>
				{/if}
			</div>
			{#if !recipe.is_owned}
				<button
					class="save-btn"
					onclick={(e) => saveRecipe(e, recipe.id)}
					disabled={savingId === recipe.id}
				>
					{savingId === recipe.id ? 'Saving...' : 'Save to My Recipes'}
				</button>
			{/if}
			{#if recipe.contains_avoided && recipe.avoided_ingredients && recipe.avoided_ingredients.length > 0}
				<div class="avoided-warning">
					Contains: {recipe.avoided_ingredients.map((i) => i.name).join(', ')}
				</div>
			{/if}
		</div>
	</a>
{/snippet}

<style>
	.dashboard {
		max-width: 100%;
	}

	.loading,
	.error {
		text-align: center;
		padding: var(--space-12);
		color: var(--text-secondary);
	}

	.error {
		color: var(--color-error);
	}

	.empty-state {
		text-align: center;
		padding: var(--space-16) var(--space-4);
	}

	.empty-state h1 {
		font-family: var(--font-serif);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-4);
	}

	.empty-state p {
		color: var(--text-secondary);
		font-size: var(--text-lg);
		margin: 0 0 var(--space-8);
	}

	.alt-action {
		margin-top: var(--space-4) !important;
		font-size: var(--text-base) !important;
	}

	.alt-action a {
		color: var(--color-marinara-600);
	}

	.add-recipe-section {
		margin-bottom: var(--space-10);
	}

	.add-recipe-form {
		display: flex;
		gap: var(--space-2);
		max-width: 600px;
		margin: 0 auto;
	}

	.add-recipe-form input {
		flex: 1;
		padding: var(--space-4);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		transition: all var(--transition-fast);
	}

	.add-recipe-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.add-recipe-form button {
		padding: var(--space-4) var(--space-8);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		white-space: nowrap;
	}

	.add-recipe-form button:hover:not(:disabled) {
		background: var(--color-basil-600);
		box-shadow: var(--shadow-basil);
	}

	.add-recipe-form button:disabled {
		background: var(--color-gray-400);
	}

	.section {
		margin-bottom: var(--space-10);
	}

	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-4);
	}

	.section h2 {
		margin: 0 0 var(--space-4);
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		color: var(--color-marinara-700);
	}

	.section-header h2 {
		margin-bottom: 0;
	}

	.shuffle-btn {
		padding: var(--space-2) var(--space-4);
		background: var(--bg-card);
		color: var(--color-marinara-600);
		border: var(--border-width-thin) solid var(--color-marinara-500);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.shuffle-btn:hover:not(:disabled) {
		background: var(--color-marinara-50);
	}

	.shuffle-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.section-empty {
		color: var(--text-muted);
		font-style: italic;
	}

	.card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: var(--space-6);
	}

	.recipe-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-md);
		transition: all var(--transition-normal);
		text-decoration: none;
		color: inherit;
		display: block;
	}

	.recipe-card:hover {
		box-shadow: var(--shadow-lg);
		transform: translateY(-2px);
	}

	.recipe-image {
		width: 100%;
		height: 160px;
		object-fit: cover;
	}

	.recipe-image.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
		min-height: 160px;
	}

	.recipe-content {
		padding: var(--space-3) var(--space-4) var(--space-4);
	}

	h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-base);
		color: var(--color-marinara-800);
		line-height: var(--leading-snug);
	}

	.recipe-meta {
		display: flex;
		gap: var(--space-3);
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	.save-btn {
		display: block;
		width: 100%;
		margin-top: var(--space-2);
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.save-btn:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.save-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.avoided-warning {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		margin-top: var(--space-2);
		border: var(--border-width-thin) solid var(--color-pasta-400);
	}

	@media (max-width: 640px) {
		.card-grid {
			grid-template-columns: 1fr 1fr;
			gap: var(--space-3);
		}

		.recipe-image {
			height: 120px;
		}

		.recipe-image.placeholder {
			min-height: 120px;
		}

		.add-recipe-form {
			flex-direction: column;
		}
	}

	@media (max-width: 400px) {
		.card-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
