<script lang="ts">
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { quicklist, type DashboardRecipe } from '$lib/api/client';

	const tagOptions = ['dinner', 'breakfast', 'lunch', 'drinks', 'dessert', 'snacks'] as const;

	let selectedTag = $state<string>('dinner');
	let cards = $state<DashboardRecipe[]>([]);
	let loading = $state(true);
	let error = $state('');
	let swiping = $state(false);

	// View mode
	let viewMode = $state<'swipe' | 'feed'>('swipe');
	let feedContainer = $state<HTMLElement | null>(null);
	let feedSentinel = $state<HTMLElement | null>(null);
	let dismissingId = $state<number | null>(null);

	onMount(() => {
		const saved = localStorage.getItem('quicklist-view');
		if (saved === 'swipe' || saved === 'feed') {
			viewMode = saved;
		}
	});

	function setViewMode(mode: 'swipe' | 'feed') {
		viewMode = mode;
		localStorage.setItem('quicklist-view', mode);
	}

	// IntersectionObserver for infinite scroll in feed mode
	$effect(() => {
		if (viewMode !== 'feed' || !feedSentinel) return;
		const observer = new IntersectionObserver(
			(entries) => {
				if (entries[0].isIntersecting && !loading && cards.length > 0) {
					loadBatch();
				}
			},
			{ root: feedContainer, threshold: 0.1 }
		);
		observer.observe(feedSentinel);
		return () => observer.disconnect();
	});

	let heartingId = $state<number | null>(null);
	let lastTapTime = 0;
	let lastTapTarget = 0;

	function onFeedCardTap(recipeId: number) {
		const now = Date.now();
		if (lastTapTarget === recipeId && now - lastTapTime < 400) {
			// Double-tap → heart
			handleFeedAction(recipeId, 'maybe');
			lastTapTime = 0;
			lastTapTarget = 0;
		} else {
			lastTapTime = now;
			lastTapTarget = recipeId;
		}
	}

	async function handleFeedAction(recipeId: number, action: 'maybe' | 'skip') {
		if (swiping) return;
		const token = authStore.getToken();
		if (!token) return;

		swiping = true;

		if (action === 'maybe') {
			heartingId = recipeId;
			await new Promise((r) => setTimeout(r, 800));
			heartingId = null;
		}

		dismissingId = recipeId;
		await new Promise((r) => setTimeout(r, 300));

		try {
			await quicklist.swipe(token, recipeId, action);
			cards = cards.filter((c) => c.id !== recipeId);
			if (cards.length < 5) {
				loadBatch();
			}
		} catch {
			// ignore
		} finally {
			swiping = false;
			dismissingId = null;
		}
	}

	// Drag state
	let dragX = $state(0);
	let dragStartX = 0;
	let isDragging = $state(false);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else {
			loadBatch();
		}
	});

	async function loadBatch() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await quicklist.batch(token, 10, selectedTag || undefined);
			cards = [...cards, ...result.data];
		} catch {
			error = 'Failed to load recipes';
		} finally {
			loading = false;
		}
	}

	function changeTag(newTag: string) {
		selectedTag = newTag;
		cards = [];
		loading = true;
		error = '';
		loadBatch();
	}

	function tagLabel(tag: string): string {
		return tag.charAt(0).toUpperCase() + tag.slice(1);
	}

	async function handleSwipe(action: 'maybe' | 'skip') {
		if (swiping || cards.length === 0) return;
		const token = authStore.getToken();
		if (!token) return;

		swiping = true;
		const recipe = cards[0];

		try {
			await quicklist.swipe(token, recipe.id, action);
			cards = cards.slice(1);

			// Auto-load more when stack is low
			if (cards.length < 3) {
				loadBatch();
			}
		} catch {
			// ignore swipe errors
		} finally {
			swiping = false;
			dragX = 0;
		}
	}

	function onPointerDown(e: PointerEvent) {
		isDragging = true;
		dragStartX = e.clientX;
		dragX = 0;
		const el = e.currentTarget as HTMLElement;
		el.setPointerCapture(e.pointerId);
	}

	function onPointerMove(e: PointerEvent) {
		if (!isDragging) return;
		e.preventDefault();
		dragX = e.clientX - dragStartX;
	}

	function onPointerUp(e: PointerEvent) {
		if (!isDragging) return;
		e.preventDefault();
		isDragging = false;

		if (dragX > 80) {
			handleSwipe('maybe');
		} else if (dragX < -80) {
			handleSwipe('skip');
		} else {
			dragX = 0;
		}
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return '';
		if (minutes < 60) return `${minutes}m`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours}h ${mins}m` : `${hours}h`;
	}

	function getSwipeIndicator(x: number): string {
		if (x > 40) return 'maybe';
		if (x < -40) return 'skip';
		return '';
	}
</script>

<div class="quicklist-page" class:feed-mode={viewMode === 'feed'}>
	<header class="ql-header">
		<a href="/home" class="back-link">Back</a>
		<div class="header-center">
			<div class="view-toggle">
				<button
					class="toggle-btn"
					class:active={viewMode === 'swipe'}
					onclick={() => setViewMode('swipe')}
					aria-label="Swipe view"
				>
					<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
						<rect x="2" y="3" width="20" height="18" rx="3" />
						<path d="M9 14l2 2 4-4" />
					</svg>
				</button>
				<button
					class="toggle-btn"
					class:active={viewMode === 'feed'}
					onclick={() => setViewMode('feed')}
					aria-label="Feed view"
				>
					<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
						<rect x="3" y="3" width="18" height="6" rx="2" />
						<rect x="3" y="13" width="18" height="6" rx="2" />
					</svg>
				</button>
			</div>
			<div class="tag-picker">
				<span class="tag-label">Find</span>
				<select
					class="tag-select"
					value={selectedTag}
					onchange={(e) => changeTag((e.target as HTMLSelectElement).value)}
				>
					{#each tagOptions as tag}
						<option value={tag}>{tagLabel(tag)}</option>
					{/each}
				</select>
			</div>
		</div>
		<a href="/quicklist/maybe" class="maybe-link">Maybe List</a>
	</header>

	{#if loading && cards.length === 0}
		<div class="loading">Loading recipes...</div>
	{:else if error && cards.length === 0}
		<div class="error">{error}</div>
	{:else if cards.length === 0}
		<div class="empty">
			<h2>All caught up!</h2>
			<p>You've seen all the available recipes. Check back later for more.</p>
			<a href="/quicklist/maybe" class="btn-primary">View Maybe List</a>
		</div>
	{:else if viewMode === 'swipe'}
		<div class="card-stack">
			{#each cards.slice(0, 3) as recipe, i (recipe.id)}
				{@const isTop = i === 0}
				<div
					class="swipe-card"
					class:top={isTop}
					class:dragging={isTop && isDragging}
					class:indicator-maybe={isTop && getSwipeIndicator(dragX) === 'maybe'}
					class:indicator-skip={isTop && getSwipeIndicator(dragX) === 'skip'}
					style:transform={isTop ? `translateX(${dragX}px) rotate(${dragX * 0.05}deg)` : `scale(${1 - i * 0.05}) translateY(${i * 8}px)`}
					style:z-index={10 - i}
					onpointerdown={isTop ? onPointerDown : undefined}
					onpointermove={isTop ? onPointerMove : undefined}
					onpointerup={isTop ? onPointerUp : undefined}
					role={isTop ? 'button' : undefined}
					tabindex={isTop ? 0 : -1}
				>
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="card-img" draggable="false" />
					{:else}
						<div class="card-img placeholder">No image</div>
					{/if}
					<div class="card-overlay">
						<div class="card-badges">
							{#if recipe.total_time_minutes}
								<span class="badge">{formatTime(recipe.total_time_minutes)}</span>
							{/if}
							{#if recipe.source_domain}
								<span class="badge">{recipe.source_domain}</span>
							{/if}
						</div>
						<h2>{recipe.title}</h2>
						{#if recipe.description}
							<p class="card-desc">{recipe.description}</p>
						{/if}
					</div>

					{#if isTop && getSwipeIndicator(dragX) === 'maybe'}
						<div class="swipe-label maybe-label">MAYBE</div>
					{/if}
					{#if isTop && getSwipeIndicator(dragX) === 'skip'}
						<div class="swipe-label skip-label">SKIP</div>
					{/if}
				</div>
			{/each}
		</div>

		<div class="action-buttons">
			<button class="action-btn skip" onclick={() => handleSwipe('skip')} disabled={swiping}>
				Skip
			</button>
			<button class="action-btn view" onclick={() => goto(`/recipes/${cards[0]?.id}`)} disabled={swiping || cards.length === 0}>
				View
			</button>
			<button class="action-btn maybe" onclick={() => handleSwipe('maybe')} disabled={swiping}>
				Maybe
			</button>
		</div>
	{:else}
		<!-- Floating top bar over feed -->
		<div class="feed-top-bar">
			<button class="feed-nav-btn" onclick={() => setViewMode('swipe')} aria-label="Back to swipe view">
				<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
					<line x1="19" y1="12" x2="5" y2="12"/>
					<polyline points="12 19 5 12 12 5"/>
				</svg>
			</button>
			<div class="feed-tag-pills">
				{#each tagOptions as tag}
					<button
						class="feed-tag-pill"
						class:active={selectedTag === tag}
						onclick={() => changeTag(tag)}
					>{tagLabel(tag)}</button>
				{/each}
			</div>
			<a href="/quicklist/maybe" class="feed-nav-btn" aria-label="Maybe list">
				<svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
					<path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
				</svg>
			</a>
		</div>

		<div class="feed-container" bind:this={feedContainer}>
			{#each cards as recipe (recipe.id)}
				<div
					class="feed-card"
					class:dismissing={dismissingId === recipe.id}
					onclick={() => onFeedCardTap(recipe.id)}
					role="button"
					tabindex="0"
				>
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="feed-card-img" />
					{:else}
						<div class="feed-card-img placeholder">No image</div>
					{/if}

					{#if heartingId === recipe.id}
						<div class="heart-burst">
							<svg width="100" height="100" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
						</div>
					{/if}

					<!-- Right-side action rail -->
					<div class="feed-action-rail">
						<button class="rail-btn" onclick={(e: MouseEvent) => { e.stopPropagation(); handleFeedAction(recipe.id, 'maybe'); }} disabled={swiping} aria-label="Save recipe">
							<svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
							<span class="rail-label">Save</span>
						</button>
						<a class="rail-btn" href="/recipes/{recipe.id}" onclick={(e: MouseEvent) => e.stopPropagation()} aria-label="View recipe">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
								<line x1="3" y1="9" x2="21" y2="9"/>
								<line x1="9" y1="21" x2="9" y2="9"/>
							</svg>
							<span class="rail-label">View</span>
						</a>
						<button class="rail-btn" onclick={(e: MouseEvent) => { e.stopPropagation(); handleFeedAction(recipe.id, 'skip'); }} disabled={swiping} aria-label="Skip recipe">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<circle cx="12" cy="12" r="10"/>
								<line x1="15" y1="9" x2="9" y2="15"/>
								<line x1="9" y1="9" x2="15" y2="15"/>
							</svg>
							<span class="rail-label">Skip</span>
						</button>
					</div>

					<!-- Bottom info -->
					<div class="feed-card-overlay">
						<div class="feed-card-overlay-content">
							{#if recipe.source_domain}
								<span class="feed-source">
									<img
										src="https://www.google.com/s2/favicons?domain={recipe.source_domain}&sz=32"
										alt=""
										class="feed-favicon"
										width="14"
										height="14"
									/>
									{recipe.source_domain}
								</span>
							{/if}
							<h2 class="feed-title">{recipe.title}</h2>
							{#if recipe.total_time_minutes}
								<div class="feed-detail">
									<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
										<circle cx="12" cy="12" r="10"/>
										<polyline points="12 6 12 12 16 14"/>
									</svg>
									{formatTime(recipe.total_time_minutes)}
								</div>
							{/if}
						</div>
					</div>
				</div>
			{/each}
			<div class="feed-sentinel" bind:this={feedSentinel}></div>
			{#if loading}
				<div class="feed-loading">
					<div class="feed-spinner"></div>
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.quicklist-page {
		max-width: 500px;
		margin: 0 auto;
		padding: var(--space-4);
		min-height: 80vh;
		display: flex;
		flex-direction: column;
		overflow: hidden;
	}

	.ql-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-6);
	}

	.tag-picker {
		display: flex;
		align-items: baseline;
		gap: var(--space-2);
	}

	.tag-label {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		color: var(--color-marinara-800);
	}

	.tag-select {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		color: var(--color-marinara-600);
		background: none;
		border: none;
		border-bottom: 2px solid var(--color-marinara-300);
		padding: 0 var(--space-1);
		cursor: pointer;
		appearance: auto;
	}

	.tag-select:focus {
		outline: none;
		border-bottom-color: var(--color-marinara-600);
	}

	.back-link,
	.maybe-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
	}

	.back-link:hover,
	.maybe-link:hover {
		text-decoration: underline;
	}

	.loading,
	.error {
		text-align: center;
		padding: var(--space-12);
		color: var(--text-secondary);
	}

	.error {
		color: var(--color-error);
	}

	.empty {
		text-align: center;
		padding: var(--space-12) var(--space-4);
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}

	.empty h2 {
		font-family: var(--font-serif);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-3);
	}

	.empty p {
		color: var(--text-secondary);
		margin: 0 0 var(--space-6);
	}

	.btn-primary {
		display: inline-block;
		padding: var(--space-3) var(--space-6);
		background: var(--color-basil-600);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
	}

	.btn-primary:hover {
		background: var(--color-basil-700);
	}

	/* Card stack */
	.card-stack {
		position: relative;
		flex: 1;
		min-height: 400px;
		max-height: 65vh;
	}

	.swipe-card {
		position: absolute;
		inset: 0;
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-lg);
		background: var(--bg-card);
		user-select: none;
		transition: transform 0.2s ease;
	}

	.swipe-card.top {
		cursor: grab;
		transition: none;
		touch-action: none;
	}

	.swipe-card.dragging {
		cursor: grabbing;
	}

	.swipe-card.indicator-maybe {
		box-shadow: 0 0 0 3px var(--color-basil-500), var(--shadow-lg);
	}

	.swipe-card.indicator-skip {
		box-shadow: 0 0 0 3px var(--color-marinara-500), var(--shadow-lg);
	}

	.card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.card-img.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
	}

	.card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: var(--space-12) var(--space-5) var(--space-5);
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
		color: white;
	}

	.card-overlay h2 {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		margin: 0 0 var(--space-2);
		color: white;
		line-height: var(--leading-snug);
	}

	.card-desc {
		margin: 0;
		font-size: var(--text-sm);
		opacity: 0.85;
		display: -webkit-box;
		-webkit-line-clamp: 2;
		-webkit-box-orient: vertical;
		overflow: hidden;
	}

	.card-badges {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-2);
	}

	.badge {
		padding: var(--space-1) var(--space-2);
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	/* Swipe labels */
	.swipe-label {
		position: absolute;
		top: var(--space-8);
		padding: var(--space-2) var(--space-5);
		font-size: var(--text-3xl);
		font-weight: var(--font-bold);
		border-radius: var(--radius-md);
		border: 3px solid;
		transform: rotate(-15deg);
	}

	.maybe-label {
		left: var(--space-6);
		color: var(--color-basil-600);
		border-color: var(--color-basil-600);
		background: rgba(255, 255, 255, 0.9);
	}

	.skip-label {
		right: var(--space-6);
		color: var(--color-marinara-600);
		border-color: var(--color-marinara-600);
		background: rgba(255, 255, 255, 0.9);
		transform: rotate(15deg);
	}

	/* Action buttons */
	.action-buttons {
		display: flex;
		justify-content: center;
		gap: var(--space-4);
		padding: var(--space-6) 0 var(--space-2);
	}

	.action-btn {
		padding: var(--space-3) var(--space-8);
		border: none;
		border-radius: var(--radius-full);
		font-size: var(--text-base);
		font-weight: var(--font-semibold);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.action-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.action-btn.skip {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.action-btn.skip:hover:not(:disabled) {
		background: var(--color-marinara-200);
	}

	.action-btn.view {
		background: var(--color-gray-100);
		color: var(--text-primary);
	}

	.action-btn.view:hover:not(:disabled) {
		background: var(--color-gray-200);
	}

	.action-btn.maybe {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.action-btn.maybe:hover:not(:disabled) {
		background: var(--color-basil-200);
	}

	/* Header center group */
	.header-center {
		display: flex;
		align-items: center;
		gap: var(--space-3);
	}

	/* View toggle */
	.view-toggle {
		display: flex;
		background: var(--color-gray-100);
		border-radius: var(--radius-md);
		padding: 2px;
	}

	.toggle-btn {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 32px;
		height: 32px;
		border: none;
		border-radius: var(--radius-sm);
		background: transparent;
		color: var(--text-muted);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.toggle-btn.active {
		background: var(--color-white);
		color: var(--color-marinara-700);
		box-shadow: var(--shadow-sm);
	}

	.toggle-btn:hover:not(.active) {
		color: var(--text-primary);
	}

	/* Feed mode: immersive full-screen */
	.quicklist-page.feed-mode {
		position: fixed;
		inset: 0;
		z-index: 100;
		max-width: none;
		padding: 0;
		margin: 0;
		background: #000;
		overflow: hidden;
	}

	.feed-mode .ql-header {
		display: none;
	}

	/* Floating top bar */
	.feed-top-bar {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		z-index: 20;
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: env(safe-area-inset-top, 12px) var(--space-3) var(--space-2);
		background: linear-gradient(rgba(0, 0, 0, 0.5), transparent);
		pointer-events: none;
	}

	.feed-top-bar > * {
		pointer-events: auto;
	}

	.feed-nav-btn {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 40px;
		height: 40px;
		border: none;
		border-radius: 50%;
		background: transparent;
		color: white;
		cursor: pointer;
		text-decoration: none;
		flex-shrink: 0;
		filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.4));
	}

	.feed-tag-pills {
		flex: 1;
		display: flex;
		gap: 6px;
		overflow-x: auto;
		scrollbar-width: none;
		-ms-overflow-style: none;
		padding: var(--space-1) 0;
	}

	.feed-tag-pills::-webkit-scrollbar {
		display: none;
	}

	.feed-tag-pill {
		padding: 6px 14px;
		border-radius: var(--radius-full);
		border: 1.5px solid rgba(255, 255, 255, 0.4);
		background: rgba(0, 0, 0, 0.3);
		backdrop-filter: blur(8px);
		-webkit-backdrop-filter: blur(8px);
		color: rgba(255, 255, 255, 0.85);
		font-size: 13px;
		font-weight: 600;
		cursor: pointer;
		white-space: nowrap;
		flex-shrink: 0;
		transition: all 0.15s ease;
	}

	.feed-tag-pill.active {
		background: white;
		color: #000;
		border-color: white;
	}

	/* Feed container */
	.feed-container {
		position: absolute;
		inset: 0;
		overflow-y: auto;
		scroll-snap-type: y mandatory;
		-webkit-overflow-scrolling: touch;
		container-type: size;
	}

	.feed-card {
		height: 100cqh;
		scroll-snap-align: start;
		scroll-snap-stop: always;
		position: relative;
		overflow: hidden;
		background: #000;
		transition: opacity 0.3s ease;
	}

	.feed-card.dismissing {
		opacity: 0;
	}

	.feed-card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}

	.feed-card-img.placeholder {
		background: #1a1a1a;
		display: flex;
		align-items: center;
		justify-content: center;
		color: #555;
		font-size: var(--text-lg);
	}

	/* Bottom overlay */
	.feed-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 120px 0 0;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
		color: white;
		pointer-events: none;
	}

	.feed-card-overlay-content {
		padding: 0 72px 24px 16px;
	}

	.feed-source {
		font-size: 13px;
		font-weight: 600;
		opacity: 0.85;
		display: flex;
		align-items: center;
		gap: 6px;
		margin-bottom: 5px;
	}

	.feed-favicon {
		border-radius: 2px;
		flex-shrink: 0;
	}

	.feed-title {
		font-family: var(--font-serif);
		font-size: 20px;
		font-weight: 700;
		margin: 0;
		color: white;
		line-height: 1.25;
		text-shadow: 0 1px 4px rgba(0, 0, 0, 0.6);
	}

	.feed-detail {
		display: flex;
		align-items: center;
		gap: 4px;
		margin-top: 6px;
		font-size: 13px;
		opacity: 0.75;
		color: white;
	}

	/* Right-side action rail */
	.feed-action-rail {
		position: absolute;
		right: 8px;
		bottom: 24px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 20px;
		z-index: 5;
	}

	.rail-btn {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 4px;
		border: none;
		background: transparent;
		color: white;
		cursor: pointer;
		text-decoration: none;
		filter: drop-shadow(0 1px 4px rgba(0, 0, 0, 0.6));
		transition: transform 0.15s ease;
		padding: 0;
	}

	.rail-btn:active:not(:disabled) {
		transform: scale(0.85);
	}

	.rail-btn:disabled {
		opacity: 0.3;
		cursor: not-allowed;
	}

	.rail-label {
		font-size: 11px;
		font-weight: 600;
		text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
	}

	/* Heart burst animation */
	.heart-burst {
		position: absolute;
		inset: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 10;
		pointer-events: none;
		animation: heartPop 0.8s ease-out forwards;
	}

	@keyframes heartPop {
		0% {
			opacity: 0;
			transform: scale(0);
		}
		15% {
			opacity: 1;
			transform: scale(1.4);
		}
		30% {
			transform: scale(0.9);
		}
		50% {
			transform: scale(1.1);
		}
		100% {
			opacity: 0;
			transform: scale(1);
		}
	}

	.feed-sentinel {
		height: 1px;
	}

	.feed-loading {
		display: flex;
		justify-content: center;
		padding: 40px 0;
	}

	.feed-spinner {
		width: 24px;
		height: 24px;
		border: 2.5px solid rgba(255, 255, 255, 0.2);
		border-top-color: white;
		border-radius: 50%;
		animation: spin 0.7s linear infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	@media (max-width: 500px) {
		.quicklist-page {
			padding: var(--space-3);
		}

		.card-stack {
			min-height: 350px;
		}
	}
</style>
