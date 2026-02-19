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

	async function handleFeedAction(recipeId: number, action: 'maybe' | 'skip') {
		if (swiping) return;
		const token = authStore.getToken();
		if (!token) return;

		swiping = true;

		if (action === 'maybe') {
			// Show heart animation before dismissing
			heartingId = recipeId;
			await new Promise((r) => setTimeout(r, 600));
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
		<div class="feed-container" bind:this={feedContainer}>
			{#each cards as recipe (recipe.id)}
				<div class="feed-card" class:dismissing={dismissingId === recipe.id}>
					{#if recipe.image_url}
						<img src={recipe.image_url} alt={recipe.title} class="feed-card-img" />
					{:else}
						<div class="feed-card-img placeholder">No image</div>
					{/if}

					<!-- Heart animation overlay -->
					{#if heartingId === recipe.id}
						<div class="heart-burst">
							<svg width="80" height="80" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
						</div>
					{/if}

					<!-- Right-side icon buttons (Instagram-style) -->
					<div class="feed-side-actions">
						<button class="feed-icon-btn heart" onclick={() => handleFeedAction(recipe.id, 'maybe')} disabled={swiping} aria-label="Save recipe">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
						</button>
						<button class="feed-icon-btn" onclick={() => goto(`/recipes/${recipe.id}`)} aria-label="View recipe">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<path d="M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6"/>
								<polyline points="15 3 21 3 21 9"/>
								<line x1="10" y1="14" x2="21" y2="3"/>
							</svg>
						</button>
						<button class="feed-icon-btn skip" onclick={() => handleFeedAction(recipe.id, 'skip')} disabled={swiping} aria-label="Skip recipe">
							<svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
								<line x1="18" y1="6" x2="6" y2="18"/>
								<line x1="6" y1="6" x2="18" y2="18"/>
							</svg>
						</button>
					</div>

					<!-- Bottom info overlay -->
					<div class="feed-card-overlay">
						<h2>{recipe.title}</h2>
						<div class="feed-meta">
							{#if recipe.total_time_minutes}
								<span class="feed-meta-item">{formatTime(recipe.total_time_minutes)}</span>
							{/if}
							{#if recipe.source_domain}
								<span class="feed-meta-item">{recipe.source_domain}</span>
							{/if}
						</div>
					</div>
				</div>
			{/each}
			<div class="feed-sentinel" bind:this={feedSentinel}></div>
			{#if loading}
				<div class="feed-loading">Loading more...</div>
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

	/* Feed mode: full-screen overlay to escape layout chrome */
	.quicklist-page.feed-mode {
		position: fixed;
		inset: 0;
		z-index: 100;
		max-width: none;
		padding: 0;
		margin: 0;
		background: var(--bg-page, #fff);
		overflow: hidden;
	}

	.feed-mode .ql-header {
		padding: var(--space-2) var(--space-4);
		margin-bottom: 0;
	}

	/* Feed view */
	.feed-container {
		flex: 1;
		min-height: 0;
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
		transition: opacity 0.3s ease, transform 0.3s ease;
	}

	.feed-card.dismissing {
		opacity: 0;
		transform: scale(0.95);
	}

	.feed-card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}

	.feed-card-img.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
		font-size: var(--text-lg);
	}

	.feed-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 60px;
		padding: var(--space-12) var(--space-4) var(--space-5);
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
		color: white;
	}

	.feed-card-overlay h2 {
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		margin: 0 0 var(--space-1);
		color: white;
		line-height: var(--leading-snug);
		text-shadow: 0 1px 3px rgba(0, 0, 0, 0.5);
	}

	.feed-meta {
		display: flex;
		gap: var(--space-3);
		font-size: var(--text-sm);
		opacity: 0.8;
	}

	.feed-meta-item {
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	}

	/* Right-side icon buttons */
	.feed-side-actions {
		position: absolute;
		right: var(--space-3);
		bottom: var(--space-5);
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: var(--space-5);
	}

	.feed-icon-btn {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 48px;
		height: 48px;
		border: none;
		border-radius: 50%;
		background: transparent;
		color: white;
		cursor: pointer;
		filter: drop-shadow(0 1px 3px rgba(0, 0, 0, 0.5));
		transition: transform 0.15s ease;
	}

	.feed-icon-btn:active:not(:disabled) {
		transform: scale(0.9);
	}

	.feed-icon-btn:disabled {
		opacity: 0.4;
		cursor: not-allowed;
	}

	.feed-icon-btn.heart:hover:not(:disabled) {
		color: #ff3040;
	}

	.feed-icon-btn.skip:hover:not(:disabled) {
		color: rgba(255, 255, 255, 0.6);
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
		animation: heartPop 0.6s ease-out forwards;
	}

	@keyframes heartPop {
		0% {
			opacity: 0;
			transform: scale(0);
		}
		15% {
			opacity: 1;
			transform: scale(1.3);
		}
		30% {
			transform: scale(0.95);
		}
		45% {
			transform: scale(1.05);
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
		text-align: center;
		padding: var(--space-6);
		color: var(--text-secondary);
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
