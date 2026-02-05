<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, isAdmin } from '$lib/stores/auth';
	import {
		admin,
		type AdminKitchenTool,
		type AdminKitchenToolOptions
	} from '$lib/api/client';

	let kitchenTools = $state<AdminKitchenTool[]>([]);
	let options = $state<AdminKitchenToolOptions | null>(null);
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
		await Promise.all([loadOptions(), loadKitchenTools()]);
	});

	async function loadOptions() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			options = await admin.kitchenTools.options(token);
		} catch {
			// Options are optional
		}
	}

	async function loadKitchenTools() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';
		try {
			const params: { category?: string; search?: string } = {};
			if (categoryFilter) params.category = categoryFilter;
			if (searchQuery) params.search = searchQuery;

			const result = await admin.kitchenTools.list(token, params);
			kitchenTools = result.data;
		} catch {
			error = 'Failed to load kitchen tools';
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
		editAliases = '';
		editMetadata = '{}';
		modalError = '';
		showModal = true;
	}

	function openEditModal(tool: AdminKitchenTool) {
		modalMode = 'edit';
		editId = tool.id;
		editName = tool.name;
		editDisplayName = tool.display_name;
		editCategory = tool.category || '';
		editAliases = (tool.aliases || []).join(', ');
		editMetadata = JSON.stringify(tool.metadata || {}, null, 2);
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
			aliases,
			metadata: parsedMetadata
		};

		modalSaving = true;
		modalError = '';

		try {
			if (modalMode === 'create') {
				const result = await admin.kitchenTools.create(token, attrs as Parameters<typeof admin.kitchenTools.create>[1]);
				kitchenTools = [...kitchenTools, result.data];
				message = `Created kitchen tool "${result.data.display_name}"`;
			} else {
				const result = await admin.kitchenTools.update(token, editId, attrs);
				kitchenTools = kitchenTools.map((t) => (t.id === editId ? result.data : t));
				message = `Updated kitchen tool "${result.data.display_name}"`;
			}
			closeModal();
		} catch {
			modalError = `Failed to ${modalMode} kitchen tool`;
		} finally {
			modalSaving = false;
		}
	}

	async function deleteKitchenTool(tool: AdminKitchenTool) {
		if (!confirm(`Delete kitchen tool "${tool.display_name}"? This cannot be undone.`)) {
			return;
		}

		const token = authStore.getToken();
		if (!token) return;

		try {
			await admin.kitchenTools.delete(token, tool.id);
			kitchenTools = kitchenTools.filter((t) => t.id !== tool.id);
			message = `Deleted kitchen tool "${tool.display_name}"`;
		} catch {
			error = 'Failed to delete kitchen tool';
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
			loadKitchenTools();
		}, 300);
	}
</script>

<div class="admin-page">
	<div class="page-header">
		<h1>Admin: Kitchen Tools</h1>
		<button onclick={openCreateModal} class="btn-primary">Add Kitchen Tool</button>
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
				<select bind:value={categoryFilter} onchange={() => loadKitchenTools()}>
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
		<p class="loading">Loading kitchen tools...</p>
	{:else if kitchenTools.length === 0}
		<p class="empty">No kitchen tools found matching the filters.</p>
	{:else}
		<p class="count">Showing {kitchenTools.length} kitchen tools</p>
		<table class="tools-table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Display Name</th>
					<th>Category</th>
					<th>Aliases</th>
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				{#each kitchenTools as tool}
					<tr>
						<td class="name-cell">
							<span class="mono-name">{tool.name}</span>
						</td>
						<td>{tool.display_name}</td>
						<td>
							{#if tool.category}
								<span class="category-badge">{formatLabel(tool.category)}</span>
							{:else}
								<span class="missing">-</span>
							{/if}
						</td>
						<td class="aliases-cell">
							{#if tool.aliases && tool.aliases.length > 0}
								<div class="alias-list">
									{#each tool.aliases as alias}
										<span class="alias-badge">{alias}</span>
									{/each}
								</div>
							{:else}
								<span class="missing">-</span>
							{/if}
						</td>
						<td class="actions-cell">
							<button onclick={() => openEditModal(tool)} class="edit-btn">Edit</button>
							<button onclick={() => deleteKitchenTool(tool)} class="delete-btn">Delete</button>
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
				<h2>{modalMode === 'create' ? 'Add Kitchen Tool' : 'Edit Kitchen Tool'}</h2>
				<button class="modal-close" onclick={closeModal}>&times;</button>
			</div>
			<div class="modal-body">
				<div class="form-group">
					<label for="tool-name">Name</label>
					<input id="tool-name" type="text" bind:value={editName} placeholder="e.g., knife" />
					<span class="form-help">Unique lowercase identifier (auto-lowercased on save)</span>
				</div>

				<div class="form-group">
					<label for="tool-display-name">Display Name</label>
					<input id="tool-display-name" type="text" bind:value={editDisplayName} placeholder="e.g., Knife" />
				</div>

				<div class="form-group">
					<label for="tool-category">Category</label>
					<select id="tool-category" bind:value={editCategory}>
						<option value="">None</option>
						{#if options?.categories}
							{#each options.categories as cat}
								<option value={cat}>{formatLabel(cat)}</option>
							{/each}
						{/if}
					</select>
				</div>

				<div class="form-group">
					<label for="tool-aliases">Aliases</label>
					<input id="tool-aliases" type="text" bind:value={editAliases} placeholder="e.g., chef's knife, paring knife" />
					<span class="form-help">Comma-separated alternative names</span>
				</div>

				<div class="form-group">
					<label for="tool-metadata">Metadata (JSON)</label>
					<textarea id="tool-metadata" bind:value={editMetadata} rows="5" spellcheck="false" class="metadata-editor"></textarea>
					<span class="form-help">Optional metadata as JSON</span>
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
		background: rgba(220, 74, 61, 0.1);
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

	.tools-table {
		width: 100%;
		border-collapse: collapse;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-sm);
	}

	.tools-table th {
		background: var(--color-pasta-100);
		padding: var(--space-3) var(--space-4);
		text-align: left;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.tools-table td {
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.tools-table tbody tr:hover {
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
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.delete-btn:hover {
		background: var(--color-marinara-200);
	}

	/* Button styles */
	.btn-primary {
		background: var(--color-basil-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-primary:hover {
		background: var(--color-basil-600);
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
		border-color: var(--color-basil-500);
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
