<script lang="ts">
	import { onDestroy } from 'svelte';

	let { href = '/login' }: { href?: string } = $props();

	// Swipe card animation state
	let swipeActive = $state(0);
	let swipeState = $state<'idle' | 'showing' | 'label' | 'swiping'>('idle');
	let swipeTimers: ReturnType<typeof setTimeout>[] = [];
	let containerEl = $state<HTMLElement | null>(null);

	function clearSwipeTimers() {
		swipeTimers.forEach(clearTimeout);
		swipeTimers = [];
	}

	function scheduleSwipe() {
		swipeTimers.push(setTimeout(() => {
			swipeState = 'label';
			swipeTimers.push(setTimeout(() => {
				swipeState = 'swiping';
				swipeTimers.push(setTimeout(() => {
					const next = swipeActive + 1;
					if (next >= 4) {
						swipeState = 'idle';
						swipeTimers.push(setTimeout(() => {
							swipeActive = 0;
							swipeState = 'showing';
							scheduleSwipe();
						}, 600));
					} else {
						swipeActive = next;
						swipeState = 'showing';
						scheduleSwipe();
					}
				}, 500));
			}, 400));
		}, 1200));
	}

	function startSwipeAnimation() {
		clearSwipeTimers();
		swipeActive = 0;
		swipeState = 'showing';
		scheduleSwipe();
	}

	function stopSwipeAnimation() {
		clearSwipeTimers();
		swipeActive = 0;
		swipeState = 'idle';
	}

	function getSwipeClass(cardIndex: number): string {
		if (swipeState === 'idle') {
			return ['sc-front', 'sc-behind-1', 'sc-behind-2', 'sc-behind-3'][cardIndex];
		}
		if (cardIndex === swipeActive) {
			if (swipeState === 'swiping') {
				return cardIndex % 2 === 0 ? 'sc-front sc-swipe-right' : 'sc-front sc-swipe-left';
			}
			return 'sc-front';
		}
		if (cardIndex < swipeActive) return 'sc-gone';
		const behind = cardIndex - swipeActive;
		return ['', 'sc-behind-1', 'sc-behind-2', 'sc-behind-3'][behind];
	}

	function showLabel(cardIndex: number, label: 'maybe' | 'skip'): boolean {
		if (cardIndex !== swipeActive || swipeState !== 'label') return false;
		return cardIndex % 2 === 0 ? label === 'maybe' : label === 'skip';
	}

	// IntersectionObserver for auto-play
	$effect(() => {
		if (!containerEl) return;
		const observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) {
					if (entry.isIntersecting) {
						startSwipeAnimation();
					} else {
						stopSwipeAnimation();
					}
				}
			},
			{ threshold: 0.3 }
		);
		observer.observe(containerEl);
		return () => observer.disconnect();
	});

	onDestroy(clearSwipeTimers);
</script>

<a {href} class="ql-card ql-swipe" bind:this={containerEl}>
	<div class="ql-text">
		<strong>Tinder Style</strong>
		<span>Swipe right to save, left to skip. Rapid-fire recipe discovery, one card at a time.</span>
		<span class="ql-action">Try swiping &rarr;</span>
	</div>
	<div class="ql-phone" aria-hidden="true">
		<div class="phone-frame">
			<div class="phone-header">
				<span class="phone-tag">Find</span>
				<span class="phone-tag-value">Dinner</span>
			</div>
			<div class="phone-cards">
				<div class="mock-card {getSwipeClass(3)}">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/649b7f9aaa7e9bd7c9662b4d_watermelon-basil-salad-thumbnail.webp" alt="" class="mock-card-photo" />
					<div class="mock-overlay">
						<div class="mock-badge">15m</div>
						<div class="mock-title-bar"></div>
						<div class="mock-subtitle-bar"></div>
					</div>
					<div class="mock-label-maybe" class:label-show={showLabel(3, 'maybe')}>MAYBE</div>
					<div class="mock-label-skip" class:label-show={showLabel(3, 'skip')}>SKIP</div>
				</div>
				<div class="mock-card {getSwipeClass(2)}">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6723a19fcc12a7d0178521d9_tomato-red-pepper-soup-thumbnail.webp" alt="" class="mock-card-photo" />
					<div class="mock-overlay">
						<div class="mock-badge">45m</div>
						<div class="mock-title-bar"></div>
						<div class="mock-subtitle-bar"></div>
					</div>
					<div class="mock-label-maybe" class:label-show={showLabel(2, 'maybe')}>MAYBE</div>
					<div class="mock-label-skip" class:label-show={showLabel(2, 'skip')}>SKIP</div>
				</div>
				<div class="mock-card {getSwipeClass(1)}">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/668c7c1038f9ea42fc3eff27_spinach-feta-grilled-cheese-thumbnail.webp" alt="" class="mock-card-photo" />
					<div class="mock-overlay">
						<div class="mock-badge">20m</div>
						<div class="mock-title-bar"></div>
						<div class="mock-subtitle-bar"></div>
					</div>
					<div class="mock-label-maybe" class:label-show={showLabel(1, 'maybe')}>MAYBE</div>
					<div class="mock-label-skip" class:label-show={showLabel(1, 'skip')}>SKIP</div>
				</div>
				<div class="mock-card {getSwipeClass(0)}">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6585b42a484dac29edc39a97_jalapeno-pimento-cheese-thumbnail.webp" alt="" class="mock-card-photo" />
					<div class="mock-overlay">
						<div class="mock-badge">30m</div>
						<div class="mock-title-bar"></div>
						<div class="mock-subtitle-bar"></div>
					</div>
					<div class="mock-label-maybe" class:label-show={showLabel(0, 'maybe')}>MAYBE</div>
					<div class="mock-label-skip" class:label-show={showLabel(0, 'skip')}>SKIP</div>
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

<style>
	.ql-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1.5rem;
		padding: 1.75rem 2rem;
		border-radius: 8px;
		text-decoration: none;
		transition: all 200ms;
		overflow: hidden;
		border: 1px solid;
	}
	.ql-swipe {
		background: linear-gradient(135deg, #e8f0eb 0%, #d4e4da 100%);
		border-color: #a8bfb0;
	}
	.ql-swipe:hover {
		border-color: #7a9e88;
		box-shadow: 0 8px 24px rgba(27, 58, 45, 0.12);
	}
	.ql-card:hover .ql-phone { transform: scale(1.03); }

	.ql-text {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		flex: 1;
		min-width: 0;
	}
	.ql-text strong {
		color: #1b3a2d;
		font-size: 1.25rem;
		font-family: 'Cormorant Garamond', Georgia, serif;
	}
	.ql-text span {
		color: #5a7264;
		font-size: 0.875rem;
		line-height: 1.7;
	}
	.ql-action {
		color: #2d5a47 !important;
		font-weight: 600;
		font-size: 0.9375rem !important;
		margin-top: 0.25rem;
	}

	/* Phone mockup */
	.ql-phone {
		flex-shrink: 0;
		transition: transform 200ms;
	}
	.phone-frame {
		width: 140px;
		height: 200px;
		background: white;
		border-radius: 16px;
		box-shadow: 0 8px 24px rgba(27, 58, 45, 0.12);
		padding: 8px;
		display: flex;
		flex-direction: column;
		overflow: hidden;
		border: 2px solid #ddd8ce;
	}
	.phone-header {
		display: flex;
		align-items: baseline;
		gap: 4px;
		padding: 4px 4px 6px;
	}
	.phone-tag {
		font-size: 9px;
		font-weight: 600;
		color: #1b3a2d;
	}
	.phone-tag-value {
		font-size: 9px;
		color: #c17c5a;
		border-bottom: 1px solid #dbb9a0;
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

	/* JS-driven swipe card positions */
	.sc-front { z-index: 3; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15); transition: transform 0.5s ease, opacity 0.4s ease; }
	.sc-behind-1 { transform: scale(0.95) translateY(4px); z-index: 2; transition: transform 0.3s ease; }
	.sc-behind-2 { transform: scale(0.9) translateY(8px); z-index: 1; transition: transform 0.3s ease; }
	.sc-behind-3 { transform: scale(0.85) translateY(12px); z-index: 0; transition: transform 0.3s ease; }
	.sc-swipe-right { transform: rotate(14deg) translateX(80px); opacity: 0; }
	.sc-swipe-left { transform: rotate(-14deg) translateX(-80px); opacity: 0; }
	.sc-gone { opacity: 0; z-index: -1; transition: none; }
	.label-show { opacity: 1 !important; }

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
		font-weight: 700;
		background: rgba(255, 255, 255, 0.9);
		padding: 1px 4px;
		border-radius: 3px;
		border: 1.5px solid;
		opacity: 0;
		transition: opacity 0.2s ease;
	}
	.mock-label-maybe {
		left: 4px;
		color: #2d5a47;
		border-color: #2d5a47;
		transform: rotate(-12deg);
	}
	.mock-label-skip {
		right: 4px;
		color: #c17c5a;
		border-color: #c17c5a;
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
		font-weight: 600;
		padding: 2px 8px;
		border-radius: 99px;
	}
	.mock-skip { background: #f5e6dc; color: #a05a3a; }
	.mock-view { background: #eee; color: #1b3a2d; }
	.mock-maybe { background: #d4e4da; color: #2d5a47; }

	@media (max-width: 400px) {
		.ql-phone {
			display: none;
		}
	}
</style>
