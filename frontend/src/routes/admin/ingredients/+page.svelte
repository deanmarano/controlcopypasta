<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import {
		admin,
		type AdminIngredient,
		type AdminIngredientOptions,
		type IngredientEnrichmentStats,
		type ParsingStats
	} from '$lib/api/client';

	let ingredients = $state<AdminIngredient[]>([]);
	let options = $state<AdminIngredientOptions | null>(null);
	let enrichmentStats = $state<IngredientEnrichmentStats | null>(null);
	let parsingStats = $state<ParsingStats | null>(null);
	let loading = $state(true);
	let error = $state('');
	let message = $state('');
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
		await Promise.all([loadOptions(), loadIngredients(), loadEnrichmentStats(), loadParsingStats()]);
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

	function formatNumber(n: number): string {
		return n.toLocaleString();
	}

	async function loadEnrichmentStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.ingredientEnrichment(token);
			enrichmentStats = result.data;
		} catch {
			enrichmentStats = null;
		}
	}

	async function loadParsingStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.parsingStats(token);
			parsingStats = result.data;
		} catch {
			parsingStats = null;
		}
	}

	async function parseAllIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			await admin.scraper.parseIngredients(token);
			message = 'Started parsing ingredients for all unparsed recipes';
		} catch {
			error = 'Failed to start ingredient parsing';
		}
	}

	async function reparseAllIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		if (!confirm('This will reprocess ALL recipes to regenerate pre_steps, alternatives, and recipe references. Continue?')) {
			return;
		}

		error = '';
		message = '';

		try {
			await admin.scraper.parseIngredients(token, { force: true });
			message = 'Started reparsing ALL recipes (this may take a while)';
		} catch {
			error = 'Failed to start ingredient reparsing';
		}
	}

	async function enqueueNutrition() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.enqueueNutrition(token);
			message = `Enqueued ${result.data.enqueued} ingredients for nutrition enrichment`;
			await loadEnrichmentStats();
		} catch {
			error = 'Failed to enqueue nutrition enrichment';
		}
	}

	async function enqueueDensity() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.enqueueDensity(token);
			message = `Enqueued ${result.data.enqueued} ingredients for density enrichment`;
			await loadEnrichmentStats();
		} catch {
			error = 'Failed to enqueue density enrichment';
		}
	}

	async function resumeNutrition() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			await admin.scraper.resumeNutrition(token);
			message = 'Resumed nutrition enrichment queue';
			await loadEnrichmentStats();
		} catch {
			error = 'Failed to resume nutrition enrichment';
		}
	}

	async function resumeDensity() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			await admin.scraper.resumeDensity(token);
			message = 'Resumed density enrichment queue';
			await loadEnrichmentStats();
		} catch {
			error = 'Failed to resume density enrichment';
		}
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

	{#if message}
		<p class="message">{message}</p>
	{/if}

	<!-- Ingredient Parsing Status -->
	{#if parsingStats}
		<section class="parsing-section">
			<h2>Ingredient Parsing</h2>
			<div class="parsing-overview">
				<div class="parsing-progress">
					<div class="progress-bar">
						<div class="progress-fill" style="width: {parsingStats.percent_complete}%"></div>
					</div>
					<span class="progress-text">{parsingStats.percent_complete}% complete</span>
				</div>
				<div class="parsing-counts">
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.parsed_recipes)}</span>
						<span class="parsing-stat-label">Parsed</span>
					</div>
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.unparsed_recipes)}</span>
						<span class="parsing-stat-label">Unparsed</span>
					</div>
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.total_recipes)}</span>
						<span class="parsing-stat-label">Total</span>
					</div>
				</div>
				<div class="parsing-actions">
					<button onclick={parseAllIngredients} class="btn-secondary">Parse Unparsed</button>
					<button onclick={reparseAllIngredients} class="btn-primary">Reparse All Recipes</button>
				</div>
			</div>

			{#if parsingStats.active_jobs.length > 0}
				<div class="parsing-jobs">
					<h3>Active Parsing Jobs ({parsingStats.active_jobs.length})</h3>
					<div class="jobs-list">
						{#each parsingStats.active_jobs as job}
							<div class="job-item">
								<span class="job-id">#{job.id}</span>
								<span class="job-state" class:executing={job.state === 'executing'} class:available={job.state === 'available'} class:scheduled={job.state === 'scheduled'}>{job.state}</span>
								<span class="job-offset">Offset: {job.offset}</span>
								{#if job.force}
									<span class="job-force">Force</span>
								{/if}
								<span class="job-time">{new Date(job.inserted_at).toLocaleTimeString()}</span>
							</div>
						{/each}
					</div>
				</div>
			{/if}

			{#if parsingStats.last_completed}
				<div class="parsing-last">
					<span>Last completed batch: offset {parsingStats.last_completed.offset} at {new Date(parsingStats.last_completed.completed_at).toLocaleString()}</span>
				</div>
			{/if}
		</section>
	{/if}

	<!-- Ingredient Enrichment -->
	{#if enrichmentStats}
		<section class="enrichment-section">
			<h2>Ingredient Enrichment</h2>
			<div class="enrichment-grid">
				<!-- Nutrition (FatSecret) -->
				<div class="enrichment-card">
					<h3>Nutrition Data</h3>
					<p class="enrichment-sources">Source: FatSecret</p>
					<div class="enrichment-stats">
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.nutrition.with_fatsecret_data || 0)}</span>
							<span class="enrichment-stat-label">With Data</span>
						</div>
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.nutrition.total_ingredients - (enrichmentStats.nutrition.with_fatsecret_data || 0))}</span>
							<span class="enrichment-stat-label">Without Data</span>
						</div>
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.nutrition.pending_jobs)}</span>
							<span class="enrichment-stat-label">Pending</span>
						</div>
					</div>
					<div class="enrichment-progress">
						<div class="progress-bar">
							<div class="progress-fill" style="width: {enrichmentStats.nutrition.total_ingredients > 0 ? Math.round(((enrichmentStats.nutrition.with_fatsecret_data || 0) / enrichmentStats.nutrition.total_ingredients) * 100) : 0}%"></div>
						</div>
						<span class="progress-text">{enrichmentStats.nutrition.total_ingredients > 0 ? Math.round(((enrichmentStats.nutrition.with_fatsecret_data || 0) / enrichmentStats.nutrition.total_ingredients) * 100) : 0}% complete</span>
					</div>
					<div class="enrichment-rate">
						<span>Today: {enrichmentStats.nutrition.completed_today}/{enrichmentStats.nutrition.daily_limit}</span>
						<span>This hour: {enrichmentStats.nutrition.completed_this_hour}/{enrichmentStats.nutrition.hourly_limit}</span>
					</div>
					<div class="enrichment-actions">
						<button onclick={enqueueNutrition} class="btn-secondary">Enqueue All</button>
						<button onclick={resumeNutrition} class="btn-success">Resume Queue</button>
					</div>
				</div>

				<!-- Density -->
				<div class="enrichment-card">
					<h3>Density Data</h3>
					<p class="enrichment-sources">Sources: FatSecret, USDA, Open Food Facts</p>
					<div class="enrichment-stats">
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.density.with_density_data || 0)}</span>
							<span class="enrichment-stat-label">With Data</span>
						</div>
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.density.without_density_data || 0)}</span>
							<span class="enrichment-stat-label">Without Data</span>
						</div>
						<div class="enrichment-stat">
							<span class="enrichment-stat-value">{formatNumber(enrichmentStats.density.pending_jobs)}</span>
							<span class="enrichment-stat-label">Pending</span>
						</div>
					</div>
					<div class="enrichment-progress">
						<div class="progress-bar">
							<div class="progress-fill" style="width: {enrichmentStats.density.total_ingredients > 0 ? Math.round(((enrichmentStats.density.with_density_data || 0) / enrichmentStats.density.total_ingredients) * 100) : 0}%"></div>
						</div>
						<span class="progress-text">{enrichmentStats.density.total_ingredients > 0 ? Math.round(((enrichmentStats.density.with_density_data || 0) / enrichmentStats.density.total_ingredients) * 100) : 0}% complete</span>
					</div>
					<div class="enrichment-rate">
						<span>Today: {enrichmentStats.density.completed_today}/{enrichmentStats.density.daily_limit}</span>
						<span>This hour: {enrichmentStats.density.completed_this_hour}/{enrichmentStats.density.hourly_limit}</span>
					</div>
					<div class="enrichment-actions">
						<button onclick={enqueueDensity} class="btn-secondary">Enqueue All</button>
						<button onclick={resumeDensity} class="btn-success">Resume Queue</button>
					</div>
				</div>
			</div>
		</section>
	{/if}

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

	/* Message */
	.message {
		color: var(--color-basil-700);
		background: var(--color-basil-100);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	/* Section styling */
	h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-lg);
		color: var(--color-marinara-700);
	}

	h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-base);
		color: var(--text-secondary);
	}

	/* Parsing Section */
	.parsing-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.parsing-overview {
		display: flex;
		flex-direction: column;
		gap: var(--space-4);
	}

	.parsing-progress {
		margin-bottom: var(--space-2);
	}

	.parsing-counts {
		display: flex;
		gap: var(--space-3);
	}

	.parsing-stat {
		flex: 1;
		text-align: center;
		padding: var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.parsing-stat-value {
		display: block;
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--color-marinara-600);
	}

	.parsing-stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.parsing-actions {
		display: flex;
		gap: var(--space-3);
	}

	.parsing-jobs {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.parsing-jobs h3 {
		margin: 0 0 var(--space-3);
	}

	.jobs-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.job-item {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-2) var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
	}

	.job-id {
		font-weight: var(--font-medium);
		color: var(--text-muted);
		min-width: 60px;
	}

	.job-state {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		background: var(--color-gray-200);
		color: var(--text-secondary);
	}

	.job-state.executing {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.job-state.available {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.job-state.scheduled {
		background: var(--color-gray-200);
		color: var(--text-secondary);
	}

	.job-offset {
		color: var(--text-secondary);
	}

	.job-force {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.job-time {
		margin-left: auto;
		color: var(--text-muted);
		font-size: var(--text-xs);
	}

	.parsing-last {
		margin-top: var(--space-3);
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	/* Progress bar */
	.progress-bar {
		height: 8px;
		background: var(--border-light);
		border-radius: var(--radius-full);
		overflow: hidden;
		margin-bottom: var(--space-1);
	}

	.progress-fill {
		height: 100%;
		background: var(--color-basil-500);
		border-radius: var(--radius-full);
		transition: width var(--transition-normal);
	}

	.progress-text {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	/* Enrichment Section */
	.enrichment-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.enrichment-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
		gap: var(--space-4);
	}

	.enrichment-card {
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: var(--space-4);
	}

	.enrichment-card h3 {
		margin: 0 0 var(--space-1);
		font-size: var(--text-base);
		color: var(--text-primary);
	}

	.enrichment-sources {
		margin: 0 0 var(--space-3);
		font-size: var(--text-xs);
		color: var(--text-muted);
	}

	.enrichment-stats {
		display: flex;
		gap: var(--space-3);
		margin-bottom: var(--space-3);
	}

	.enrichment-stat {
		flex: 1;
		text-align: center;
		padding: var(--space-2);
		background: var(--bg-card);
		border-radius: var(--radius-sm);
	}

	.enrichment-stat-value {
		display: block;
		font-size: var(--text-lg);
		font-weight: var(--font-bold);
		color: var(--color-marinara-600);
	}

	.enrichment-stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.enrichment-progress {
		margin-bottom: var(--space-3);
	}

	.enrichment-rate {
		display: flex;
		justify-content: space-between;
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-bottom: var(--space-3);
	}

	.enrichment-actions {
		display: flex;
		gap: var(--space-2);
	}

	.enrichment-actions button {
		flex: 1;
		padding: var(--space-2);
		font-size: var(--text-sm);
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

	.btn-success {
		background: var(--color-basil-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-success:hover {
		background: var(--color-basil-600);
	}
</style>
