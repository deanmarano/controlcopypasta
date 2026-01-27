<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import {
		admin,
		type DomainStats,
		type QueueStats,
		type RateLimitStatus,
		type FailedUrl
	} from '$lib/api/client';

	let domains = $state<DomainStats[]>([]);
	let queueStats = $state<QueueStats | null>(null);
	let rateLimits = $state<RateLimitStatus | null>(null);
	let failedUrls = $state<FailedUrl[]>([]);
	let loading = $state(true);
	let error = $state('');
	let message = $state('');
	let accessDenied = $state(false);

	// Add domain form
	let newDomain = $state('');
	let newSeedUrl = $state('');
	let adding = $state(false);

	// Selected domain for filtering
	let selectedDomain = $state('');

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await loadAll();
	});

	async function loadAll() {
		loading = true;
		error = '';
		await Promise.all([loadDomains(), loadQueueStats(), loadRateLimits(), loadFailed()]);
		loading = false;
	}

	async function loadDomains() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.domains(token);
			domains = result.data;
		} catch (e) {
			if (e instanceof Error && 'status' in e && (e as { status: number }).status === 403) {
				accessDenied = true;
			}
		}
	}

	async function loadQueueStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.queueStats(token);
			queueStats = result.data;
		} catch {
			// Handled by loadDomains error
		}
	}

	async function loadRateLimits() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.rateLimits(token);
			rateLimits = result.data;
		} catch {
			// Handled by loadDomains error
		}
	}

	async function loadFailed() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const params = selectedDomain ? { domain: selectedDomain, limit: 20 } : { limit: 20 };
			const result = await admin.scraper.failed(token, params);
			failedUrls = result.data;
		} catch {
			// Handled by loadDomains error
		}
	}

	async function addDomain(e: Event) {
		e.preventDefault();
		if (!newDomain.trim() || !newSeedUrl.trim()) return;

		const token = authStore.getToken();
		if (!token) return;

		adding = true;
		error = '';
		message = '';
		try {
			const result = await admin.scraper.addDomain(token, newDomain.trim(), [newSeedUrl.trim()]);
			message = `Added ${result.data.domain}: ${result.data.enqueued} URLs enqueued`;
			newDomain = '';
			newSeedUrl = '';
			await loadDomains();
		} catch {
			error = 'Failed to add domain';
		} finally {
			adding = false;
		}
	}

	async function pauseScraping() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await admin.scraper.pause(token);
			message = `Paused scraping: ${result.data.cancelled_jobs} jobs cancelled`;
			await loadAll();
		} catch {
			error = 'Failed to pause scraping';
		}
	}

	async function resumeScraping() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await admin.scraper.resume(token);
			message = `Resumed scraping: ${result.data.resumed} URLs re-queued`;
			await loadAll();
		} catch {
			error = 'Failed to resume scraping';
		}
	}

	async function retryFailed() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await admin.scraper.retryFailed(token, selectedDomain || undefined);
			message = `Retried ${result.data.retried} failed URLs`;
			await loadAll();
		} catch {
			error = 'Failed to retry';
		}
	}

	function formatNumber(n: number): string {
		return n.toLocaleString();
	}
</script>

<div class="admin-page">
	<h1>Admin: Scraping</h1>

	{#if accessDenied}
		<div class="access-denied">
			<h2>Access Denied</h2>
			<p>You do not have permission to view this page. Admin access is required.</p>
			<a href="/settings">Back to Settings</a>
		</div>
	{:else if error}
		<p class="error">{error}</p>
	{/if}

	{#if message}
		<p class="message">{message}</p>
	{/if}

	{#if !accessDenied && loading}
		<p class="loading">Loading...</p>
	{:else if !accessDenied}
		<!-- Queue Stats -->
		{#if queueStats}
			<section class="stats-section">
				<h2>Queue Status</h2>
				<div class="stats-grid">
					<div class="stat">
						<span class="stat-value">{formatNumber(queueStats.pending)}</span>
						<span class="stat-label">Pending</span>
					</div>
					<div class="stat">
						<span class="stat-value">{formatNumber(queueStats.processing)}</span>
						<span class="stat-label">Processing</span>
					</div>
					<div class="stat">
						<span class="stat-value">{formatNumber(queueStats.completed)}</span>
						<span class="stat-label">Completed</span>
					</div>
					<div class="stat">
						<span class="stat-value">{formatNumber(queueStats.failed)}</span>
						<span class="stat-label">Failed</span>
					</div>
					<div class="stat">
						<span class="stat-value">{formatNumber(queueStats.total)}</span>
						<span class="stat-label">Total</span>
					</div>
				</div>
				<div class="actions">
					<button onclick={pauseScraping} class="btn-warning">Pause Scraping</button>
					<button onclick={resumeScraping} class="btn-success">Resume Scraping</button>
				</div>
			</section>
		{/if}

		<!-- Rate Limits -->
		{#if rateLimits}
			<section class="stats-section">
				<h2>Rate Limits (per domain)</h2>
				<div class="config-info" style="margin-bottom: var(--space-4)">
					<span>Limit: {rateLimits.config.max_per_hour}/hour, {rateLimits.config.max_per_day}/day per domain</span>
					<span>Delay: {rateLimits.config.min_delay_ms}-{rateLimits.config.min_delay_ms + rateLimits.config.max_random_delay_ms}ms</span>
					<span>Concurrency: {rateLimits.config.queue_concurrency}</span>
				</div>
				{#if rateLimits.per_domain.length === 0}
					<p class="empty">No active domains</p>
				{:else}
					<table class="rate-limits-table">
						<thead>
							<tr>
								<th>Domain</th>
								<th class="num">Hourly</th>
								<th class="num">Daily</th>
							</tr>
						</thead>
						<tbody>
							{#each rateLimits.per_domain as domain}
								<tr>
									<td>{domain.domain}</td>
									<td class="num">
										<span class:at-limit={domain.hourly.remaining === 0}>
											{domain.hourly.count} / {domain.hourly.limit}
										</span>
									</td>
									<td class="num">
										<span class:at-limit={domain.daily.remaining === 0}>
											{domain.daily.count} / {domain.daily.limit}
										</span>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				{/if}
			</section>
		{/if}

		<!-- Add Domain -->
		<section class="add-section">
			<h2>Add Domain</h2>
			<form onsubmit={addDomain}>
				<div class="form-row">
					<label>
						<span>Domain</span>
						<input
							type="text"
							bind:value={newDomain}
							placeholder="halfbakedharvest.com"
							disabled={adding}
						/>
					</label>
					<label>
						<span>Seed URL</span>
						<input
							type="url"
							bind:value={newSeedUrl}
							placeholder="https://halfbakedharvest.com/category/recipes/"
							disabled={adding}
						/>
					</label>
					<button type="submit" disabled={adding || !newDomain.trim() || !newSeedUrl.trim()}>
						{adding ? 'Adding...' : 'Add Domain'}
					</button>
				</div>
			</form>
		</section>

		<!-- Domains Table -->
		<section class="domains-section">
			<h2>Domains ({domains.length})</h2>
			{#if domains.length === 0}
				<p class="empty">No domains registered yet.</p>
			{:else}
				<table class="domains-table">
					<thead>
						<tr>
							<th>Domain</th>
							<th class="num">Pending</th>
							<th class="num">Processing</th>
							<th class="num">Completed</th>
							<th class="num">Failed</th>
							<th class="num">Total</th>
						</tr>
					</thead>
					<tbody>
						{#each domains as domain}
							<tr>
								<td class="domain-name">{domain.domain}</td>
								<td class="num">{formatNumber(domain.pending)}</td>
								<td class="num">{formatNumber(domain.processing)}</td>
								<td class="num">{formatNumber(domain.completed)}</td>
								<td class="num failed-count">{formatNumber(domain.failed)}</td>
								<td class="num">{formatNumber(domain.total)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{/if}
		</section>

		<!-- Failed URLs -->
		<section class="failed-section">
			<h2>Failed URLs</h2>
			<div class="failed-controls">
				<select bind:value={selectedDomain} onchange={() => loadFailed()}>
					<option value="">All Domains</option>
					{#each domains as d}
						<option value={d.domain}>{d.domain}</option>
					{/each}
				</select>
				<button onclick={retryFailed} class="btn-warning">
					Retry {selectedDomain ? selectedDomain : 'All'} Failed
				</button>
			</div>
			{#if failedUrls.length === 0}
				<p class="empty">No failed URLs.</p>
			{:else}
				<table class="failed-table">
					<thead>
						<tr>
							<th>URL</th>
							<th>Error</th>
							<th class="num">Attempts</th>
						</tr>
					</thead>
					<tbody>
						{#each failedUrls as url}
							<tr>
								<td class="url-cell" title={url.url}>{url.url}</td>
								<td class="error-cell">{url.error}</td>
								<td class="num">{url.attempts}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{/if}
		</section>
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

	section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
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
	}

	/* Stats */
	.stats-grid {
		display: flex;
		gap: var(--space-4);
		flex-wrap: wrap;
		margin-bottom: var(--space-4);
	}

	.stat {
		background: var(--bg-surface);
		padding: var(--space-4);
		border-radius: var(--radius-md);
		text-align: center;
		min-width: 100px;
	}

	.stat-value {
		display: block;
		font-size: var(--text-2xl);
		font-weight: var(--font-bold);
		color: var(--color-marinara-600);
	}

	.stat-label {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.actions {
		display: flex;
		gap: var(--space-3);
	}

	.btn-warning {
		background: var(--color-pasta-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-warning:hover {
		background: var(--color-pasta-600);
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

	/* Rate Limits */
	.rate-limits {
		display: flex;
		gap: var(--space-6);
		margin-bottom: var(--space-3);
	}

	.rate-limit p {
		margin: 0;
		font-size: var(--text-lg);
	}

	.remaining {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.config-info {
		display: flex;
		gap: var(--space-4);
		color: var(--text-muted);
		font-size: var(--text-sm);
		flex-wrap: wrap;
	}

	.rate-limits-table {
		width: 100%;
		border-collapse: collapse;
	}

	.rate-limits-table th,
	.rate-limits-table td {
		padding: var(--space-2) var(--space-3);
		text-align: left;
	}

	.rate-limits-table th {
		border-bottom: var(--border-width-default) solid var(--border-default);
		font-size: var(--text-sm);
		color: var(--text-secondary);
		font-weight: var(--font-medium);
	}

	.rate-limits-table td {
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.at-limit {
		color: var(--color-marinara-600);
		font-weight: var(--font-medium);
	}

	/* Add Domain Form */
	.form-row {
		display: flex;
		gap: var(--space-3);
		align-items: flex-end;
		flex-wrap: wrap;
	}

	.form-row label {
		display: flex;
		flex-direction: column;
		gap: var(--space-1);
		flex: 1;
		min-width: 200px;
	}

	.form-row label span {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.form-row input {
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.form-row button {
		background: var(--color-basil-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		white-space: nowrap;
	}

	.form-row button:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.form-row button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	/* Tables */
	table {
		width: 100%;
		border-collapse: collapse;
	}

	th {
		text-align: left;
		padding: var(--space-2) var(--space-3);
		border-bottom: var(--border-width-default) solid var(--border-default);
		font-size: var(--text-sm);
		color: var(--text-secondary);
		font-weight: var(--font-medium);
	}

	td {
		padding: var(--space-2) var(--space-3);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.num {
		text-align: right;
	}

	.domain-name {
		font-weight: var(--font-medium);
	}

	.failed-count {
		color: var(--color-marinara-600);
	}

	/* Failed section */
	.failed-controls {
		display: flex;
		gap: var(--space-3);
		margin-bottom: var(--space-4);
		align-items: center;
	}

	.failed-controls select {
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		min-width: 200px;
	}

	.url-cell {
		max-width: 400px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.error-cell {
		color: var(--color-marinara-600);
		max-width: 300px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
</style>
