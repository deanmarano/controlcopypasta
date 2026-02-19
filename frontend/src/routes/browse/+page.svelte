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

	<div class="quicklist-ctas">
		<a href="/quicklist" class="quicklist-cta cta-swipe">
			<div class="cta-text">
				<strong>Tinder Style</strong>
				<span>Swipe right to save, left to skip. Rapid-fire recipe discovery, one card at a time.</span>
				<span class="cta-action">Try swiping &rarr;</span>
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
								<div class="mock-title-bar"></div>
								<div class="mock-subtitle-bar"></div>
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

		<a href="/quicklist" class="quicklist-cta cta-feed">
			<div class="cta-text">
				<strong>Instagram Style</strong>
				<span>Scroll a full-screen feed. Double-tap to save, just like your favorite app.</span>
				<span class="cta-action">Try scrolling &rarr;</span>
			</div>
			<div class="cta-phone" aria-hidden="true">
				<div class="phone-frame phone-frame-dark">
					<div class="feed-mock-card feed-card-current">
						<div class="feed-mock-img"></div>
						<div class="feed-mock-overlay">
							<div class="feed-mock-source">
								<div class="feed-mock-favicon"></div>
								<div class="feed-mock-domain-bar"></div>
							</div>
							<div class="feed-mock-title-bar"></div>
							<div class="feed-mock-time-bar"></div>
						</div>
						<div class="feed-mock-rail">
							<div class="feed-mock-heart">
								<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5">
									<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
								</svg>
							</div>
							<div class="feed-mock-rail-icon"></div>
							<div class="feed-mock-rail-icon"></div>
						</div>
						<div class="feed-mock-heart-burst">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
						</div>
					</div>
					<div class="feed-mock-card feed-card-next">
						<div class="feed-mock-img feed-mock-img-2"></div>
					</div>
				</div>
			</div>
		</a>
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

	.quicklist-cta {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-4);
		padding: var(--space-5) var(--space-6);
		border-radius: var(--radius-lg);
		text-decoration: none;
		transition: all var(--transition-fast);
		overflow: hidden;
		border: var(--border-width-thin) solid;
	}

	.cta-swipe {
		background: linear-gradient(135deg, var(--color-basil-50) 0%, var(--color-basil-100) 100%);
		border-color: var(--color-basil-300);
	}

	.cta-swipe:hover {
		border-color: var(--color-basil-400);
		box-shadow: var(--shadow-lg);
	}

	.cta-feed {
		background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
		border-color: #2a2a4a;
	}

	.cta-feed:hover {
		border-color: #4a4a6a;
		box-shadow: var(--shadow-lg);
	}

	.cta-feed .cta-text strong {
		color: #fff;
	}

	.cta-feed .cta-text span {
		color: rgba(255, 255, 255, 0.6);
	}

	.cta-feed .cta-action {
		color: #ff3040 !important;
	}

	.quicklist-cta:hover .cta-phone {
		transform: scale(1.03);
	}

	.cta-swipe:hover .mock-card.card-1 {
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

	.mock-title-bar {
		height: 6px;
		width: 75%;
		background: rgba(255, 255, 255, 0.9);
		border-radius: 3px;
		margin-bottom: 3px;
	}

	.mock-subtitle-bar {
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

	/* Feed phone mockup */
	.phone-frame-dark {
		background: #000 !important;
		border-color: #333 !important;
		padding: 0 !important;
		position: relative;
	}

	.feed-mock-card {
		position: absolute;
		inset: 0;
		overflow: hidden;
		border-radius: 14px;
	}

	.feed-card-current {
		z-index: 2;
	}

	.feed-card-next {
		z-index: 1;
		top: auto;
		bottom: -10px;
		height: 30px;
		border-radius: 0 0 14px 14px;
		opacity: 0.4;
	}

	.feed-mock-img {
		width: 100%;
		height: 100%;
		background: linear-gradient(
			160deg,
			#e8a87c 0%,
			#d4856a 40%,
			#b5654a 100%
		);
	}

	.feed-mock-img-2 {
		background: linear-gradient(
			160deg,
			#85c7a3 0%,
			#5ba37d 40%,
			#3d7a5a 100%
		);
	}

	.feed-mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 24px;
		padding: 20px 6px 8px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
	}

	.feed-mock-source {
		display: flex;
		align-items: center;
		gap: 3px;
		margin-bottom: 3px;
	}

	.feed-mock-favicon {
		width: 6px;
		height: 6px;
		border-radius: 1px;
		background: rgba(255, 255, 255, 0.5);
	}

	.feed-mock-domain-bar {
		height: 4px;
		width: 30px;
		background: rgba(255, 255, 255, 0.5);
		border-radius: 2px;
	}

	.feed-mock-title-bar {
		height: 6px;
		width: 70%;
		background: rgba(255, 255, 255, 0.9);
		border-radius: 3px;
		margin-bottom: 3px;
	}

	.feed-mock-time-bar {
		height: 4px;
		width: 25px;
		background: rgba(255, 255, 255, 0.4);
		border-radius: 2px;
	}

	.feed-mock-rail {
		position: absolute;
		right: 5px;
		bottom: 8px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 8px;
		z-index: 3;
	}

	.feed-mock-heart {
		filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.4));
	}

	.feed-mock-rail-icon {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		border: 1.5px solid rgba(255, 255, 255, 0.7);
	}

	.feed-mock-heart-burst {
		position: absolute;
		top: 50%;
		left: 45%;
		transform: translate(-50%, -50%);
		z-index: 5;
		animation: mockHeartPop 2s ease-out infinite;
	}

	@keyframes mockHeartPop {
		0%, 60% {
			opacity: 0;
			transform: translate(-50%, -50%) scale(0);
		}
		70% {
			opacity: 1;
			transform: translate(-50%, -50%) scale(1.3);
		}
		80% {
			transform: translate(-50%, -50%) scale(0.9);
		}
		90% {
			transform: translate(-50%, -50%) scale(1.05);
		}
		100% {
			opacity: 0;
			transform: translate(-50%, -50%) scale(1);
		}
	}

	@media (max-width: 768px) {
		.quicklist-ctas {
			grid-template-columns: 1fr;
		}
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
