<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, isAdmin } from '$lib/stores/auth';
	import {
		admin,
		type AdminPreparation,
		type AdminPreparationOptions
	} from '$lib/api/client';

	let preparations = $state<AdminPreparation[]>([]);
	let options = $state<AdminPreparationOptions | null>(null);
	let loading = $state(true);
	let error = $state('');
	let message = $state('');

	// Filters
	let categoryFilter = $state('');
	let searchQuery = $state('');

	// Modal
	let showModal = $state(false);
	let modalMode = $state<'create' | 'edit'>('create');
	let modalSaving = $state(false);
	let modalError = $state('');

	// Modal form fields
	let editId = $state('');
	let editName = $state('');
	let editDisplayName = $state('');
	let editCategory = $state('');
	let editVerb = $state('');
	let editAliases = $state('');
	let editMetadata = $state('{}');

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else if (!$isAdmin) {
			goto('/');
		}
	});

	onMount(async () => {
		await Promise.all([loadOptions(), loadPreparations()]);
	});

	async function loadOptions() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			options = await admin.preparations.options(token);
		} catch {
			// Options are optional
		}
	}

	async function loadPreparations() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';
		try {
			const params: { category?: string; search?: string } = {};
			if (categoryFilter) params.category = categoryFilter;
			if (searchQuery) params.search = searchQuery;

			const result = await admin.preparations.list(token, params);
			preparations = result.data;
		} catch {
			error = 'Failed to load preparations';
		} finally {
			loading = false;
		}
	}

	function openCreateModal() {
		modalMode = 'create';
		editId = '';
		editName = '';
		editDisplayName = '';
		editCategory = '';
		editVerb = '';
		editAliases = '';
		editMetadata = '{}';
		modalError = '';
		showModal = true;
	}

	function openEditModal(prep: AdminPreparation) {
		modalMode = 'edit';
		editId = prep.id;
		editName = prep.name;
		editDisplayName = prep.display_name;
		editCategory = prep.category || '';
		editVerb = prep.verb || '';
		editAliases = (prep.aliases || []).join(', ');
		editMetadata = JSON.stringify(prep.metadata || {}, null, 2);
		modalError = '';
		showModal = true;
	}

	function closeModal() {
		showModal = false;
		modalError = '';
	}

	async function saveModal() {
		const token = authStore.getToken();
		if (!token) return;

		// Validate metadata JSON
		let parsedMetadata: Record<string, unknown> = {};
		try {
			const trimmed = editMetadata.trim();
			if (trimmed && trimmed !== '{}') {
				parsedMetadata = JSON.parse(trimmed);
			}
		} catch {
			modalError = 'Invalid JSON in metadata';
			return;
		}

		const aliases = editAliases
			.split(',')
			.map((a) => a.trim())
			.filter((a) => a.length > 0);

		const attrs = {
			name: editName,
			display_name: editDisplayName,
			category: editCategory || undefined,
			verb: editVerb || undefined,
			aliases,
			metadata: parsedMetadata
		};

		modalSaving = true;
		modalError = '';

		try {
			if (modalMode === 'create') {
				const result = await admin.preparations.create(token, attrs as Parameters<typeof admin.preparations.create>[1]);
				preparations = [...preparations, result.data];
				message = `Created preparation "${result.data.display_name}"`;
			} else {
				const result = await admin.preparations.update(token, editId, attrs);
				preparations = preparations.map((p) => (p.id === editId ? result.data : p));
				message = `Updated preparation "${result.data.display_name}"`;
			}
			closeModal();
		} catch {
			modalError = `Failed to ${modalMode} preparation`;
		} finally {
			modalSaving = false;
		}
	}

	async function deletePreparation(prep: AdminPreparation) {
		if (!confirm(`Delete preparation "${prep.display_name}"? This cannot be undone.`)) {
			return;
		}

		const token = authStore.getToken();
		if (!token) return;

		try {
			await admin.preparations.delete(token, prep.id);
			preparations = preparations.filter((p) => p.id !== prep.id);
			message = `Deleted preparation "${prep.display_name}"`;
		} catch {
			error = 'Failed to delete preparation';
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
			loadPreparations();
		}, 300);
	}
</script>

<div class="admin-page">
	<div class="page-header">
		<h1>Admin: Preparations</h1>
		<button onclick={openCreateModal} class="btn-primary">Add Preparation</button>
	</div>

	{#if message}
		<p class="message">{message}</p>
	{/if}

	{#if error}
		<p class="error">{error}</p>
	{/if}

	<section class="filters">
		<div class="filter-row">
			<label>
				<span>Category</span>
				<select bind:value={categoryFilter} onchange={() => loadPreparations()}>
					<option value="">All Categories</option>
					{#if options?.categories}
						{#each options.categories as cat}
							<option value={cat}>{formatLabel(cat)}</option>
						{/each}
					{/if}
				</select>
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

	{#if loading}
		<p class="loading">Loading preparations...</p>
	{:else if preparations.length === 0}
		<p class="empty">No preparations found matching the filters.</p>
	{:else}
		<p class="count">Showing {preparations.length} preparations</p>
		<table class="preparations-table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Display Name</th>
					<th>Category</th>
					<th>Verb</th>
					<th>Aliases</th>
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				{#each preparations as prep}
					<tr>
						<td class="name-cell">
							<span class="mono-name">{prep.name}</span>
						</td>
						<td>{prep.display_name}</td>
						<td>
							{#if prep.category}
								<span class="category-badge">{formatLabel(prep.category)}</span>
							{:else}
								<span class="missing">-</span>
							{/if}
						</td>
						<td class="verb-cell">{prep.verb || '-'}</td>
						<td class="aliases-cell">
							{#if prep.aliases && prep.aliases.length > 0}
								<div class="alias-list">
									{#each prep.aliases as alias}
										<span class="alias-badge">{alias}</span>
									{/each}
								</div>
							{:else}
								<span class="missing">-</span>
							{/if}
						</td>
						<td class="actions-cell">
							<button onclick={() => openEditModal(prep)} class="edit-btn">Edit</button>
							<button onclick={() => deletePreparation(prep)} class="delete-btn">Delete</button>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/if}
</div>

<!-- Create/Edit Modal -->
{#if showModal}
	<div class="modal-backdrop" onclick={closeModal} onkeydown={(e) => e.key === 'Escape' && closeModal()} role="dialog" aria-modal="true" tabindex="-1">
		<div class="modal" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.key === 'Escape' && closeModal()} role="document" tabindex="-1">
			<div class="modal-header">
				<h2>{modalMode === 'create' ? 'Add Preparation' : 'Edit Preparation'}</h2>
				<button class="modal-close" onclick={closeModal}>&times;</button>
			</div>
			<div class="modal-body">
				<div class="form-group">
					<label for="prep-name">Name</label>
					<input id="prep-name" type="text" bind:value={editName} placeholder="e.g., diced" />
					<span class="form-help">Unique lowercase identifier (auto-lowercased on save)</span>
				</div>

				<div class="form-group">
					<label for="prep-display-name">Display Name</label>
					<input id="prep-display-name" type="text" bind:value={editDisplayName} placeholder="e.g., Diced" />
				</div>

				<div class="form-group">
					<label for="prep-category">Category</label>
					<select id="prep-category" bind:value={editCategory}>
						<option value="">None</option>
						{#if options?.categories}
							{#each options.categories as cat}
								<option value={cat}>{formatLabel(cat)}</option>
							{/each}
						{/if}
					</select>
				</div>

				<div class="form-group">
					<label for="prep-verb">Verb</label>
					<input id="prep-verb" type="text" bind:value={editVerb} placeholder="e.g., dice" />
					<span class="form-help">The action form of the preparation word</span>
				</div>

				<div class="form-group">
					<label for="prep-aliases">Aliases</label>
					<input id="prep-aliases" type="text" bind:value={editAliases} placeholder="e.g., cubed, cut into cubes" />
					<span class="form-help">Comma-separated alternative names</span>
				</div>

				<div class="form-group">
					<label for="prep-metadata">Metadata (JSON)</label>
					<textarea id="prep-metadata" bind:value={editMetadata} rows="5" spellcheck="false" class="metadata-editor"></textarea>
					<span class="form-help">Optional metadata like tool, time_per_cup, time_min, etc.</span>
				</div>

				{#if modalError}
					<p class="error">{modalError}</p>
				{/if}
			</div>
			<div class="modal-footer">
				<button class="btn-secondary" onclick={closeModal}>Cancel</button>
				<button class="btn-primary" onclick={saveModal} disabled={modalSaving || !editName.trim() || !editDisplayName.trim()}>
					{modalSaving ? 'Saving...' : (modalMode === 'create' ? 'Create' : 'Save')}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.admin-page {
		max-width: 1200px;
	}

	.page-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: var(--space-6);
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
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

	.error {
		color: var(--color-error);
		background: rgba(27, 58, 45, 0.1);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	.message {
		color: var(--color-basil-700);
		background: var(--color-basil-100);
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

	.preparations-table {
		width: 100%;
		border-collapse: collapse;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-sm);
	}

	.preparations-table th {
		background: var(--color-pasta-100);
		padding: var(--space-3) var(--space-4);
		text-align: left;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.preparations-table td {
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.preparations-table tbody tr:hover {
		background: var(--color-pasta-50);
	}

	.mono-name {
		font-family: monospace;
		font-weight: var(--font-medium);
	}

	.category-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.verb-cell {
		color: var(--text-secondary);
		font-style: italic;
	}

	.alias-list {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-1);
	}

	.alias-badge {
		display: inline-block;
		padding: 2px var(--space-2);
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
	}

	.missing {
		color: var(--text-muted);
	}

	.actions-cell {
		white-space: nowrap;
	}

	.edit-btn,
	.delete-btn {
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

	.delete-btn {
		background: #fee2e2;
		color: #a32828;
	}

	.delete-btn:hover {
		background: #fecaca;
	}

	/* Button styles */
	.btn-primary {
		background: var(--color-marinara-600);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-primary:hover {
		background: var(--color-marinara-700);
	}

	.btn-primary:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.btn-secondary {
		background: var(--color-gray-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-secondary:hover {
		background: var(--color-gray-600);
	}

	/* Modal */
	.modal-backdrop {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.5);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
	}

	.modal {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		width: 90%;
		max-width: 550px;
		max-height: 90vh;
		overflow: hidden;
		display: flex;
		flex-direction: column;
		box-shadow: var(--shadow-lg);
	}

	.modal-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.modal-header h2 {
		margin: 0;
		font-size: var(--text-lg);
	}

	.modal-close {
		background: none;
		border: none;
		font-size: var(--text-2xl);
		cursor: pointer;
		color: var(--text-muted);
		line-height: 1;
		padding: 0;
	}

	.modal-close:hover {
		color: var(--text-primary);
	}

	.modal-body {
		padding: var(--space-4);
		overflow-y: auto;
		flex: 1;
	}

	.modal-footer {
		display: flex;
		justify-content: flex-end;
		gap: var(--space-3);
		padding: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.modal-footer button {
		min-width: 100px;
	}

	.form-group {
		margin-bottom: var(--space-4);
	}

	.form-group label {
		display: block;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
		margin-bottom: var(--space-1);
	}

	.form-group input,
	.form-group select,
	.form-group textarea {
		width: 100%;
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		box-sizing: border-box;
	}

	.form-group input:focus,
	.form-group select:focus,
	.form-group textarea:focus {
		outline: none;
		border-color: var(--color-marinara-600);
		box-shadow: 0 0 0 2px var(--color-basil-100);
	}

	.form-help {
		display: block;
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-top: var(--space-1);
	}

	.metadata-editor {
		font-family: monospace;
		resize: vertical;
	}
</style>
