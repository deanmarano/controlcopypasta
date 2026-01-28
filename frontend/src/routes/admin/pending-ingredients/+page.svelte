<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, isAdmin } from '$lib/stores/auth';
	import { admin, ingredients, type PendingIngredient, type PendingIngredientStats, type CanonicalIngredient } from '$lib/api/client';

	let pending = $state<PendingIngredient[]>([]);
	let stats = $state<PendingIngredientStats | null>(null);
	let loading = $state(true);
	let error = $state('');
	let accessDenied = $state(false);

	// Filters
	let statusFilter = $state('pending');
	let searchQuery = $state('');

	// Actions
	let processing = $state<string | null>(null);
	let scanning = $state(false);

	// Merge modal
	let mergeModalOpen = $state(false);
	let mergeTarget = $state<PendingIngredient | null>(null);
	let mergeSearch = $state('');
	let mergeResults = $state<CanonicalIngredient[]>([]);
	let mergeSearching = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
		else if (!$isAdmin) goto('/');
	});

	onMount(async () => {
		await loadPending();
	});

	async function loadPending() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';
		try {
			const result = await admin.pendingIngredients.list(token, {
				status: statusFilter,
				limit: 100
			});
			pending = result.data;
			stats = result.stats;
		} catch (e) {
			if (e instanceof Error && 'status' in e && (e as { status: number }).status === 403) {
				accessDenied = true;
			} else {
				error = 'Failed to load pending ingredients';
			}
		} finally {
			loading = false;
		}
	}

	async function handleApprove(item: PendingIngredient) {
		const token = authStore.getToken();
		if (!token) return;

		processing = item.id;
		try {
			await admin.pendingIngredients.approve(token, item.id, {
				display_name: item.suggested_display_name || undefined,
				category: item.suggested_category || undefined,
				aliases: item.suggested_aliases
			});
			await loadPending();
		} catch {
			error = 'Failed to approve ingredient';
		} finally {
			processing = null;
		}
	}

	async function handleReject(item: PendingIngredient) {
		const token = authStore.getToken();
		if (!token) return;

		processing = item.id;
		try {
			await admin.pendingIngredients.reject(token, item.id);
			await loadPending();
		} catch {
			error = 'Failed to reject ingredient';
		} finally {
			processing = null;
		}
	}

	function openMergeModal(item: PendingIngredient) {
		mergeTarget = item;
		mergeSearch = item.name;
		mergeResults = [];
		mergeModalOpen = true;
		searchCanonicals();
	}

	function closeMergeModal() {
		mergeModalOpen = false;
		mergeTarget = null;
		mergeSearch = '';
		mergeResults = [];
	}

	async function searchCanonicals() {
		const token = authStore.getToken();
		if (!token || !mergeSearch) return;

		mergeSearching = true;
		try {
			const result = await ingredients.list(token, { search: mergeSearch });
			mergeResults = result.data.slice(0, 10);
		} catch {
			// Ignore
		} finally {
			mergeSearching = false;
		}
	}

	async function handleMerge(canonicalId: string) {
		const token = authStore.getToken();
		if (!token || !mergeTarget) return;

		processing = mergeTarget.id;
		try {
			await admin.pendingIngredients.merge(token, mergeTarget.id, canonicalId);
			closeMergeModal();
			await loadPending();
		} catch {
			error = 'Failed to merge ingredient';
		} finally {
			processing = null;
		}
	}

	async function handleScan() {
		const token = authStore.getToken();
		if (!token) return;

		scanning = true;
		try {
			await admin.pendingIngredients.scan(token);
			// Show success message briefly
			error = '';
		} catch {
			error = 'Failed to start scan';
		} finally {
			scanning = false;
		}
	}

	let searchTimeout: ReturnType<typeof setTimeout>;
	function handleMergeSearchInput() {
		clearTimeout(searchTimeout);
		searchTimeout = setTimeout(() => {
			searchCanonicals();
		}, 300);
	}

	function formatLabel(value: string): string {
		return value
			.split('_')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}

	const filteredPending = $derived(
		searchQuery
			? pending.filter((p) => p.name.toLowerCase().includes(searchQuery.toLowerCase()))
			: pending
	);
</script>

<div class="admin-page">
	<div class="header">
		<h1>Pending Ingredients</h1>
		<button onclick={handleScan} disabled={scanning} class="scan-btn">
			{scanning ? 'Scanning...' : 'Run Scan'}
		</button>
	</div>

	{#if accessDenied}
		<div class="access-denied">
			<h2>Access Denied</h2>
			<p>You do not have permission to view this page. Admin access is required.</p>
			<a href="/admin">Back to Admin</a>
		</div>
	{:else}
		{#if stats}
			<div class="stats-bar">
				<div class="stat" class:active={statusFilter === 'pending'}>
					<button onclick={() => { statusFilter = 'pending'; loadPending(); }}>
						<span class="stat-value">{stats.pending}</span>
						<span class="stat-label">Pending</span>
					</button>
				</div>
				<div class="stat" class:active={statusFilter === 'approved'}>
					<button onclick={() => { statusFilter = 'approved'; loadPending(); }}>
						<span class="stat-value">{stats.approved}</span>
						<span class="stat-label">Approved</span>
					</button>
				</div>
				<div class="stat" class:active={statusFilter === 'rejected'}>
					<button onclick={() => { statusFilter = 'rejected'; loadPending(); }}>
						<span class="stat-value">{stats.rejected}</span>
						<span class="stat-label">Rejected</span>
					</button>
				</div>
				<div class="stat" class:active={statusFilter === 'merged'}>
					<button onclick={() => { statusFilter = 'merged'; loadPending(); }}>
						<span class="stat-value">{stats.merged}</span>
						<span class="stat-label">Merged</span>
					</button>
				</div>
			</div>
		{/if}

		<div class="filters">
			<input
				type="text"
				bind:value={searchQuery}
				placeholder="Filter by name..."
				class="search-input"
			/>
		</div>

		{#if error}
			<p class="error">{error}</p>
		{/if}

		{#if loading}
			<p class="loading">Loading pending ingredients...</p>
		{:else if filteredPending.length === 0}
			<p class="empty">No pending ingredients found.</p>
		{:else}
			<p class="count">Showing {filteredPending.length} of {pending.length} ingredients</p>
			<div class="pending-list">
				{#each filteredPending as item}
					<div class="pending-item" class:processing={processing === item.id}>
						<div class="item-header">
							<span class="item-name">{item.suggested_display_name || item.name}</span>
							<span class="item-count">{item.occurrence_count}x</span>
						</div>

						<div class="item-canonical">
							<code>{item.name}</code>
						</div>

						{#if item.suggested_category}
							<div class="item-category">
								<span class="category-badge">{formatLabel(item.suggested_category)}</span>
							</div>
						{/if}

						<div class="item-samples">
							<span class="samples-label">Samples:</span>
							<ul>
								{#each item.sample_texts.slice(0, 3) as sample}
									<li>{sample}</li>
								{/each}
							</ul>
						</div>

						{#if statusFilter === 'pending'}
							<div class="item-actions">
								<button
									onclick={() => handleApprove(item)}
									disabled={processing === item.id}
									class="approve-btn"
								>
									Approve
								</button>
								<button
									onclick={() => openMergeModal(item)}
									disabled={processing === item.id}
									class="merge-btn"
								>
									Merge
								</button>
								<button
									onclick={() => handleReject(item)}
									disabled={processing === item.id}
									class="reject-btn"
								>
									Reject
								</button>
							</div>
						{:else}
							<div class="item-status">
								<span class="status-badge status-{item.status}">{item.status}</span>
								{#if item.reviewed_at}
									<span class="reviewed-at">
										{new Date(item.reviewed_at).toLocaleDateString()}
									</span>
								{/if}
							</div>
						{/if}
					</div>
				{/each}
			</div>
		{/if}
	{/if}
</div>

<!-- Merge Modal -->
{#if mergeModalOpen && mergeTarget}
	<div class="modal-overlay" onclick={closeMergeModal}>
		<div class="modal" onclick={(e) => e.stopPropagation()}>
			<h2>Merge "{mergeTarget.name}"</h2>
			<p class="modal-desc">Select an existing canonical ingredient to merge this as an alias:</p>

			<input
				type="text"
				bind:value={mergeSearch}
				oninput={handleMergeSearchInput}
				placeholder="Search canonical ingredients..."
				class="merge-search"
			/>

			{#if mergeSearching}
				<p class="searching">Searching...</p>
			{:else if mergeResults.length > 0}
				<ul class="merge-results">
					{#each mergeResults as canonical}
						<li>
							<button onclick={() => handleMerge(canonical.id)} disabled={processing !== null}>
								<span class="canonical-name">{canonical.display_name}</span>
								{#if canonical.category}
									<span class="canonical-category">{formatLabel(canonical.category)}</span>
								{/if}
								{#if canonical.aliases.length > 0}
									<span class="canonical-aliases">
										Aliases: {canonical.aliases.slice(0, 3).join(', ')}
									</span>
								{/if}
							</button>
						</li>
					{/each}
				</ul>
			{:else if mergeSearch}
				<p class="no-results">No matching ingredients found</p>
			{/if}

			<div class="modal-actions">
				<button onclick={closeMergeModal} class="cancel-btn">Cancel</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.admin-page {
		max-width: 900px;
	}

	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-6);
	}

	h1 {
		margin: 0;
		color: var(--color-marinara-800);
	}

	.scan-btn {
		padding: var(--space-2) var(--space-4);
		background: var(--color-basil-500);
		color: white;
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.scan-btn:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.scan-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.access-denied {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		text-align: center;
	}

	.stats-bar {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-2);
		box-shadow: var(--shadow-sm);
	}

	.stat button {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: var(--space-3) var(--space-4);
		background: transparent;
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		min-width: 80px;
	}

	.stat.active button {
		background: var(--color-pasta-100);
	}

	.stat button:hover {
		background: var(--color-pasta-50);
	}

	.stat-value {
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--color-marinara-700);
	}

	.stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.filters {
		margin-bottom: var(--space-4);
	}

	.search-input {
		width: 100%;
		max-width: 300px;
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
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

	.pending-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
	}

	.pending-item {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		box-shadow: var(--shadow-sm);
	}

	.pending-item.processing {
		opacity: 0.6;
		pointer-events: none;
	}

	.item-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-2);
	}

	.item-name {
		font-size: var(--text-lg);
		font-weight: var(--font-medium);
		color: var(--color-marinara-800);
	}

	.item-count {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
	}

	.item-canonical {
		margin-bottom: var(--space-2);
	}

	.item-canonical code {
		font-size: var(--text-sm);
		color: var(--text-muted);
		background: var(--color-gray-100);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
	}

	.item-category {
		margin-bottom: var(--space-2);
	}

	.category-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
	}

	.item-samples {
		margin-bottom: var(--space-3);
	}

	.samples-label {
		font-size: var(--text-xs);
		color: var(--text-muted);
		display: block;
		margin-bottom: var(--space-1);
	}

	.item-samples ul {
		margin: 0;
		padding-left: var(--space-4);
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.item-samples li {
		margin-bottom: var(--space-1);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.item-actions {
		display: flex;
		gap: var(--space-2);
	}

	.approve-btn,
	.merge-btn,
	.reject-btn {
		padding: var(--space-2) var(--space-3);
		border: none;
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		cursor: pointer;
	}

	.approve-btn {
		background: var(--color-basil-500);
		color: white;
	}

	.approve-btn:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.merge-btn {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
	}

	.merge-btn:hover:not(:disabled) {
		background: var(--color-pasta-300);
	}

	.reject-btn {
		background: var(--color-gray-200);
		color: var(--color-gray-700);
	}

	.reject-btn:hover:not(:disabled) {
		background: var(--color-gray-300);
	}

	.item-status {
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.status-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.status-approved {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.status-rejected {
		background: var(--color-gray-200);
		color: var(--color-gray-600);
	}

	.status-merged {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.reviewed-at {
		font-size: var(--text-xs);
		color: var(--text-muted);
	}

	/* Modal */
	.modal-overlay {
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
		padding: var(--space-6);
		max-width: 500px;
		width: 90%;
		max-height: 80vh;
		overflow-y: auto;
	}

	.modal h2 {
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-800);
	}

	.modal-desc {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin-bottom: var(--space-4);
	}

	.merge-search {
		width: 100%;
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		margin-bottom: var(--space-3);
	}

	.searching,
	.no-results {
		color: var(--text-muted);
		font-size: var(--text-sm);
		font-style: italic;
	}

	.merge-results {
		list-style: none;
		margin: 0;
		padding: 0;
	}

	.merge-results li {
		margin-bottom: var(--space-2);
	}

	.merge-results button {
		width: 100%;
		text-align: left;
		padding: var(--space-3);
		background: var(--color-gray-50);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		cursor: pointer;
	}

	.merge-results button:hover:not(:disabled) {
		background: var(--color-pasta-50);
		border-color: var(--color-pasta-300);
	}

	.canonical-name {
		display: block;
		font-weight: var(--font-medium);
		color: var(--color-marinara-700);
	}

	.canonical-category {
		display: inline-block;
		font-size: var(--text-xs);
		color: var(--color-basil-600);
		margin-right: var(--space-2);
	}

	.canonical-aliases {
		display: block;
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-top: var(--space-1);
	}

	.modal-actions {
		margin-top: var(--space-4);
		display: flex;
		justify-content: flex-end;
	}

	.cancel-btn {
		padding: var(--space-2) var(--space-4);
		background: var(--color-gray-200);
		color: var(--color-gray-700);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
	}

	.cancel-btn:hover {
		background: var(--color-gray-300);
	}
</style>
