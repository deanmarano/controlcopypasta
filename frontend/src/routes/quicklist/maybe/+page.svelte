<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { quicklist, type DashboardRecipe } from '$lib/api/client';

	let recipes = $state<DashboardRecipe[]>([]);
	let loading = $state(true);
	let error = $state('');
	let removingId = $state<string | null>(null);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else {
			loadMaybeList();
		}
	});

	async function loadMaybeList() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await quicklist.maybeList(token);
			recipes = result.data;
		} catch {
			error = 'Failed to load maybe list';
		} finally {
			loading = false;
		}
	}

	async function removeRecipe(e: Event, recipeId: string) {
		e.preventDefault();
		e.stopPropagation();
		const token = authStore.getToken();
		if (!token) return;

		removingId = recipeId;
		try {
			await quicklist.removeMaybe(token, recipeId);
			recipes = recipes.filter((r) => r.id !== recipeId);
		} catch {
			// ignore
		} finally {
			removingId = null;
		}
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}
</script>

<div class="maybe-page">
	<header class="page-header">
		<a href="/quicklist" class="back-link">Back to swiping</a>
		<h1>Maybe List ({recipes.length})</h1>
	</header>

	{#if loading}
		<div class="loading">Loading...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if recipes.length === 0}
		<div class="empty">
			<h2>No maybes yet</h2>
			<p>Swipe right on recipes you might want to cook.</p>
			<a href="/quicklist" class="btn-primary">Find Dinner</a>
		</div>
	{:else}
		<div class="card-grid">
			{#each recipes as recipe (recipe.id)}
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
						<button
							class="remove-btn"
							onclick={(e) => removeRecipe(e, recipe.id)}
							disabled={removingId === recipe.id}
						>
							{removingId === recipe.id ? 'Removing...' : 'Remove'}
						</button>
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>

<style>
	.maybe-page {
		max-width: 900px;
		margin: 0 auto;
		padding: var(--space-4);
	}

	.page-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-6);
	}

	.page-header h1 {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		color: var(--color-marinara-800);
		margin: 0;
	}

	.back-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
	}

	.back-link:hover {
		text-decoration: underline;
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

	.empty {
		text-align: center;
		padding: var(--space-12) var(--space-4);
	}

	.empty h2 {
		font-family: var(--font-serif);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-3);
	}

	.empty p {
		color: var(--text-secondary);
		margin: 0 0 var(--space-6);
	}

	.btn-primary {
		display: inline-block;
		padding: var(--space-3) var(--space-6);
		background: var(--color-basil-600);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
	}

	.btn-primary:hover {
		background: var(--color-basil-700);
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

	.remove-btn {
		display: block;
		width: 100%;
		margin-top: var(--space-2);
		padding: var(--space-1) var(--space-2);
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.remove-btn:hover:not(:disabled) {
		background: var(--color-marinara-200);
	}

	.remove-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
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
	}

	@media (max-width: 400px) {
		.card-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
