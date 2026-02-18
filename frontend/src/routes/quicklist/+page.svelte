<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { quicklist, type DashboardRecipe } from '$lib/api/client';

	const tagOptions = ['dinner', 'breakfast', 'lunch', 'drinks', 'dessert', 'snacks'] as const;

	let selectedTag = $state<string>('dinner');
	let cards = $state<DashboardRecipe[]>([]);
	let loading = $state(true);
	let error = $state('');
	let swiping = $state(false);

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

<div class="quicklist-page">
	<header class="ql-header">
		<a href="/home" class="back-link">Back</a>
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
	{:else}
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

	@media (max-width: 500px) {
		.quicklist-page {
			padding: var(--space-3);
		}

		.card-stack {
			min-height: 350px;
		}
	}
</style>
