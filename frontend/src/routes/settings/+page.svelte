<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { avoidedIngredients, type AvoidedIngredient } from '$lib/api/client';

	let items = $state<AvoidedIngredient[]>([]);
	let loading = $state(true);
	let newIngredient = $state('');
	let error = $state('');
	let adding = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(loadItems);

	async function loadItems() {
		const token = authStore.getToken();
		if (!token) return;
		loading = true;
		error = '';
		try {
			const result = await avoidedIngredients.list(token);
			items = result.data;
		} catch {
			error = 'Failed to load avoided ingredients';
		} finally {
			loading = false;
		}
	}

	async function addIngredient(e: Event) {
		e.preventDefault();
		if (!newIngredient.trim()) return;
		const token = authStore.getToken();
		if (!token) return;

		adding = true;
		error = '';
		try {
			const result = await avoidedIngredients.create(token, newIngredient.trim());
			items = [...items, result.data].sort((a, b) => a.display_name.localeCompare(b.display_name));
			newIngredient = '';
		} catch {
			error = 'Failed to add ingredient (may already exist in your list)';
		} finally {
			adding = false;
		}
	}

	async function removeIngredient(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await avoidedIngredients.delete(token, id);
			items = items.filter((i) => i.id !== id);
		} catch {
			error = 'Failed to remove ingredient';
		}
	}
</script>

<div class="settings-page">
	<h1>Settings</h1>

	<section class="settings-section">
		<h2>Security</h2>
		<a href="/settings/passkeys" class="settings-link">
			<span class="link-title">Passkeys</span>
			<span class="link-description">Manage passkeys for quick, secure sign-in</span>
		</a>
	</section>

	<section class="avoided-section">
		<h2>Avoided Ingredients</h2>
		<p class="description">
			Recipes containing these ingredients will be flagged with a warning. Useful for allergies,
			dietary restrictions, or personal preferences.
		</p>

		<form onsubmit={addIngredient} class="add-form">
			<input
				type="text"
				bind:value={newIngredient}
				placeholder="e.g., chicken, beef, peanuts, shellfish"
				disabled={adding}
			/>
			<button type="submit" disabled={adding || !newIngredient.trim()}>
				{adding ? 'Adding...' : 'Add'}
			</button>
		</form>

		{#if error}
			<p class="error">{error}</p>
		{/if}

		{#if loading}
			<p class="loading">Loading...</p>
		{:else if items.length === 0}
			<p class="empty">No avoided ingredients yet. Add ingredients above to get started.</p>
		{:else}
			<ul class="ingredient-list">
				{#each items as item}
					<li>
						<span class="name">{item.display_name}</span>
						{#if item.canonical_name !== item.display_name}
							<span class="canonical">(matches: {item.canonical_name})</span>
						{/if}
						<button onclick={() => removeIngredient(item.id)} class="remove">Remove</button>
					</li>
				{/each}
			</ul>
		{/if}
	</section>
</div>

<style>
	.settings-page {
		max-width: 600px;
	}

	h1 {
		margin: 0 0 var(--space-8);
		color: var(--color-marinara-800);
	}

	.settings-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
		margin-bottom: var(--space-6);
	}

	.settings-section h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
	}

	.settings-link {
		display: block;
		padding: var(--space-4);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-fast);
	}

	.settings-link:hover {
		background: var(--color-pasta-100);
	}

	.link-title {
		display: block;
		font-weight: var(--font-medium);
		color: var(--color-marinara-600);
		margin-bottom: var(--space-1);
	}

	.link-description {
		display: block;
		color: var(--text-secondary);
		font-size: var(--text-sm);
	}

	.avoided-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
	}

	h2 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
	}

	.description {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-6);
	}

	.add-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
	}

	.add-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.add-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.add-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.add-form button:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.add-form button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.error {
		color: var(--color-error);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-4);
	}

	.loading,
	.empty {
		color: var(--text-muted);
		font-style: italic;
	}

	.ingredient-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.ingredient-list li {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-3) 0;
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.ingredient-list li:last-child {
		border-bottom: none;
	}

	.name {
		font-weight: var(--font-medium);
	}

	.canonical {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.remove {
		margin-left: auto;
		background: none;
		border: none;
		color: var(--color-marinara-600);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: var(--space-1) var(--space-2);
	}

	.remove:hover {
		text-decoration: underline;
	}
</style>
