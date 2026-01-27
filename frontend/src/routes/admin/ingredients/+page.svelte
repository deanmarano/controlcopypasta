<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { admin, type AdminIngredient, type AdminIngredientOptions } from '$lib/api/client';

	let ingredients = $state<AdminIngredient[]>([]);
	let options = $state<AdminIngredientOptions | null>(null);
	let loading = $state(true);
	let error = $state('');
	let accessDenied = $state(false);

	// Filters
	let categoryFilter = $state('protein');
	let animalTypeFilter = $state('');
	let showMissingOnly = $state(true);
	let searchQuery = $state('');

	// Editing
	let editingId = $state<string | null>(null);
	let editingValue = $state<string | null>(null);
	let saving = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await loadOptions();
		await loadIngredients();
	});

	async function loadOptions() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			options = await admin.ingredients.options(token);
		} catch {
			// Options are optional
		}
	}

	async function loadIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';
		try {
			const params: {
				category?: string;
				animal_type?: string;
				missing_animal_type?: boolean;
				search?: string;
			} = {};

			if (categoryFilter) params.category = categoryFilter;
			if (animalTypeFilter) params.animal_type = animalTypeFilter;
			if (showMissingOnly) params.missing_animal_type = true;
			if (searchQuery) params.search = searchQuery;

			const result = await admin.ingredients.list(token, params);
			ingredients = result.data;
		} catch (e) {
			if (e instanceof Error && 'status' in e && (e as { status: number }).status === 403) {
				accessDenied = true;
			} else {
				error = 'Failed to load ingredients';
			}
		} finally {
			loading = false;
		}
	}

	function startEdit(ingredient: AdminIngredient) {
		editingId = ingredient.id;
		editingValue = ingredient.animal_type;
	}

	function cancelEdit() {
		editingId = null;
		editingValue = null;
	}

	async function saveEdit(ingredient: AdminIngredient) {
		const token = authStore.getToken();
		if (!token || editingId !== ingredient.id) return;

		saving = true;
		try {
			const result = await admin.ingredients.update(token, ingredient.id, {
				animal_type: editingValue || null
			});
			// Update the ingredient in the list
			ingredients = ingredients.map((i) => (i.id === ingredient.id ? result.data : i));
			editingId = null;
			editingValue = null;
		} catch {
			error = 'Failed to save changes';
		} finally {
			saving = false;
		}
	}

	async function quickSetAnimalType(ingredient: AdminIngredient, animalType: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await admin.ingredients.update(token, ingredient.id, {
				animal_type: animalType
			});
			ingredients = ingredients.map((i) => (i.id === ingredient.id ? result.data : i));
		} catch {
			error = 'Failed to save changes';
		}
	}

	function formatLabel(value: string): string {
		return value
			.split('_')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}

	// Debounced search
	let searchTimeout: ReturnType<typeof setTimeout>;
	function handleSearchInput() {
		clearTimeout(searchTimeout);
		searchTimeout = setTimeout(() => {
			loadIngredients();
		}, 300);
	}
</script>

<div class="admin-page">
	<h1>Admin: Ingredients</h1>

	{#if accessDenied}
		<div class="access-denied">
			<h2>Access Denied</h2>
			<p>You do not have permission to view this page. Admin access is required.</p>
			<a href="/settings">Back to Settings</a>
		</div>
	{:else}

	<section class="filters">
		<div class="filter-row">
			<label>
				<span>Category</span>
				<select bind:value={categoryFilter} onchange={() => loadIngredients()}>
					<option value="">All Categories</option>
					{#if options?.categories}
						{#each options.categories as cat}
							<option value={cat}>{formatLabel(cat)}</option>
						{/each}
					{/if}
				</select>
			</label>

			<label>
				<span>Animal Type</span>
				<select bind:value={animalTypeFilter} onchange={() => loadIngredients()}>
					<option value="">All Types</option>
					{#if options?.animal_types}
						{#each options.animal_types as type}
							<option value={type}>{formatLabel(type)}</option>
						{/each}
					{/if}
				</select>
			</label>

			<label class="checkbox-label">
				<input
					type="checkbox"
					bind:checked={showMissingOnly}
					onchange={() => loadIngredients()}
				/>
				<span>Show only missing animal_type</span>
			</label>

			<label>
				<span>Search</span>
				<input
					type="text"
					bind:value={searchQuery}
					oninput={handleSearchInput}
					placeholder="Search by name..."
				/>
			</label>
		</div>
	</section>

	{#if error}
		<p class="error">{error}</p>
	{/if}

	{#if loading}
		<p class="loading">Loading ingredients...</p>
	{:else if ingredients.length === 0}
		<p class="empty">No ingredients found matching the filters.</p>
	{:else}
		<p class="count">Showing {ingredients.length} ingredients</p>
		<table class="ingredients-table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Category</th>
					<th>Subcategory</th>
					<th>Animal Type</th>
					<th>Usage</th>
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				{#each ingredients as ingredient}
					<tr>
						<td class="name-cell">
							<span class="display-name">{ingredient.display_name}</span>
							{#if ingredient.name !== ingredient.display_name.toLowerCase()}
								<span class="canonical-name">({ingredient.name})</span>
							{/if}
						</td>
						<td>{ingredient.category ? formatLabel(ingredient.category) : '-'}</td>
						<td>{ingredient.subcategory ? formatLabel(ingredient.subcategory) : '-'}</td>
						<td class="animal-type-cell">
							{#if editingId === ingredient.id}
								<select bind:value={editingValue} disabled={saving}>
									<option value="">None</option>
									{#if options?.animal_types}
										{#each options.animal_types as type}
											<option value={type}>{formatLabel(type)}</option>
										{/each}
									{/if}
								</select>
							{:else if ingredient.animal_type}
								<span class="animal-badge">{formatLabel(ingredient.animal_type)}</span>
							{:else}
								<span class="missing">Not set</span>
							{/if}
						</td>
						<td class="usage-cell">{ingredient.usage_count}</td>
						<td class="actions-cell">
							{#if editingId === ingredient.id}
								<button onclick={() => saveEdit(ingredient)} disabled={saving} class="save-btn">
									{saving ? '...' : 'Save'}
								</button>
								<button onclick={cancelEdit} disabled={saving} class="cancel-btn">Cancel</button>
							{:else}
								<button onclick={() => startEdit(ingredient)} class="edit-btn">Edit</button>

								{#if !ingredient.animal_type}
									<div class="quick-set">
										{#each ['chicken', 'beef', 'pork', 'egg', 'salmon', 'shrimp'] as type}
											<button
												onclick={() => quickSetAnimalType(ingredient, type)}
												class="quick-btn"
												title="Set to {type}"
											>
												{type.slice(0, 3)}
											</button>
										{/each}
									</div>
								{/if}
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/if}
	{/if}
</div>

<style>
	.admin-page {
		max-width: 1200px;
	}

	h1 {
		margin: 0 0 var(--space-6);
		color: var(--color-marinara-800);
	}

	.access-denied {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		text-align: center;
		box-shadow: var(--shadow-sm);
	}

	.access-denied h2 {
		color: var(--color-marinara-600);
		margin: 0 0 var(--space-3);
	}

	.access-denied p {
		color: var(--text-secondary);
		margin: 0 0 var(--space-4);
	}

	.access-denied a {
		color: var(--color-basil-600);
		font-weight: var(--font-medium);
	}

	.filters {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		margin-bottom: var(--space-6);
		box-shadow: var(--shadow-sm);
	}

	.filter-row {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-4);
		align-items: flex-end;
	}

	.filter-row label {
		display: flex;
		flex-direction: column;
		gap: var(--space-1);
	}

	.filter-row label span {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.filter-row select,
	.filter-row input[type='text'] {
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		min-width: 150px;
	}

	.checkbox-label {
		flex-direction: row !important;
		align-items: center !important;
		gap: var(--space-2) !important;
	}

	.checkbox-label input[type='checkbox'] {
		width: 18px;
		height: 18px;
	}

	.error {
		color: var(--color-error);
		background: rgba(220, 74, 61, 0.1);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	.loading,
	.empty {
		color: var(--text-muted);
		font-style: italic;
		text-align: center;
		padding: var(--space-8);
	}

	.count {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin-bottom: var(--space-3);
	}

	.ingredients-table {
		width: 100%;
		border-collapse: collapse;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-sm);
	}

	.ingredients-table th {
		background: var(--color-pasta-100);
		padding: var(--space-3) var(--space-4);
		text-align: left;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.ingredients-table td {
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.ingredients-table tbody tr:hover {
		background: var(--color-pasta-50);
	}

	.name-cell {
		min-width: 200px;
	}

	.display-name {
		font-weight: var(--font-medium);
	}

	.canonical-name {
		color: var(--text-muted);
		font-size: var(--text-xs);
		display: block;
	}

	.animal-type-cell select {
		padding: var(--space-1) var(--space-2);
		font-size: var(--text-sm);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-sm);
	}

	.animal-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.missing {
		color: var(--text-muted);
		font-style: italic;
	}

	.usage-cell {
		text-align: right;
		color: var(--text-muted);
	}

	.actions-cell {
		white-space: nowrap;
	}

	.edit-btn,
	.save-btn,
	.cancel-btn {
		padding: var(--space-1) var(--space-2);
		border: none;
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		cursor: pointer;
		margin-right: var(--space-1);
	}

	.edit-btn {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.edit-btn:hover {
		background: var(--color-pasta-200);
	}

	.save-btn {
		background: var(--color-basil-500);
		color: white;
	}

	.save-btn:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.cancel-btn {
		background: var(--color-gray-200);
		color: var(--color-gray-700);
	}

	.cancel-btn:hover:not(:disabled) {
		background: var(--color-gray-300);
	}

	.quick-set {
		display: inline-flex;
		gap: 2px;
		margin-left: var(--space-2);
	}

	.quick-btn {
		padding: 2px 4px;
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-surface);
		border-radius: var(--radius-sm);
		font-size: 10px;
		cursor: pointer;
		text-transform: capitalize;
	}

	.quick-btn:hover {
		background: var(--color-pasta-100);
		border-color: var(--color-pasta-300);
	}
</style>
