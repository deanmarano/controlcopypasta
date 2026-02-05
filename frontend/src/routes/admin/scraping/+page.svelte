<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import {
		admin,
		type DomainStats,
		type QueueStats,
		type RateLimitStatus,
		type FailedUrl,
		type BrowserStatus,
		type ExecutingWorker
	} from '$lib/api/client';

	let domains = $state<DomainStats[]>([]);
	let queueStats = $state<QueueStats | null>(null);
	let rateLimits = $state<RateLimitStatus | null>(null);
	let failedUrls = $state<FailedUrl[]>([]);
	let browserStatus = $state<BrowserStatus | null>(null);
	let executingWorkers = $state<ExecutingWorker[]>([]);
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

	// Screenshot capture
	let capturingScreenshot = $state<string | null>(null);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await loadAll();
	});

	async function loadAll() {
		loading = true;
		error = '';
		await Promise.all([loadDomains(), loadQueueStats(), loadRateLimits(), loadFailed(), loadBrowserStatus(), loadWorkers()]);
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

	async function loadBrowserStatus() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.browserStatus(token);
			browserStatus = result.data;
		} catch {
			// Browser status not critical, just set to null
			browserStatus = null;
		}
	}

	async function loadWorkers() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.workers(token);
			executingWorkers = result.data;
		} catch {
			executingWorkers = [];
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

	// Parse datetime string from server (assumes UTC) and format to local time
	function formatLocalTime(dateStr: string): string {
		const normalized = dateStr.endsWith('Z') || dateStr.includes('+') ? dateStr : dateStr + 'Z';
		return new Date(normalized).toLocaleTimeString();
	}

	function formatLocalDateTime(dateStr: string): string {
		const normalized = dateStr.endsWith('Z') || dateStr.includes('+') ? dateStr : dateStr + 'Z';
		return new Date(normalized).toLocaleString();
	}

	async function captureScreenshot(domain: string) {
		const token = authStore.getToken();
		if (!token) return;

		capturingScreenshot = domain;
		error = '';
		message = '';

		try {
			await admin.scraper.captureScreenshot(token, domain);
			message = `Screenshot captured for ${domain}`;
		} catch {
			error = `Failed to capture screenshot for ${domain}`;
		} finally {
			capturingScreenshot = null;
		}
	}

	async function resetStale() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.resetStale(token);
			message = `Reset ${result.data.reset} stale processing URLs to pending`;
			await loadAll();
		} catch {
			error = 'Failed to reset stale URLs';
		}
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
		<!-- Browser Pool Status -->
		<section class="browser-section">
			<h2>Browser Pool</h2>
			{#if browserStatus}
				<div class="browser-status" class:healthy={browserStatus.running && browserStatus.healthy} class:unhealthy={!browserStatus.running || !browserStatus.healthy}>
					<div class="status-indicator">
						<span class="status-dot"></span>
						<span class="status-text">
							{#if !browserStatus.running}
								Not Running
							{:else if browserStatus.healthy}
								Healthy
							{:else}
								Unhealthy
							{/if}
						</span>
					</div>
					<div class="browser-details">
						<span>Pool Size: {browserStatus.pool_size}</span>
						{#if browserStatus.error}
							<span class="browser-error">Error: {browserStatus.error}</span>
						{/if}
					</div>
				</div>
				{#if browserStatus.stats}
					<div class="browser-stats">
						<div class="browser-stats-counts">
							<div class="browser-stat">
								<span class="browser-stat-value">{formatNumber(browserStatus.stats.total_actions)}</span>
								<span class="browser-stat-label">Total Actions</span>
							</div>
							<div class="browser-stat success">
								<span class="browser-stat-value">{formatNumber(browserStatus.stats.success_count)}</span>
								<span class="browser-stat-label">Success</span>
							</div>
							<div class="browser-stat error">
								<span class="browser-stat-value">{formatNumber(browserStatus.stats.error_count)}</span>
								<span class="browser-stat-label">Errors</span>
							</div>
						</div>
						{#if browserStatus.stats.last_action}
							<div class="browser-last-action">
								<h3>Last Action</h3>
								<div class="last-action-details">
									<span class="last-action-type">{browserStatus.stats.last_action}</span>
									<span class="last-action-result" class:result-success={browserStatus.stats.last_result === 'success'} class:result-error={browserStatus.stats.last_result?.startsWith('error')}>
										{browserStatus.stats.last_result}
									</span>
									{#if browserStatus.stats.last_action_at}
										<span class="last-action-time">{formatLocalDateTime(browserStatus.stats.last_action_at)}</span>
									{/if}
								</div>
								{#if browserStatus.stats.last_url}
									<div class="last-action-url" title={browserStatus.stats.last_url}>
										{browserStatus.stats.last_url}
									</div>
								{/if}
							</div>
						{/if}
						{#if browserStatus.stats.started_at}
							<div class="browser-uptime">
								Started: {formatLocalDateTime(browserStatus.stats.started_at)}
							</div>
						{/if}
					</div>
				{/if}
			{:else}
				<p class="empty">Browser status unavailable</p>
			{/if}
		</section>

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
						<span class="stat-value">{formatNumber(queueStats.paused || 0)}</span>
						<span class="stat-label">Paused</span>
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
					<button onclick={resetStale} class="btn-secondary">Reset Stale Processing</button>
				</div>

				<!-- Executing Workers -->
				{#if executingWorkers.length > 0}
					<div class="workers-section">
						<h3>Active Workers ({executingWorkers.length})</h3>
						<div class="workers-list">
							{#each executingWorkers as worker}
								<div class="worker-item">
									<span class="worker-id">#{worker.id}</span>
									<span class="worker-url" title={worker.url}>{worker.url}</span>
									<span class="worker-time">{formatLocalTime(worker.started_at)}</span>
								</div>
							{/each}
						</div>
					</div>
				{:else}
					<div class="workers-section">
						<h3>Active Workers</h3>
						<p class="empty">No workers currently executing</p>
					</div>
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
			{#if rateLimits}
				<div class="config-info" style="margin-bottom: var(--space-4)">
					<span>Rate limit: {rateLimits.config.max_per_hour}/hour, {rateLimits.config.max_per_day}/day per domain</span>
					<span>Delay: {rateLimits.config.min_delay_ms}-{rateLimits.config.min_delay_ms + rateLimits.config.max_random_delay_ms}ms</span>
					<span>Concurrency: {rateLimits.config.queue_concurrency}</span>
				</div>
			{/if}
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
							<th class="num">Hourly</th>
							<th class="num">Daily</th>
							<th>Actions</th>
						</tr>
					</thead>
					<tbody>
						{#each domains as domain}
							{@const rateLimit = rateLimits?.per_domain.find(r => r.domain === domain.domain)}
							<tr>
								<td class="domain-name">{domain.domain}</td>
								<td class="num">{formatNumber(domain.pending)}</td>
								<td class="num">{formatNumber(domain.processing)}</td>
								<td class="num">{formatNumber(domain.completed)}</td>
								<td class="num failed-count">{formatNumber(domain.failed)}</td>
								<td class="num">{formatNumber(domain.total)}</td>
								<td class="num">
									{#if rateLimit}
										<span class:at-limit={rateLimit.hourly.remaining === 0}>
											{rateLimit.hourly.count}/{rateLimit.hourly.limit}
										</span>
									{:else}
										<span class="inactive">-</span>
									{/if}
								</td>
								<td class="num">
									{#if rateLimit}
										<span class:at-limit={rateLimit.daily.remaining === 0}>
											{rateLimit.daily.count}/{rateLimit.daily.limit}
										</span>
									{:else}
										<span class="inactive">-</span>
									{/if}
								</td>
								<td>
									<button
										class="btn-small"
										onclick={() => captureScreenshot(domain.domain)}
										disabled={capturingScreenshot !== null}
									>
										{capturingScreenshot === domain.domain ? 'Capturing...' : 'Screenshot'}
									</button>
								</td>
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

	/* Browser Status */
	.browser-status {
		display: flex;
		align-items: center;
		gap: var(--space-6);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		background: var(--bg-surface);
	}

	.browser-status.healthy {
		border-left: 4px solid var(--color-basil-500);
	}

	.browser-status.unhealthy {
		border-left: 4px solid var(--color-marinara-500);
	}

	.status-indicator {
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.status-dot {
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: var(--color-gray-400);
	}

	.healthy .status-dot {
		background: var(--color-basil-500);
		box-shadow: 0 0 8px var(--color-basil-400);
	}

	.unhealthy .status-dot {
		background: var(--color-marinara-500);
	}

	.status-text {
		font-weight: var(--font-medium);
	}

	.browser-details {
		display: flex;
		gap: var(--space-4);
		color: var(--text-secondary);
		font-size: var(--text-sm);
	}

	.browser-error {
		color: var(--color-marinara-600);
	}

	.browser-stats {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.browser-stats-counts {
		display: flex;
		gap: var(--space-4);
		margin-bottom: var(--space-4);
	}

	.browser-stat {
		background: var(--bg-surface);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		text-align: center;
		min-width: 80px;
	}

	.browser-stat.success .browser-stat-value {
		color: var(--color-basil-600);
	}

	.browser-stat.error .browser-stat-value {
		color: var(--color-marinara-600);
	}

	.browser-stat-value {
		display: block;
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--text-primary);
	}

	.browser-stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.browser-last-action {
		background: var(--bg-surface);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-3);
	}

	.browser-last-action h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-sm);
		color: var(--text-secondary);
		font-weight: var(--font-medium);
	}

	.last-action-details {
		display: flex;
		gap: var(--space-3);
		align-items: center;
		margin-bottom: var(--space-2);
	}

	.last-action-type {
		font-weight: var(--font-medium);
		text-transform: capitalize;
	}

	.last-action-result {
		font-size: var(--text-sm);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		background: var(--color-gray-100);
	}

	.last-action-result.result-success {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.last-action-result.result-error {
		background: rgba(220, 74, 61, 0.1);
		color: var(--color-marinara-700);
	}

	.last-action-time {
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	.last-action-url {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		max-width: 100%;
	}

	.browser-uptime {
		font-size: var(--text-sm);
		color: var(--text-muted);
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

	.workers-section {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.workers-section h3 {
		margin: 0 0 var(--space-3);
		font-size: var(--text-base);
		color: var(--text-secondary);
	}

	.workers-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.worker-item {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-2) var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
	}

	.worker-id {
		font-weight: var(--font-medium);
		color: var(--text-muted);
		min-width: 70px;
	}

	.worker-url {
		flex: 1;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		color: var(--text-primary);
	}

	.worker-time {
		color: var(--text-muted);
		font-size: var(--text-xs);
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


	.config-info {
		display: flex;
		gap: var(--space-4);
		color: var(--text-muted);
		font-size: var(--text-sm);
		flex-wrap: wrap;
	}

	.at-limit {
		color: var(--color-marinara-600);
		font-weight: var(--font-medium);
	}

	.inactive {
		color: var(--text-muted);
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

	.btn-small {
		background: var(--color-gray-500);
		color: white;
		border: none;
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
		white-space: nowrap;
	}

	.btn-small:hover:not(:disabled) {
		background: var(--color-gray-600);
	}

	.btn-small:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}
</style>
