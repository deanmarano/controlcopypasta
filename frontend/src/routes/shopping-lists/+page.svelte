<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { shoppingLists, type ShoppingList } from '$lib/api/client';

	let lists = $state<ShoppingList[]>([]);
	let loading = $state(true);
	let error = $state('');
	let showArchived = $state(false);
	let newListName = $state('');
	let creating = $state(false);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadLists();
	});

	async function loadLists() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const params: { archived?: 'true' | 'all' } = {};
			if (showArchived) params.archived = 'true';
			const result = await shoppingLists.list(token, Object.keys(params).length > 0 ? params : undefined);
			lists = result.data;
		} catch (err) {
			error = 'Failed to load shopping lists';
		} finally {
			loading = false;
		}
	}

	async function createList(e: Event) {
		e.preventDefault();
		if (!newListName.trim()) return;

		const token = authStore.getToken();
		if (!token) return;

		creating = true;
		try {
			const result = await shoppingLists.create(token, { name: newListName.trim() });
			lists = [result.data, ...lists];
			newListName = '';
		} catch {
			alert('Failed to create shopping list');
		} finally {
			creating = false;
		}
	}

	async function deleteList(id: string) {
		if (!confirm('Are you sure you want to delete this shopping list?')) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			await shoppingLists.delete(token, id);
			lists = lists.filter((l) => l.id !== id);
		} catch {
			alert('Failed to delete shopping list');
		}
	}

	async function archiveList(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await shoppingLists.archive(token, id);
			lists = lists.filter((l) => l.id !== id);
		} catch {
			alert('Failed to archive shopping list');
		}
	}

	async function toggleShowArchived() {
		showArchived = !showArchived;
		await loadLists();
	}

	function formatDate(dateStr: string): string {
		return new Date(dateStr).toLocaleDateString();
	}
</script>

<div class="shopping-lists-page">
	<header class="page-header">
		<h1>Shopping Lists</h1>
	</header>

	<form class="create-form" onsubmit={createList}>
		<input
			type="text"
			bind:value={newListName}
			placeholder="New shopping list name..."
			disabled={creating}
		/>
		<button type="submit" disabled={creating || !newListName.trim()}>
			{creating ? 'Creating...' : 'Create List'}
		</button>
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
		<div class="loading">Loading shopping lists...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if lists.length === 0}
		<div class="empty">
			<p>{showArchived ? 'No archived shopping lists' : 'No shopping lists yet!'}</p>
			{#if !showArchived}
				<p>Create your first shopping list above.</p>
			{/if}
		</div>
	{:else}
		<div class="lists-grid">
			{#each lists as list}
				<div class="list-card">
					<div class="list-content">
						<h2><a href="/shopping-lists/{list.id}">{list.name}</a></h2>
						<div class="list-meta">
							<span class="date">Created {formatDate(list.inserted_at)}</span>
						</div>
						<div class="actions">
							<a href="/shopping-lists/{list.id}">View</a>
							{#if !showArchived}
								<button onclick={() => archiveList(list.id)} class="action-archive">Archive</button>
							{/if}
							<button onclick={() => deleteList(list.id)}>Delete</button>
						</div>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.shopping-lists-page {
		max-width: 800px;
		margin: 0 auto;
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

	.create-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-8);
	}

	.create-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.create-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.create-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.create-form button:hover:not(:disabled) {
		background: var(--color-marinara-700);
	}

	.create-form button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
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
	}

	.error {
		color: var(--color-error);
	}

	.lists-grid {
		display: grid;
		gap: var(--space-4);
	}

	.list-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		box-shadow: var(--shadow-md);
	}

	.list-content h2 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-xl);
	}

	.list-content h2 a {
		color: var(--color-marinara-800);
		text-decoration: none;
	}

	.list-content h2 a:hover {
		color: var(--color-marinara-600);
	}

	.list-meta {
		font-size: var(--text-sm);
		color: var(--text-muted);
		margin-bottom: var(--space-2);
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
</style>
