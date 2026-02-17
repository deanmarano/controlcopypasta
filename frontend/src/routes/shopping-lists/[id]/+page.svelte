<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { shoppingLists, type ShoppingList, type ShoppingListItem } from '$lib/api/client';

	let list = $state<ShoppingList | null>(null);
	let loading = $state(true);
	let error = $state('');
	let newItemText = $state('');
	let adding = $state(false);

	const categoryLabels: Record<string, string> = {
		produce: 'Produce',
		dairy: 'Dairy',
		protein: 'Protein',
		bakery: 'Bakery',
		pantry: 'Pantry',
		frozen: 'Frozen',
		beverages: 'Beverages',
		condiments: 'Condiments',
		spices: 'Spices',
		other: 'Other'
	};

	const categoryOrder = ['produce', 'dairy', 'protein', 'bakery', 'pantry', 'frozen', 'beverages', 'condiments', 'spices', 'other'];

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadList();
	});

	async function loadList() {
		const token = authStore.getToken();
		const id = $page.params.id;
		if (!token || !id) return;

		loading = true;
		error = '';

		try {
			const result = await shoppingLists.get(token, id);
			list = result.data;
		} catch (err) {
			error = 'Failed to load shopping list';
		} finally {
			loading = false;
		}
	}

	async function addItem(e: Event) {
		e.preventDefault();
		if (!newItemText.trim() || !list) return;

		const token = authStore.getToken();
		if (!token) return;

		adding = true;
		try {
			await shoppingLists.createItem(token, list.id, { display_text: newItemText.trim() });
			newItemText = '';
			await loadList();
		} catch {
			alert('Failed to add item');
		} finally {
			adding = false;
		}
	}

	async function toggleItem(item: ShoppingListItem) {
		if (!list) return;
		const token = authStore.getToken();
		if (!token) return;

		try {
			if (item.checked_at) {
				await shoppingLists.uncheckItem(token, list.id, item.id);
			} else {
				await shoppingLists.checkItem(token, list.id, item.id);
			}
			await loadList();
		} catch {
			alert('Failed to update item');
		}
	}

	async function deleteItem(itemId: string) {
		if (!list) return;
		const token = authStore.getToken();
		if (!token) return;

		try {
			await shoppingLists.deleteItem(token, list.id, itemId);
			await loadList();
		} catch {
			alert('Failed to delete item');
		}
	}

	async function clearChecked() {
		if (!list) return;
		if (!confirm('Remove all checked items?')) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			await shoppingLists.clearChecked(token, list.id);
			await loadList();
		} catch {
			alert('Failed to clear checked items');
		}
	}

	function getItemsByCategory(items: ShoppingListItem[]): { category: string; label: string; items: ShoppingListItem[] }[] {
		const grouped = new Map<string, ShoppingListItem[]>();

		for (const item of items) {
			const cat = item.category || 'other';
			if (!grouped.has(cat)) {
				grouped.set(cat, []);
			}
			grouped.get(cat)!.push(item);
		}

		return categoryOrder
			.filter(cat => grouped.has(cat))
			.map(cat => ({
				category: cat,
				label: categoryLabels[cat] || cat,
				items: grouped.get(cat)!.sort((a, b) => {
					// Unchecked items first
					if (a.checked_at && !b.checked_at) return 1;
					if (!a.checked_at && b.checked_at) return -1;
					return 0;
				})
			}));
	}

	function getProgress(list: ShoppingList): { checked: number; total: number; percent: number } {
		const total = list.total_count || 0;
		const checked = list.checked_count || 0;
		const percent = total > 0 ? Math.round((checked / total) * 100) : 0;
		return { checked, total, percent };
	}
</script>

<div class="shopping-list-page">
	{#if loading}
		<div class="loading">Loading shopping list...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if list}
		<header class="page-header">
			<div class="header-left">
				<a href="/shopping-lists" class="back-link">&larr; All Lists</a>
				<h1>{list.name}</h1>
			</div>
			{#if list.total_count && list.total_count > 0}
				{@const progress = getProgress(list)}
				<div class="progress">
					<div class="progress-bar">
						<div class="progress-fill" style="width: {progress.percent}%"></div>
					</div>
					<span class="progress-text">{progress.checked}/{progress.total}</span>
				</div>
			{/if}
		</header>

		<form class="add-form" onsubmit={addItem}>
			<input
				type="text"
				bind:value={newItemText}
				placeholder="Add item..."
				disabled={adding}
			/>
			<button type="submit" disabled={adding || !newItemText.trim()}>Add</button>
		</form>

		{#if list.checked_count && list.checked_count > 0}
			<button class="clear-checked-btn" onclick={clearChecked}>
				Clear {list.checked_count} checked item{list.checked_count !== 1 ? 's' : ''}
			</button>
		{/if}

		{#if !list.items || list.items.length === 0}
			<div class="empty">
				<p>No items yet. Add items above or add from a recipe.</p>
			</div>
		{:else}
			<div class="items-list">
				{#each getItemsByCategory(list.items) as category}
					<div class="category-section">
						<h3 class="category-header">{category.label}</h3>
						<ul class="items">
							{#each category.items as item}
								<li class="item" class:checked={item.checked_at}>
									<label class="item-checkbox">
										<input
											type="checkbox"
											checked={!!item.checked_at}
											onchange={() => toggleItem(item)}
										/>
										<span class="item-text">{item.display_text}</span>
									</label>
									<button class="delete-btn" onclick={() => deleteItem(item.id)} aria-label="Delete item">
										&times;
									</button>
								</li>
							{/each}
						</ul>
					</div>
				{/each}
			</div>
		{/if}
	{/if}
</div>

<style>
	.shopping-list-page {
		max-width: 600px;
		margin: 0 auto;
	}

	.page-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: var(--space-6);
	}

	.header-left {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.back-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
	}

	.back-link:hover {
		text-decoration: underline;
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
	}

	.progress {
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.progress-bar {
		width: 100px;
		height: 8px;
		background: var(--color-gray-200);
		border-radius: var(--radius-sm);
		overflow: hidden;
	}

	.progress-fill {
		height: 100%;
		background: var(--color-marinara-600);
		transition: width var(--transition-normal);
	}

	.progress-text {
		font-size: var(--text-sm);
		color: var(--text-secondary);
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
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.add-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.add-form button:hover:not(:disabled) {
		background: var(--color-marinara-700);
	}

	.add-form button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.clear-checked-btn {
		width: 100%;
		padding: var(--space-2);
		background: var(--bg-surface);
		color: var(--text-secondary);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-md);
		cursor: pointer;
		margin-bottom: var(--space-4);
		transition: all var(--transition-fast);
	}

	.clear-checked-btn:hover {
		background: var(--color-gray-200);
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

	.items-list {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-md);
		overflow: hidden;
	}

	.category-section {
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.category-section:last-child {
		border-bottom: none;
	}

	.category-header {
		background: var(--color-pasta-100);
		padding: var(--space-3) var(--space-4);
		margin: 0;
		font-size: var(--text-sm);
		font-weight: var(--font-semibold);
		color: var(--text-secondary);
		text-transform: uppercase;
		letter-spacing: var(--tracking-wider);
	}

	.items {
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.item {
		display: flex;
		align-items: center;
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--color-gray-100);
		gap: var(--space-2);
	}

	.item:last-child {
		border-bottom: none;
	}

	.item.checked {
		background: var(--bg-surface);
	}

	.item.checked .item-text {
		text-decoration: line-through;
		color: var(--text-muted);
	}

	.item-checkbox {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		flex: 1;
		cursor: pointer;
	}

	.item-checkbox input {
		width: 20px;
		height: 20px;
		cursor: pointer;
		accent-color: var(--color-basil-500);
	}

	.item-text {
		flex: 1;
	}

	.delete-btn {
		background: none;
		border: none;
		color: var(--color-gray-300);
		font-size: var(--text-2xl);
		cursor: pointer;
		padding: 0 var(--space-1);
		line-height: 1;
		transition: all var(--transition-fast);
	}

	.delete-btn:hover {
		color: #c53030;
	}
</style>
