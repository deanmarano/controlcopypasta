<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { browse, getDomainScreenshotUrl, getDomainFaviconUrl, type DomainInfo } from '$lib/api/client';
	import SwipePhoneMockup from '$lib/components/SwipePhoneMockup.svelte';
	import FeedPhoneMockup from '$lib/components/FeedPhoneMockup.svelte';

	let domains = $state<DomainInfo[]>([]);
	let loading = $state(true);
	let error = $state('');
	let failedScreenshots = $state<Set<string>>(new Set());

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadDomains();
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

	function formatDomain(domain: string): string {
		return domain.replace(/^www\./, '');
	}

	function handleScreenshotError(domain: string) {
		failedScreenshots = new Set([...failedScreenshots, domain]);
	}

	const totalRecipes = $derived(domains.reduce((sum, d) => sum + d.count, 0));

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
		<div class="domain-grid">
			{#each domains as domain}
				<a href="/browse/{encodeURIComponent(formatDomain(domain.domain))}" class="domain-card">
					{#if domain.has_screenshot && !failedScreenshots.has(domain.domain)}
						<div class="screenshot-container">
							<img
								src={getDomainScreenshotUrl(domain.domain)}
								alt="{formatDomain(domain.domain)} screenshot"
								class="screenshot"
								onerror={() => handleScreenshotError(domain.domain)}
							/>
						</div>
					{:else}
						<div class="screenshot-placeholder">
							<img
								src={getDomainFaviconUrl(domain.domain)}
								alt="{formatDomain(domain.domain)} favicon"
								class="placeholder-favicon"
							/>
						</div>
					{/if}
					<div class="card-content">
						<div class="domain-header">
							<img
								src={getDomainFaviconUrl(domain.domain)}
								alt=""
								class="favicon"
							/>
							<h2>{formatDomain(domain.domain)}</h2>
						</div>
						<span class="count">{domain.count} recipes</span>
					</div>
				</a>
			{/each}
		</div>
	{/if}
</div>

<style>
	.browse-page {
		max-width: 100%;
	}

	.page-header {
		margin-bottom: var(--space-8);
	}

	h1 {
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-800);
	}

	.subtitle {
		color: var(--text-secondary);
		margin: 0;
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

	.domain-card h2 {
		margin: 0;
		color: var(--color-marinara-800);
		font-size: var(--text-lg);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.domain-card .count {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}
</style>
