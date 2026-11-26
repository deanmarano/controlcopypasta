<script lang="ts">
	import { onMount, untrack } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { browse, getDomainScreenshotUrl, getDomainFaviconUrl, type DomainInfo, type Recipe } from '$lib/api/client';
	import { decodeEntities } from '$lib/text';
	import SwipePhoneMockup from '$lib/components/SwipePhoneMockup.svelte';
	import FeedPhoneMockup from '$lib/components/FeedPhoneMockup.svelte';

	// The biggest sources get a picture; the long tail is a compact list.
	const FEATURED_COUNT = 12;
	const COMPACT_COUNT = 30;
	const RESULTS_PAGE = 24;

	let domains = $state<DomainInfo[]>([]);
	let loading = $state(true);
	let error = $state('');
	let failedScreenshots = $state<Set<string>>(new Set());
	let showAllSources = $state(false);

	// Search state. The query lives in the URL (/browse?q=lasagna) so results can be linked and survive Back.
	const query = $derived(($page.url.searchParams.get('q') || '').trim());
	let searchInput = $state('');
	let results = $state<Recipe[]>([]);
	let resultTotal = $state(0);
	let searching = $state(false);
	let searchingMore = $state(false);
	let searchError = $state('');
	let loadedQuery: string | null = null;

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadDomains();
	});

	$effect(() => {
		const q = query;
		if (!$isAuthenticated || q === loadedQuery) return;
		loadedQuery = q;
		untrack(() => {
			searchInput = q;
			runSearch();
		});
	});

	async function loadDomains() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await browse.domains(token);
			domains = result.data;
		} catch (err) {
			error = 'Failed to load domains';
		} finally {
			loading = false;
		}
	}

	async function runSearch(append = false) {
		const token = authStore.getToken();
		if (!token) return;

		if (!query) {
			results = [];
			resultTotal = 0;
			searchError = '';
			return;
		}

		if (append) searchingMore = true;
		else searching = true;
		searchError = '';

		try {
			const result = await browse.search(token, {
				q: query,
				limit: RESULTS_PAGE,
				offset: append ? results.length : 0
			});
			results = append ? [...results, ...result.data] : result.data;
			resultTotal = result.total;
		} catch {
			searchError = 'Search failed. Please try again.';
		} finally {
			searching = false;
			searchingMore = false;
		}
	}

	function handleSearch(e: Event) {
		e.preventDefault();
		const q = searchInput.trim();
		goto(q ? `/browse?q=${encodeURIComponent(q)}` : '/browse', { keepFocus: true });
	}

	function formatDomain(domain: string): string {
		return domain.replace(/^www\./, '');
	}

	function handleScreenshotError(domain: string) {
		failedScreenshots = new Set([...failedScreenshots, domain]);
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}

	const totalRecipes = $derived(domains.reduce((sum, d) => sum + d.count, 0));
	const featured = $derived(domains.slice(0, FEATURED_COUNT));
	const rest = $derived(domains.slice(FEATURED_COUNT));
	const visibleRest = $derived(showAllSources ? rest : rest.slice(0, COMPACT_COUNT));

	function abbreviateCount(n: number): string {
		if (n >= 1_000_000) return `${(n / 1_000_000).toFixed(1).replace(/\.0$/, '')}M`;
		if (n >= 1_000) return `${(n / 1_000).toFixed(1).replace(/\.0$/, '')}k`;
		return n.toString();
	}
</script>

<div class="browse-page">
	<header class="page-header">
		<h1>Browse {totalRecipes > 0 ? `${abbreviateCount(totalRecipes)} ` : ''}Recipes</h1>
		<p class="subtitle">Discover recipes from various sources</p>
	</header>

	<form class="search-form" onsubmit={handleSearch} role="search">
		<input
			type="search"
			bind:value={searchInput}
			placeholder="Search every recipe by title or description..."
			aria-label="Search all recipes"
		/>
		<button type="submit">Search</button>
	</form>

	{#if query}
		<section class="results">
			<div class="results-header">
				<h2>
					{#if searching}
						Searching for “{query}”...
					{:else}
						{resultTotal.toLocaleString()} result{resultTotal === 1 ? '' : 's'} for “{query}”
					{/if}
				</h2>
				<a href="/browse" class="clear-search">Clear search</a>
			</div>

			{#if searchError}
				<div class="error">{searchError}</div>
			{:else if !searching && results.length === 0}
				<div class="empty">
					<p>No recipes match “{query}”. Try a shorter or different search.</p>
				</div>
			{:else}
				<div class="result-grid">
					{#each results as recipe (recipe.id)}
						<a href="/recipes/{recipe.id}" class="result-card">
							{#if recipe.image_url}
								<img src={recipe.image_url} alt="" class="result-image" loading="lazy" />
							{:else}
								<div class="result-image placeholder">No image</div>
							{/if}
							<div class="result-content">
								<h3>{decodeEntities(recipe.title)}</h3>
								<div class="result-meta">
									{#if recipe.total_time_minutes}
										<span>{formatTime(recipe.total_time_minutes)}</span>
									{/if}
									{#if recipe.source_domain}
										<span>{formatDomain(recipe.source_domain)}</span>
									{/if}
								</div>
							</div>
						</a>
					{/each}
				</div>
				{#if results.length < resultTotal}
					<div class="load-more">
						<button onclick={() => runSearch(true)} disabled={searchingMore}>
							{searchingMore ? 'Loading...' : 'Show more results'}
						</button>
					</div>
				{/if}
			{/if}
		</section>
	{:else}
		<div class="quicklist-ctas">
			<SwipePhoneMockup href="/quicklist" />
			<FeedPhoneMockup href="/quicklist" />
		</div>

		{#if loading}
			<div class="loading">Loading sources...</div>
		{:else if error}
			<div class="error">{error}</div>
		{:else if domains.length === 0}
			<div class="empty">
				<p>No recipe sources available yet.</p>
			</div>
		{:else}
			<h2 class="section-title">Popular sources</h2>
			<div class="domain-grid">
				{#each featured as domain}
					<a href="/browse/{encodeURIComponent(formatDomain(domain.domain))}" class="domain-card">
						{#if domain.has_screenshot && !failedScreenshots.has(domain.domain)}
							<div class="screenshot-container">
								<img
									src={getDomainScreenshotUrl(domain.domain)}
									alt="{formatDomain(domain.domain)} screenshot"
									class="screenshot"
									loading="lazy"
									onerror={() => handleScreenshotError(domain.domain)}
								/>
							</div>
						{:else}
							<div class="screenshot-placeholder">
								<img
									src={getDomainFaviconUrl(domain.domain)}
									alt="{formatDomain(domain.domain)} favicon"
									class="placeholder-favicon"
									loading="lazy"
								/>
							</div>
						{/if}
						<div class="card-content">
							<div class="domain-header">
								<img src={getDomainFaviconUrl(domain.domain)} alt="" class="favicon" loading="lazy" />
								<h3>{formatDomain(domain.domain)}</h3>
							</div>
							<span class="count">{domain.count.toLocaleString()} recipes</span>
						</div>
					</a>
				{/each}
			</div>

			{#if rest.length > 0}
				<h2 class="section-title">All sources ({domains.length.toLocaleString()})</h2>
				<div class="source-list">
					{#each visibleRest as domain}
						<a href="/browse/{encodeURIComponent(formatDomain(domain.domain))}" class="source-row">
							<img src={getDomainFaviconUrl(domain.domain)} alt="" class="favicon" loading="lazy" />
							<span class="source-name">{formatDomain(domain.domain)}</span>
							<span class="count">{domain.count.toLocaleString()}</span>
						</a>
					{/each}
				</div>
				{#if rest.length > COMPACT_COUNT}
					<div class="load-more">
						<button onclick={() => (showAllSources = !showAllSources)}>
							{showAllSources ? 'Show fewer sources' : `Show all ${domains.length.toLocaleString()} sources`}
						</button>
					</div>
				{/if}
			{/if}
		{/if}
	{/if}
</div>

<style>
	.browse-page {
		max-width: 100%;
	}

	.page-header {
		margin-bottom: var(--space-6);
	}

	h1 {
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-800);
	}

	.subtitle {
		color: var(--text-secondary);
		margin: 0;
	}

	.search-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-8);
	}

	.search-form input {
		flex: 1;
		min-width: 0;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.search-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.search-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.search-form button:hover {
		background: var(--color-marinara-600);
	}

	.results-header {
		display: flex;
		flex-wrap: wrap;
		justify-content: space-between;
		align-items: baseline;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
	}

	.results-header h2,
	.section-title {
		margin: 0 0 var(--space-4);
		font-size: var(--text-xl);
		color: var(--color-marinara-800);
	}

	.results-header h2 {
		margin: 0;
	}

	.clear-search {
		font-size: var(--text-sm);
		color: var(--color-marinara-600);
	}

	.result-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
		gap: var(--space-5);
	}

	.result-card {
		display: flex;
		flex-direction: column;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-md);
		overflow: hidden;
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-normal);
	}

	.result-card:hover {
		transform: translateY(-2px);
		box-shadow: var(--shadow-lg);
	}

	.result-image {
		width: 100%;
		height: 140px;
		object-fit: cover;
	}

	.result-image.placeholder {
		display: flex;
		align-items: center;
		justify-content: center;
		background: var(--color-gray-200);
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.result-content {
		padding: var(--space-3) var(--space-4) var(--space-4);
	}

	.result-content h3 {
		margin: 0 0 var(--space-1);
		font-size: var(--text-base);
		color: var(--color-marinara-800);
	}

	.result-meta {
		display: flex;
		gap: var(--space-3);
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	.quicklist-ctas {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-4);
		margin-bottom: var(--space-8);
	}

	@media (max-width: 768px) {
		.quicklist-ctas {
			grid-template-columns: 1fr;
		}
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

	.domain-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
		gap: var(--space-6);
		margin-bottom: var(--space-10);
	}

	@media (max-width: 640px) {
		.domain-grid {
			grid-template-columns: 1fr 1fr;
			gap: var(--space-3);
		}

		.screenshot-container,
		.screenshot-placeholder {
			height: 96px;
		}

		.placeholder-favicon {
			width: 40px;
			height: 40px;
		}

		.card-content {
			padding: var(--space-3);
		}

		.domain-card h3 {
			font-size: var(--text-sm);
		}
	}

	.domain-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-md);
		text-decoration: none;
		transition: all var(--transition-normal);
		overflow: hidden;
		display: flex;
		flex-direction: column;
	}

	.domain-card:hover {
		transform: translateY(-2px);
		box-shadow: var(--shadow-lg);
	}

	.screenshot-container {
		width: 100%;
		height: 160px;
		overflow: hidden;
		background: var(--bg-secondary);
	}

	.screenshot {
		width: 100%;
		height: 100%;
		object-fit: cover;
		object-position: top center;
	}

	.screenshot-placeholder {
		width: 100%;
		height: 160px;
		background: linear-gradient(135deg, var(--bg-secondary) 0%, var(--bg-tertiary) 100%);
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.placeholder-favicon {
		width: 64px;
		height: 64px;
		opacity: 0.6;
	}

	.card-content {
		padding: var(--space-4);
	}

	.domain-header {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		margin-bottom: var(--space-1);
	}

	.favicon {
		width: 20px;
		height: 20px;
		flex-shrink: 0;
	}

	.domain-card h3 {
		margin: 0;
		color: var(--color-marinara-800);
		font-size: var(--text-lg);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.count {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.source-list {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: var(--space-2);
	}

	.source-row {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-2) var(--space-3);
		background: var(--bg-card);
		border: var(--border-width-thin) solid var(--border-light);
		border-radius: var(--radius-md);
		text-decoration: none;
		color: var(--color-marinara-800);
		transition: all var(--transition-fast);
	}

	.source-row:hover {
		border-color: var(--color-marinara-500);
	}

	.source-name {
		flex: 1;
		min-width: 0;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		font-weight: var(--font-medium);
	}

	.load-more {
		display: flex;
		justify-content: center;
		margin-top: var(--space-6);
	}

	.load-more button {
		padding: var(--space-3) var(--space-6);
		background: var(--bg-card);
		color: var(--color-marinara-600);
		border: var(--border-width-thin) solid var(--color-marinara-500);
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
		cursor: pointer;
	}

	.load-more button:hover:not(:disabled) {
		background: var(--color-marinara-50);
	}

	.load-more button:disabled {
		opacity: 0.6;
		cursor: default;
	}
</style>
