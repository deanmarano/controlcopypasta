<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { browse, getDomainScreenshotUrl, getDomainFaviconUrl, type DomainInfo } from '$lib/api/client';

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

	<a href="/quicklist" class="quicklist-cta">
		<div class="cta-text">
			<strong>Not sure what to cook?</strong>
			<span>Swipe through recipes to find your next meal. Skip what you don't want, save what you might.</span>
			<span class="cta-action">Try it &rarr;</span>
		</div>
		<div class="cta-phone" aria-hidden="true">
			<div class="phone-frame">
				<div class="phone-header">
					<span class="phone-tag">Find</span>
					<span class="phone-tag-value">Dinner</span>
				</div>
				<div class="phone-cards">
					<div class="mock-card card-3"></div>
					<div class="mock-card card-2"></div>
					<div class="mock-card card-1">
						<div class="mock-img"></div>
						<div class="mock-overlay">
							<div class="mock-badge">30m</div>
							<div class="mock-title"></div>
							<div class="mock-subtitle"></div>
						</div>
						<div class="mock-label-maybe">MAYBE</div>
					</div>
				</div>
				<div class="phone-buttons">
					<div class="mock-btn mock-skip">Skip</div>
					<div class="mock-btn mock-view">View</div>
					<div class="mock-btn mock-maybe">Maybe</div>
				</div>
			</div>
		</div>
	</a>

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

	.quicklist-cta {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-6);
		padding: var(--space-6) var(--space-8);
		margin-bottom: var(--space-8);
		background: linear-gradient(135deg, var(--color-basil-50) 0%, var(--color-basil-100) 100%);
		border: var(--border-width-thin) solid var(--color-basil-300);
		border-radius: var(--radius-lg);
		text-decoration: none;
		transition: all var(--transition-fast);
		overflow: hidden;
	}

	.quicklist-cta:hover {
		border-color: var(--color-basil-400);
		box-shadow: var(--shadow-lg);
	}

	.quicklist-cta:hover .cta-phone {
		transform: scale(1.03);
	}

	.quicklist-cta:hover .mock-card.card-1 {
		transform: rotate(3deg);
	}

	.cta-text {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		flex: 1;
		min-width: 0;
	}

	.cta-text strong {
		color: var(--color-marinara-800);
		font-size: var(--text-xl);
		font-family: var(--font-serif);
	}

	.cta-text span {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		line-height: var(--leading-relaxed);
	}

	.cta-action {
		color: var(--color-basil-700) !important;
		font-weight: var(--font-semibold);
		font-size: var(--text-base) !important;
		margin-top: var(--space-1);
	}

	/* Phone mockup */
	.cta-phone {
		flex-shrink: 0;
		transition: transform var(--transition-normal);
	}

	.phone-frame {
		width: 140px;
		height: 200px;
		background: var(--bg-card);
		border-radius: 16px;
		box-shadow: var(--shadow-lg);
		padding: 8px;
		display: flex;
		flex-direction: column;
		overflow: hidden;
		border: 2px solid var(--color-gray-200);
	}

	.phone-header {
		display: flex;
		align-items: baseline;
		gap: 4px;
		padding: 4px 4px 6px;
	}

	.phone-tag {
		font-size: 9px;
		font-weight: var(--font-semibold);
		color: var(--color-marinara-800);
	}

	.phone-tag-value {
		font-size: 9px;
		color: var(--color-marinara-500);
		border-bottom: 1px solid var(--color-marinara-300);
	}

	.phone-cards {
		position: relative;
		flex: 1;
		margin: 0 2px;
	}

	.mock-card {
		position: absolute;
		inset: 0;
		border-radius: 8px;
		overflow: hidden;
	}

	.mock-card.card-3 {
		background: var(--color-gray-200);
		transform: scale(0.9) translateY(8px);
		z-index: 1;
	}

	.mock-card.card-2 {
		background: var(--color-gray-150, var(--color-gray-200));
		transform: scale(0.95) translateY(4px);
		z-index: 2;
	}

	.mock-card.card-1 {
		z-index: 3;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
		transition: transform var(--transition-normal);
		transform: rotate(0deg);
	}

	.mock-img {
		width: 100%;
		height: 100%;
		background: linear-gradient(
			145deg,
			var(--color-pasta-200) 0%,
			var(--color-pasta-300) 40%,
			var(--color-marinara-200) 100%
		);
	}

	.mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 16px 6px 6px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
	}

	.mock-badge {
		display: inline-block;
		font-size: 6px;
		color: white;
		background: rgba(255, 255, 255, 0.25);
		padding: 1px 4px;
		border-radius: 3px;
		margin-bottom: 3px;
	}

	.mock-title {
		height: 6px;
		width: 75%;
		background: rgba(255, 255, 255, 0.9);
		border-radius: 3px;
		margin-bottom: 3px;
	}

	.mock-subtitle {
		height: 4px;
		width: 50%;
		background: rgba(255, 255, 255, 0.5);
		border-radius: 2px;
	}

	.mock-label-maybe {
		position: absolute;
		top: 8px;
		left: 4px;
		font-size: 7px;
		font-weight: var(--font-bold);
		color: var(--color-basil-600);
		border: 1.5px solid var(--color-basil-600);
		background: rgba(255, 255, 255, 0.9);
		padding: 1px 4px;
		border-radius: 3px;
		transform: rotate(-12deg);
	}

	.phone-buttons {
		display: flex;
		justify-content: center;
		gap: 4px;
		padding: 6px 2px 4px;
	}

	.mock-btn {
		font-size: 6px;
		font-weight: var(--font-semibold);
		padding: 2px 8px;
		border-radius: 99px;
	}

	.mock-skip {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.mock-view {
		background: var(--color-gray-100);
		color: var(--text-primary);
	}

	.mock-maybe {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	@media (max-width: 640px) {
		.quicklist-cta {
			padding: var(--space-4) var(--space-5);
			gap: var(--space-4);
		}

		.cta-text strong {
			font-size: var(--text-lg);
		}

		.phone-frame {
			width: 110px;
			height: 160px;
		}
	}

	@media (max-width: 400px) {
		.cta-phone {
			display: none;
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
