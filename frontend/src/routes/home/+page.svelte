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

	function getGreeting(): string {
		const hour = new Date().getHours();
		if (hour < 12) return 'Good morning.';
		if (hour < 17) return 'Good afternoon.';
		return 'Good evening.';
	}

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
		<header class="dash-header">
			<div class="greeting">
				<h1>{getGreeting()}</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<form class="add-recipe-form" onsubmit={handleAddRecipe}>
				<input
					type="url"
					bind:value={addUrl}
					placeholder="Paste a recipe URL..."
				/>
				<button type="submit" disabled={!addUrl}>Save</button>
			</form>
		</header>

		<section class="section">
			<div class="section-header">
				<h2>Tonight's inspiration</h2>
				<button class="shuffle-btn" onclick={shuffle} disabled={shuffling}>
					{shuffling ? 'Shuffling...' : 'Shuffle'}
				</button>
			</div>
			{#if data.dinner_ideas.length === 0}
				<p class="section-empty">No recipes to suggest yet.</p>
			{:else}
				{@const heroRecipe = data.dinner_ideas[0]}
				<a href="/recipes/{heroRecipe.id}" class="hero-card">
					{#if heroRecipe.image_url}
						<img src={heroRecipe.image_url} alt={heroRecipe.title} class="hero-card-img" />
					{:else}
						<div class="hero-card-img placeholder">No image</div>
					{/if}
					<div class="hero-card-overlay">
						{#if heroRecipe.total_time_minutes}
							<span class="hero-card-tag">{formatTime(heroRecipe.total_time_minutes)}</span>
						{/if}
						<h3>{heroRecipe.title}</h3>
						{#if heroRecipe.description}
							<p>{heroRecipe.description}</p>
						{/if}
						{#if !heroRecipe.is_owned}
							<button
								class="save-btn save-btn-hero"
								onclick={(e) => saveRecipe(e, heroRecipe.id)}
								disabled={savingId === heroRecipe.id}
							>
								{savingId === heroRecipe.id ? 'Saving...' : 'Save to My Recipes'}
							</button>
						{/if}
					</div>
					{#if heroRecipe.contains_avoided && heroRecipe.avoided_ingredients && heroRecipe.avoided_ingredients.length > 0}
						<div class="avoided-warning hero-avoided">
							Contains: {heroRecipe.avoided_ingredients.map((i) => i.name).join(', ')}
						</div>
					{/if}
				</a>
				{#if data.dinner_ideas.length > 1}
					<div class="card-grid">
						{#each data.dinner_ideas.slice(1) as recipe}
							{@render recipeCard(recipe)}
						{/each}
					</div>
				{/if}
			{/if}
		</section>

		<section class="section">
			<div class="section-header">
				<h2>Recently added</h2>
				<a href="/recipes" class="view-all">View all</a>
			</div>
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

	/* Dashboard header with greeting */
	.dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: var(--space-10);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.greeting h1 {
		font-family: var(--font-serif);
		font-size: var(--text-4xl);
		margin: 0;
		color: var(--color-marinara-800);
	}

	.greeting p {
		margin: var(--space-1) 0 0;
		color: var(--color-marinara-500);
		font-size: var(--text-base);
	}

	.add-recipe-form {
		display: flex;
		gap: var(--space-2);
		max-width: 600px;
	}

	.add-recipe-form input {
		flex: 1;
		padding: var(--space-3) var(--space-4);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		transition: all var(--transition-fast);
		min-width: 280px;
	}

	.add-recipe-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.add-recipe-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-600);
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
		background: var(--color-marinara-700);
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
		align-items: baseline;
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

	.view-all {
		color: var(--color-marinara-600);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		text-decoration: none;
	}

	.view-all:hover {
		color: var(--color-marinara-800);
		text-decoration: underline;
	}

	.section-empty {
		color: var(--text-muted);
		font-style: italic;
	}

	/* Hero card */
	.hero-card {
		display: block;
		position: relative;
		border-radius: var(--radius-lg);
		overflow: hidden;
		margin-bottom: var(--space-4);
		text-decoration: none;
		color: inherit;
		aspect-ratio: 21/9;
		transition: all var(--transition-normal);
	}

	.hero-card:hover {
		box-shadow: var(--shadow-lg);
	}

	.hero-card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.hero-card-img.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
	}

	.hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: var(--space-10) var(--space-6) var(--space-6);
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
		color: white;
	}

	.hero-card-overlay h3 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		margin: 0 0 var(--space-2);
		color: white;
		line-height: var(--leading-snug);
	}

	.hero-card-overlay p {
		margin: 0;
		font-size: var(--text-sm);
		opacity: 0.85;
		max-width: 500px;
	}

	.hero-card-tag {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		margin-bottom: var(--space-2);
		font-weight: var(--font-medium);
	}

	.save-btn-hero {
		margin-top: var(--space-3);
		width: auto;
		display: inline-block;
	}

	.hero-avoided {
		position: absolute;
		top: var(--space-3);
		right: var(--space-3);
	}

	/* Card grid */
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
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.save-btn:hover:not(:disabled) {
		background: var(--color-marinara-700);
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

	@media (max-width: 768px) {
		.dash-header {
			flex-direction: column;
			align-items: stretch;
			gap: var(--space-4);
		}

		.add-recipe-form {
			max-width: 100%;
		}

		.add-recipe-form input {
			min-width: 0;
		}

		.hero-card {
			aspect-ratio: 16/9;
		}
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
