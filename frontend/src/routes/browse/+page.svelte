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
						<div class="mock-card card-3">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/63ac55080a308b862e48c9b2_639a44e8692ea801789551cd_quinoa-pesto-bowl-thumbnail.webp" alt="" class="mock-card-photo" />
						</div>
						<div class="mock-card card-2">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6470dfae89487940cd3f2c85_one-pot-lemon-pasta-thumbnail.webp" alt="" class="mock-card-photo" />
						</div>
						<div class="mock-card card-1">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6585b42a484dac29edc39a97_jalapeno-pimento-cheese-thumbnail.webp" alt="" class="mock-card-photo" />
							<div class="mock-overlay">
								<div class="mock-badge">30m</div>
								<div class="mock-title-bar"></div>
								<div class="mock-subtitle-bar"></div>
							</div>
							<div class="mock-label-maybe">MAYBE</div>
							<div class="mock-label-skip">SKIP</div>
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
					<div class="feed-mock-scroll">
						<div class="feed-mock-slide">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/64b959a840c6917d162cf62b_salmon-quiona-salad-thumbnail.webp" alt="" class="feed-mock-photo" />
							<div class="feed-mock-overlay">
								<div class="feed-mock-source">
									<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
									<span class="feed-mock-domain">sigsbeestreet.co</span>
								</div>
								<div class="feed-mock-name">Salmon Quinoa Salad</div>
							</div>
							<div class="feed-mock-rail">
								<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
								<div class="feed-rail-dot"></div>
								<div class="feed-rail-dot"></div>
							</div>
						</div>
						<div class="feed-mock-slide">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6470dfae89487940cd3f2c85_one-pot-lemon-pasta-thumbnail.webp" alt="" class="feed-mock-photo" />
							<div class="feed-mock-overlay">
								<div class="feed-mock-source">
									<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
									<span class="feed-mock-domain">sigsbeestreet.co</span>
								</div>
								<div class="feed-mock-name">One Pot Lemon Pasta</div>
							</div>
							<div class="feed-mock-rail">
								<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
								<div class="feed-rail-dot"></div>
								<div class="feed-rail-dot"></div>
							</div>
						</div>
						<div class="feed-mock-slide">
							<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/63ac55080a308b862e48c9b2_639a44e8692ea801789551cd_quinoa-pesto-bowl-thumbnail.webp" alt="" class="feed-mock-photo" />
							<div class="feed-mock-overlay">
								<div class="feed-mock-source">
									<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
									<span class="feed-mock-domain">sigsbeestreet.co</span>
								</div>
								<div class="feed-mock-name">Quinoa Pesto Bowl</div>
							</div>
							<div class="feed-mock-rail">
								<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
								<div class="feed-rail-dot"></div>
								<div class="feed-rail-dot"></div>
							</div>
						</div>
					</div>
					<!-- Heart burst on hover -->
					<div class="feed-mock-heart-burst">
						<svg width="32" height="32" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
							<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
						</svg>
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
		animation: swipeDemo 4s ease-in-out infinite;
	}

	.cta-swipe:hover .mock-label-maybe {
		animation: swipeLabelMaybe 4s ease-in-out infinite;
	}

	.cta-swipe:hover .mock-label-skip {
		animation: swipeLabelSkip 4s ease-in-out infinite;
	}

	@keyframes swipeDemo {
		0%, 10% { transform: rotate(0deg) translateX(0); opacity: 1; }
		20% { transform: rotate(8deg) translateX(30px); opacity: 1; }
		28% { transform: rotate(12deg) translateX(60px); opacity: 0; }
		29% { transform: rotate(0deg) translateX(0); opacity: 0; }
		35% { transform: rotate(0deg) translateX(0); opacity: 1; }
		45%, 55% { transform: rotate(0deg) translateX(0); opacity: 1; }
		65% { transform: rotate(-8deg) translateX(-30px); opacity: 1; }
		73% { transform: rotate(-12deg) translateX(-60px); opacity: 0; }
		74% { transform: rotate(0deg) translateX(0); opacity: 0; }
		80%, 100% { transform: rotate(0deg) translateX(0); opacity: 1; }
	}

	@keyframes swipeLabelMaybe {
		0%, 10% { opacity: 0; }
		18% { opacity: 1; }
		28%, 100% { opacity: 0; }
	}

	@keyframes swipeLabelSkip {
		0%, 55% { opacity: 0; }
		63% { opacity: 1; }
		73%, 100% { opacity: 0; }
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

	.mock-card-photo {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
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

	.mock-label-maybe,
	.mock-label-skip {
		position: absolute;
		top: 8px;
		font-size: 7px;
		font-weight: var(--font-bold);
		background: rgba(255, 255, 255, 0.9);
		padding: 1px 4px;
		border-radius: 3px;
		border: 1.5px solid;
		opacity: 0;
	}

	.mock-label-maybe {
		left: 4px;
		color: var(--color-basil-600);
		border-color: var(--color-basil-600);
		transform: rotate(-12deg);
	}

	.mock-label-skip {
		right: 4px;
		color: var(--color-marinara-600);
		border-color: var(--color-marinara-600);
		transform: rotate(12deg);
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
		overflow: hidden;
	}

	.feed-mock-scroll {
		animation: none;
	}

	.cta-feed:hover .feed-mock-scroll {
		animation: feedScroll 6s ease-in-out infinite;
	}

	@keyframes feedScroll {
		0%, 20% { transform: translateY(0); }
		33%, 53% { transform: translateY(-33.333%); }
		66%, 86% { transform: translateY(-66.666%); }
		100% { transform: translateY(0); }
	}

	.feed-mock-slide {
		width: 100%;
		aspect-ratio: 140 / 200;
		position: relative;
		overflow: hidden;
	}

	.feed-mock-photo {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}

	.feed-mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 24px 6px 8px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
	}

	.feed-mock-source {
		display: flex;
		align-items: center;
		gap: 3px;
		margin-bottom: 2px;
	}

	.feed-mock-fav {
		width: 8px;
		height: 8px;
		border-radius: 1px;
	}

	.feed-mock-domain {
		font-size: 5px;
		color: rgba(255, 255, 255, 0.6);
		font-weight: 600;
	}

	.feed-mock-name {
		font-size: 7px;
		font-weight: 700;
		color: white;
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	}

	.feed-mock-rail {
		position: absolute;
		right: 5px;
		bottom: 8px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		z-index: 3;
	}

	.feed-rail-heart {
		filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.4));
	}

	.feed-rail-dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		border: 1.5px solid rgba(255, 255, 255, 0.7);
	}

	/* Heart burst: synced with scroll, fires on 1st and 3rd slides */
	.feed-mock-heart-burst {
		position: absolute;
		top: 50%;
		left: 45%;
		transform: translate(-50%, -50%) scale(0);
		z-index: 5;
		opacity: 0;
		pointer-events: none;
	}

	.cta-feed:hover .feed-mock-heart-burst {
		animation: mockHeartSync 6s ease-in-out infinite;
	}

	@keyframes mockHeartSync {
		/* Heart on 1st slide (visible 0-20%) — pop at ~12% */
		0%, 10% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		12% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		14% { transform: translate(-50%, -50%) scale(0.9); }
		16% { transform: translate(-50%, -50%) scale(1.05); }
		20% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		/* No heart on 2nd slide (33-53%) */
		33%, 64% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		/* Heart on 3rd slide (visible 66-86%) — pop at ~76% */
		76% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		78% { transform: translate(-50%, -50%) scale(0.9); }
		80% { transform: translate(-50%, -50%) scale(1.05); }
		84% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		85%, 100% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
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
