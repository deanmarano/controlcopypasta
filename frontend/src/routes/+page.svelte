<script lang="ts">
	import { isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	$effect(() => {
		if ($isAuthenticated) {
			goto('/home');
		}
	});

	import { onDestroy } from 'svelte';

	const heroImage = 'https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/65b034087326da484e550fac_spaghetti-arrabiatta-thumbanil.webp';

	// Swipe card animation state
	let swipeActive = $state(0);
	let swipeState = $state<'idle' | 'showing' | 'label' | 'swiping'>('idle');
	let swipeTimers: ReturnType<typeof setTimeout>[] = [];

	function clearSwipeTimers() {
		swipeTimers.forEach(clearTimeout);
		swipeTimers = [];
	}

	function scheduleSwipe() {
		// Show card for 1.2s, then show label for 0.4s, then swipe for 0.5s, then next
		swipeTimers.push(setTimeout(() => {
			swipeState = 'label';
			swipeTimers.push(setTimeout(() => {
				swipeState = 'swiping';
				swipeTimers.push(setTimeout(() => {
					const next = swipeActive + 1;
					if (next >= 4) {
						// Reset: brief pause then restart
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
			return ['eb-sc-front', 'eb-sc-behind-1', 'eb-sc-behind-2', 'eb-sc-behind-3'][cardIndex];
		}

		if (cardIndex === swipeActive) {
			if (swipeState === 'swiping') {
				return cardIndex % 2 === 0 ? 'eb-sc-front eb-sc-swipe-right' : 'eb-sc-front eb-sc-swipe-left';
			}
			return 'eb-sc-front';
		}

		// Already swiped off
		if (cardIndex < swipeActive) return 'eb-sc-gone';

		// Behind the active card
		const behind = cardIndex - swipeActive;
		return ['', 'eb-sc-behind-1', 'eb-sc-behind-2', 'eb-sc-behind-3'][behind];
	}

	function showLabel(cardIndex: number, label: 'maybe' | 'skip'): boolean {
		if (cardIndex !== swipeActive || swipeState !== 'label') return false;
		// Even cards swipe right (maybe), odd cards swipe left (skip)
		return cardIndex % 2 === 0 ? label === 'maybe' : label === 'skip';
	}

	onDestroy(clearSwipeTimers);

	const recipes = [
		{
			title: 'One Pot Lemon Pasta',
			source_domain: 'sigsbeestreet.co',
			image_url:
				'https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6470dfae89487940cd3f2c85_one-pot-lemon-pasta-thumbnail.webp'
		},
		{
			title: 'Salmon Quinoa Salad',
			source_domain: 'sigsbeestreet.co',
			image_url:
				'https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/64b959a840c6917d162cf62b_salmon-quiona-salad-thumbnail.webp'
		},
		{
			title: 'Watermelon Basil Salad',
			source_domain: 'sigsbeestreet.co',
			image_url:
				'https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/649b7f9aaa7e9bd7c9662b4d_watermelon-basil-salad-thumbnail.webp'
		}
	];
</script>

<div class="eb">
	<header class="eb-hero">
		<div class="eb-hero-inner">
			<p class="eb-eyebrow">Recipe management, simplified</p>
			<h1 class="eb-title">Your recipes,<br />your kitchen,<br />your rules.</h1>
			<p class="eb-subtitle">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. Free to use, no ads.</p>
			<div class="eb-hero-actions">
				<a href="/login" class="eb-btn-primary">Get Started — It's Free</a>
			</div>
		</div>
		<div class="eb-hero-image">
			<img src={heroImage} alt="Spaghetti Arrabbiata" />
		</div>
	</header>


	<section class="eb-how-it-works">
		<h2>How it works</h2>
		<div class="eb-steps">
			<div class="eb-step">
				<div class="eb-step-number">1</div>
				<h3>Paste a URL</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything — ingredients, instructions, images, and nutrition data.</p>
			</div>
			<div class="eb-step">
				<div class="eb-step-number">2</div>
				<h3>Organize your way</h3>
				<p>Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection that mirrors how you actually cook.</p>
			</div>
			<div class="eb-step">
				<div class="eb-step-number">3</div>
				<h3>Cook with confidence</h3>
				<p>Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists. Print clean recipe cards for the kitchen counter.</p>
			</div>
		</div>
	</section>

	<section class="eb-preview">
		<div class="eb-preview-text">
			<p class="eb-eyebrow">Your collection, beautifully organized</p>
			<h2>Every recipe from every corner of the web, in one place.</h2>
			<p>Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs — any site with a recipe. The browser extension makes it one click.</p>
		</div>
		<div class="eb-preview-cards">
			{#each recipes as recipe}
				<div class="eb-preview-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="eb-preview-card-info">
						<span class="eb-preview-card-source">{recipe.source_domain}</span>
						<h4>{recipe.title}</h4>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<section class="eb-quicklist">
		<p class="eb-eyebrow" style="text-align: center; margin-bottom: 0.5rem;">Two ways to discover</p>
		<h2 class="eb-quicklist-title">Browse your collection like never before</h2>
		<div class="eb-quicklist-grid">
			<!-- svelte-ignore a11y_no_static_element_interactions -->
			<a href="/login" class="eb-ql-card eb-ql-swipe"
				onmouseenter={startSwipeAnimation}
				onmouseleave={stopSwipeAnimation}
			>
				<div class="eb-ql-text">
					<strong>Tinder Style</strong>
					<span>Swipe right to save, left to skip. Rapid-fire recipe discovery, one card at a time.</span>
					<span class="eb-ql-action">Try swiping &rarr;</span>
				</div>
				<div class="eb-ql-phone" aria-hidden="true">
					<div class="eb-phone-frame">
						<div class="eb-phone-header">
							<span class="eb-phone-tag">Find</span>
							<span class="eb-phone-tag-value">Dinner</span>
						</div>
						<div class="eb-phone-cards">
							<div class="eb-mock-card {getSwipeClass(3)}">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/649b7f9aaa7e9bd7c9662b4d_watermelon-basil-salad-thumbnail.webp" alt="" class="eb-mock-card-photo" />
								<div class="eb-mock-overlay">
									<div class="eb-mock-badge">15m</div>
									<div class="eb-mock-title-bar"></div>
									<div class="eb-mock-subtitle-bar"></div>
								</div>
								<div class="eb-mock-label-maybe" class:eb-label-show={showLabel(3, 'maybe')}>MAYBE</div>
								<div class="eb-mock-label-skip" class:eb-label-show={showLabel(3, 'skip')}>SKIP</div>
							</div>
							<div class="eb-mock-card {getSwipeClass(2)}">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6723a19fcc12a7d0178521d9_tomato-red-pepper-soup-thumbnail.webp" alt="" class="eb-mock-card-photo" />
								<div class="eb-mock-overlay">
									<div class="eb-mock-badge">45m</div>
									<div class="eb-mock-title-bar"></div>
									<div class="eb-mock-subtitle-bar"></div>
								</div>
								<div class="eb-mock-label-maybe" class:eb-label-show={showLabel(2, 'maybe')}>MAYBE</div>
								<div class="eb-mock-label-skip" class:eb-label-show={showLabel(2, 'skip')}>SKIP</div>
							</div>
							<div class="eb-mock-card {getSwipeClass(1)}">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/668c7c1038f9ea42fc3eff27_spinach-feta-grilled-cheese-thumbnail.webp" alt="" class="eb-mock-card-photo" />
								<div class="eb-mock-overlay">
									<div class="eb-mock-badge">20m</div>
									<div class="eb-mock-title-bar"></div>
									<div class="eb-mock-subtitle-bar"></div>
								</div>
								<div class="eb-mock-label-maybe" class:eb-label-show={showLabel(1, 'maybe')}>MAYBE</div>
								<div class="eb-mock-label-skip" class:eb-label-show={showLabel(1, 'skip')}>SKIP</div>
							</div>
							<div class="eb-mock-card {getSwipeClass(0)}">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6585b42a484dac29edc39a97_jalapeno-pimento-cheese-thumbnail.webp" alt="" class="eb-mock-card-photo" />
								<div class="eb-mock-overlay">
									<div class="eb-mock-badge">30m</div>
									<div class="eb-mock-title-bar"></div>
									<div class="eb-mock-subtitle-bar"></div>
								</div>
								<div class="eb-mock-label-maybe" class:eb-label-show={showLabel(0, 'maybe')}>MAYBE</div>
								<div class="eb-mock-label-skip" class:eb-label-show={showLabel(0, 'skip')}>SKIP</div>
							</div>
						</div>
						<div class="eb-phone-buttons">
							<div class="eb-mock-btn eb-mock-skip">Skip</div>
							<div class="eb-mock-btn eb-mock-view">View</div>
							<div class="eb-mock-btn eb-mock-maybe">Maybe</div>
						</div>
					</div>
				</div>
			</a>

			<a href="/login" class="eb-ql-card eb-ql-feed">
				<div class="eb-ql-text">
					<strong>Instagram Style</strong>
					<span>Scroll a full-screen feed. Double-tap to save, just like your favorite app.</span>
					<span class="eb-ql-action">Try scrolling &rarr;</span>
				</div>
				<div class="eb-ql-phone" aria-hidden="true">
					<div class="eb-phone-frame eb-phone-frame-dark">
						<div class="eb-feed-mock-scroll">
							<div class="eb-feed-mock-slide">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/64b959a840c6917d162cf62b_salmon-quiona-salad-thumbnail.webp" alt="" class="eb-feed-mock-photo" />
								<div class="eb-feed-mock-overlay">
									<div class="eb-feed-mock-source">
										<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="eb-feed-mock-fav" />
										<span class="eb-feed-mock-domain">sigsbeestreet.co</span>
									</div>
									<div class="eb-feed-mock-name">Salmon Quinoa Salad</div>
								</div>
								<div class="eb-feed-mock-rail">
									<svg class="eb-feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
									<div class="eb-feed-rail-dot"></div>
									<div class="eb-feed-rail-dot"></div>
								</div>
							</div>
							<div class="eb-feed-mock-slide">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6470dfae89487940cd3f2c85_one-pot-lemon-pasta-thumbnail.webp" alt="" class="eb-feed-mock-photo" />
								<div class="eb-feed-mock-overlay">
									<div class="eb-feed-mock-source">
										<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="eb-feed-mock-fav" />
										<span class="eb-feed-mock-domain">sigsbeestreet.co</span>
									</div>
									<div class="eb-feed-mock-name">One Pot Lemon Pasta</div>
								</div>
								<div class="eb-feed-mock-rail">
									<svg class="eb-feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
									<div class="eb-feed-rail-dot"></div>
									<div class="eb-feed-rail-dot"></div>
								</div>
							</div>
							<div class="eb-feed-mock-slide">
								<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/63ac55080a308b862e48c9b2_639a44e8692ea801789551cd_quinoa-pesto-bowl-thumbnail.webp" alt="" class="eb-feed-mock-photo" />
								<div class="eb-feed-mock-overlay">
									<div class="eb-feed-mock-source">
										<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="eb-feed-mock-fav" />
										<span class="eb-feed-mock-domain">sigsbeestreet.co</span>
									</div>
									<div class="eb-feed-mock-name">Quinoa Pesto Bowl</div>
								</div>
								<div class="eb-feed-mock-rail">
									<svg class="eb-feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
									<div class="eb-feed-rail-dot"></div>
									<div class="eb-feed-rail-dot"></div>
								</div>
							</div>
						</div>
						<div class="eb-feed-mock-heart-burst">
							<svg width="32" height="32" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
								<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
							</svg>
						</div>
					</div>
				</div>
			</a>
		</div>
	</section>

	<section class="eb-features">
		<p class="eb-eyebrow" style="text-align: center; margin-bottom: 0.5rem;">What you get</p>
		<h2 class="eb-features-title">Tools for the home cook who takes food seriously</h2>
		<div class="eb-feature-grid">
			<div class="eb-feature">
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. We extract ingredients, steps, and images automatically.</p>
			</div>
			<div class="eb-feature">
				<h3>Scale with confidence</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="eb-feature">
				<h3>Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from verified sources.</p>
			</div>
			<div class="eb-feature">
				<h3>Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="eb-feature">
				<h3>Find connections</h3>
				<p>Discover which recipes share ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="eb-feature">
				<h3>Always free</h3>
				<p>No subscriptions, no paywalls, no data harvesting. Your recipes are yours — export anytime.</p>
			</div>
		</div>
	</section>

	<section class="eb-stats-bar">
		<div class="eb-stat">
			<span class="eb-stat-number">200+</span>
			<span class="eb-stat-label">Supported sites</span>
		</div>
		<div class="eb-stat">
			<span class="eb-stat-number">30s</span>
			<span class="eb-stat-label">Average import time</span>
		</div>
		<div class="eb-stat">
			<span class="eb-stat-number">Free</span>
			<span class="eb-stat-label">No subscriptions</span>
		</div>
		<div class="eb-stat">
			<span class="eb-stat-number">0</span>
			<span class="eb-stat-label">Ads</span>
		</div>
	</section>

	<section class="eb-cta-section">
		<h2>Ready to take control of your recipe collection?</h2>
		<p class="eb-cta-sub">Sign up in seconds. Start saving recipes immediately.</p>
		<a href="/login" class="eb-btn-primary eb-btn-inverted">Get Started — It's Free</a>
	</section>
</div>

<style>
	@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&display=swap');

	.eb {
		font-family: 'Inter', system-ui, sans-serif;
		color: #1b3a2d;
		background: #f7f5f0;
	}

	/* HERO */
	.eb-hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		min-height: 80vh;
		overflow: hidden;
	}
	.eb-hero-inner {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 4rem 3rem 4rem 6rem;
	}
	.eb-hero-image {
		position: relative;
		overflow: hidden;
	}
	.eb-hero-image img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.eb-eyebrow {
		text-transform: uppercase;
		letter-spacing: 0.15em;
		font-size: 0.75rem;
		color: #c17c5a;
		margin: 0 0 1.5rem;
		font-weight: 500;
	}
	.eb-title {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 3.75rem;
		line-height: 1.08;
		margin: 0 0 1.5rem;
		color: #1b3a2d;
		font-weight: 600;
	}
	.eb-subtitle {
		font-size: 1.125rem;
		line-height: 1.7;
		color: #5a7264;
		margin: 0 0 2.5rem;
		max-width: 520px;
	}
	.eb-hero-actions { display: flex; gap: 1rem; }

	/* BUTTONS */
	.eb-btn-primary {
		display: inline-block;
		padding: 0.875rem 2rem;
		background: #1b3a2d;
		color: #f7f5f0;
		border: none;
		border-radius: 2px;
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
		letter-spacing: 0.02em;
		transition: background 200ms;
		text-decoration: none;
	}
	.eb-btn-primary:hover { background: #2d5a47; }

	.eb-btn-ghost {
		display: inline-block;
		padding: 0.875rem 2rem;
		background: none;
		color: #1b3a2d;
		border: 1.5px solid #a8bfb0;
		border-radius: 2px;
		font-size: 0.9375rem;
		font-weight: 500;
		text-decoration: none;
		transition: all 200ms;
	}
	.eb-btn-ghost:hover { border-color: #1b3a2d; }

	/* HOW IT WORKS */
	.eb-how-it-works {
		max-width: 1100px;
		margin: 0 auto;
		padding: 5rem 3rem;
		border-bottom: 1px solid #ddd8ce;
	}
	.eb-how-it-works h2 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.25rem;
		text-align: center;
		margin: 0 0 3rem;
		color: #1b3a2d;
		font-weight: 400;
	}
	.eb-steps {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 3rem;
	}
	.eb-step { text-align: center; }
	.eb-step-number {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		border: 2px solid #1b3a2d;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.25rem;
		color: #1b3a2d;
		margin-bottom: 1.25rem;
	}
	.eb-step h3 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.375rem;
		margin: 0 0 0.75rem;
		color: #1b3a2d;
		font-weight: 500;
	}
	.eb-step p {
		color: #5a7264;
		line-height: 1.7;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* PREVIEW */
	.eb-preview {
		max-width: 1100px;
		margin: 0 auto;
		padding: 5rem 3rem;
		display: grid;
		grid-template-columns: 1fr 1.2fr;
		gap: 4rem;
		align-items: center;
	}
	.eb-preview-text h2 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.25rem;
		line-height: 1.2;
		margin: 0 0 1.25rem;
		color: #1b3a2d;
		font-weight: 400;
	}
	.eb-preview-text p {
		color: #5a7264;
		line-height: 1.7;
		margin: 0;
		font-size: 0.9375rem;
	}
	.eb-preview-cards {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}
	.eb-preview-card {
		display: flex;
		gap: 1rem;
		background: white;
		border-radius: 4px;
		overflow: hidden;
		box-shadow: 0 2px 8px rgba(27, 58, 45, 0.06);
		transition: transform 200ms, box-shadow 200ms;
	}
	.eb-preview-card:hover {
		transform: translateX(4px);
		box-shadow: 0 4px 16px rgba(27, 58, 45, 0.1);
	}
	.eb-preview-card img {
		width: 120px;
		height: 80px;
		object-fit: cover;
		flex-shrink: 0;
	}
	.eb-preview-card-info {
		padding: 0.75rem 1rem 0.75rem 0;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.eb-preview-card-source {
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #c17c5a;
		margin-bottom: 0.25rem;
	}
	.eb-preview-card-info h4 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1rem;
		margin: 0;
		color: #1b3a2d;
		font-weight: 500;
		line-height: 1.35;
	}

	/* QUICKLIST */
	.eb-quicklist {
		max-width: 1100px;
		margin: 0 auto;
		padding: 5rem 3rem;
		border-top: 1px solid #ddd8ce;
	}
	.eb-quicklist-title {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.25rem;
		text-align: center;
		margin: 0 0 3rem;
		color: #1b3a2d;
		font-weight: 400;
	}
	.eb-quicklist-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2rem;
	}
	.eb-ql-card {
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
	.eb-ql-swipe {
		background: linear-gradient(135deg, #e8f0eb 0%, #d4e4da 100%);
		border-color: #a8bfb0;
	}
	.eb-ql-swipe:hover {
		border-color: #7a9e88;
		box-shadow: 0 8px 24px rgba(27, 58, 45, 0.12);
	}
	.eb-ql-feed {
		background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
		border-color: #2a2a4a;
	}
	.eb-ql-feed:hover {
		border-color: #4a4a6a;
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
	}
	.eb-ql-feed .eb-ql-text strong { color: #fff; }
	.eb-ql-feed .eb-ql-text span { color: rgba(255, 255, 255, 0.6); }
	.eb-ql-feed .eb-ql-action { color: #ff3040 !important; }

	.eb-ql-card:hover .eb-ql-phone { transform: scale(1.03); }

	.eb-ql-text {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		flex: 1;
		min-width: 0;
	}
	.eb-ql-text strong {
		color: #1b3a2d;
		font-size: 1.25rem;
		font-family: 'Cormorant Garamond', Georgia, serif;
	}
	.eb-ql-text span {
		color: #5a7264;
		font-size: 0.875rem;
		line-height: 1.7;
	}
	.eb-ql-action {
		color: #2d5a47 !important;
		font-weight: 600;
		font-size: 0.9375rem !important;
		margin-top: 0.25rem;
	}

	/* Phone mockup */
	.eb-ql-phone {
		flex-shrink: 0;
		transition: transform 200ms;
	}
	.eb-phone-frame {
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
	.eb-phone-header {
		display: flex;
		align-items: baseline;
		gap: 4px;
		padding: 4px 4px 6px;
	}
	.eb-phone-tag {
		font-size: 9px;
		font-weight: 600;
		color: #1b3a2d;
	}
	.eb-phone-tag-value {
		font-size: 9px;
		color: #c17c5a;
		border-bottom: 1px solid #dbb9a0;
	}
	.eb-phone-cards {
		position: relative;
		flex: 1;
		margin: 0 2px;
	}
	.eb-mock-card {
		position: absolute;
		inset: 0;
		border-radius: 8px;
		overflow: hidden;
	}
	/* JS-driven swipe card positions */
	.eb-sc-front { z-index: 3; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15); transition: transform 0.5s ease, opacity 0.4s ease; }
	.eb-sc-behind-1 { transform: scale(0.95) translateY(4px); z-index: 2; transition: transform 0.3s ease; }
	.eb-sc-behind-2 { transform: scale(0.9) translateY(8px); z-index: 1; transition: transform 0.3s ease; }
	.eb-sc-behind-3 { transform: scale(0.85) translateY(12px); z-index: 0; transition: transform 0.3s ease; }
	.eb-sc-swipe-right { transform: rotate(14deg) translateX(80px); opacity: 0; }
	.eb-sc-swipe-left { transform: rotate(-14deg) translateX(-80px); opacity: 0; }
	.eb-sc-gone { opacity: 0; z-index: -1; transition: none; }
	.eb-label-show { opacity: 1 !important; }
	.eb-mock-card-photo {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}
	.eb-mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 16px 6px 6px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
	}
	.eb-mock-badge {
		display: inline-block;
		font-size: 6px;
		color: white;
		background: rgba(255, 255, 255, 0.25);
		padding: 1px 4px;
		border-radius: 3px;
		margin-bottom: 3px;
	}
	.eb-mock-title-bar {
		height: 6px;
		width: 75%;
		background: rgba(255, 255, 255, 0.9);
		border-radius: 3px;
		margin-bottom: 3px;
	}
	.eb-mock-subtitle-bar {
		height: 4px;
		width: 50%;
		background: rgba(255, 255, 255, 0.5);
		border-radius: 2px;
	}
	.eb-mock-label-maybe,
	.eb-mock-label-skip {
		position: absolute;
		top: 8px;
		font-size: 7px;
		font-weight: 700;
		background: rgba(255, 255, 255, 0.9);
		padding: 1px 4px;
		border-radius: 3px;
		border: 1.5px solid;
		opacity: 0;
	}
	.eb-mock-label-maybe {
		left: 4px;
		color: #2d5a47;
		border-color: #2d5a47;
		transform: rotate(-12deg);
	}
	.eb-mock-label-skip {
		right: 4px;
		color: #c17c5a;
		border-color: #c17c5a;
		transform: rotate(12deg);
	}
	.eb-phone-buttons {
		display: flex;
		justify-content: center;
		gap: 4px;
		padding: 6px 2px 4px;
	}
	.eb-mock-btn {
		font-size: 6px;
		font-weight: 600;
		padding: 2px 8px;
		border-radius: 99px;
	}
	.eb-mock-skip { background: #f5e6dc; color: #a05a3a; }
	.eb-mock-view { background: #eee; color: #1b3a2d; }
	.eb-mock-maybe { background: #d4e4da; color: #2d5a47; }

	/* Swipe label transitions */
	.eb-mock-label-maybe,
	.eb-mock-label-skip {
		transition: opacity 0.2s ease;
	}

	/* Feed phone mockup */
	.eb-phone-frame-dark {
		background: #000 !important;
		border-color: #333 !important;
		padding: 0 !important;
		position: relative;
		overflow: hidden;
	}
	.eb-feed-mock-scroll { animation: none; }
	.eb-ql-feed:hover .eb-feed-mock-scroll { animation: ebFeedScroll 6s ease-in-out infinite; }
	@keyframes ebFeedScroll {
		0%, 20% { transform: translateY(0); }
		33%, 53% { transform: translateY(-33.333%); }
		66%, 86% { transform: translateY(-66.666%); }
		100% { transform: translateY(0); }
	}
	.eb-feed-mock-slide {
		width: 100%;
		aspect-ratio: 140 / 200;
		position: relative;
		overflow: hidden;
	}
	.eb-feed-mock-photo {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}
	.eb-feed-mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 24px 6px 8px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
	}
	.eb-feed-mock-source {
		display: flex;
		align-items: center;
		gap: 3px;
		margin-bottom: 2px;
	}
	.eb-feed-mock-fav {
		width: 8px;
		height: 8px;
		border-radius: 1px;
	}
	.eb-feed-mock-domain {
		font-size: 5px;
		color: rgba(255, 255, 255, 0.6);
		font-weight: 600;
	}
	.eb-feed-mock-name {
		font-size: 7px;
		font-weight: 700;
		color: white;
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	}
	.eb-feed-mock-rail {
		position: absolute;
		right: 5px;
		bottom: 8px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		z-index: 3;
	}
	.eb-feed-rail-heart {
		filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.4));
	}
	.eb-feed-rail-dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		border: 1.5px solid rgba(255, 255, 255, 0.7);
	}
	.eb-feed-mock-heart-burst {
		position: absolute;
		top: 50%;
		left: 45%;
		transform: translate(-50%, -50%) scale(0);
		z-index: 5;
		opacity: 0;
		pointer-events: none;
	}
	.eb-ql-feed:hover .eb-feed-mock-heart-burst { animation: ebMockHeartSync 6s ease-in-out infinite; }
	@keyframes ebMockHeartSync {
		0%, 10% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		12% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		14% { transform: translate(-50%, -50%) scale(0.9); }
		16% { transform: translate(-50%, -50%) scale(1.05); }
		20% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		33%, 64% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		76% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		78% { transform: translate(-50%, -50%) scale(0.9); }
		80% { transform: translate(-50%, -50%) scale(1.05); }
		84% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		85%, 100% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
	}

	/* FEATURES */
	.eb-features {
		padding: 5rem 3rem;
		max-width: 1100px;
		margin: 0 auto;
	}
	.eb-features-title {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.25rem;
		text-align: center;
		margin: 0 0 3rem;
		color: #1b3a2d;
		font-weight: 400;
	}
	.eb-feature-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2.5rem;
	}
	.eb-feature h3 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.375rem;
		margin: 0 0 0.75rem;
		color: #1b3a2d;
		font-weight: 500;
	}
	.eb-feature p {
		color: #5a7264;
		line-height: 1.7;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* STATS */
	.eb-stats-bar {
		display: flex;
		justify-content: center;
		gap: 4rem;
		padding: 3rem 2rem;
		border-top: 1px solid #ddd8ce;
		border-bottom: 1px solid #ddd8ce;
	}
	.eb-stat { text-align: center; }
	.eb-stat-number {
		display: block;
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.75rem;
		color: #1b3a2d;
		font-weight: 600;
		line-height: 1;
		margin-bottom: 0.5rem;
	}
	.eb-stat-label {
		font-size: 0.8125rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #c17c5a;
	}

	/* CTA */
	.eb-cta-section {
		text-align: center;
		padding: 5rem 2rem;
		background: #1b3a2d;
		color: #f7f5f0;
	}
	.eb-cta-section h2 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.25rem;
		margin: 0 0 1rem;
		font-weight: 400;
	}
	.eb-cta-sub {
		color: rgba(247, 245, 240, 0.7);
		font-size: 1rem;
		margin: 0 0 2rem;
	}
	.eb-btn-inverted {
		background: #f7f5f0;
		color: #1b3a2d;
	}
	.eb-btn-inverted:hover {
		background: #ddd8ce;
	}

	/* RESPONSIVE */
	@media (max-width: 768px) {
		.eb-hero {
			grid-template-columns: 1fr;
			min-height: auto;
		}
		.eb-hero-inner {
			padding: 3rem 1.5rem;
		}
		.eb-title {
			font-size: 2.5rem;
		}
		.eb-hero-image {
			height: 300px;
		}
		.eb-hero-actions {
			flex-direction: column;
			align-items: flex-start;
		}
		.eb-how-it-works {
			padding: 3rem 1.5rem;
		}
		.eb-steps {
			grid-template-columns: 1fr;
			gap: 2rem;
		}
		.eb-preview {
			grid-template-columns: 1fr;
			padding: 3rem 1.5rem;
			gap: 2rem;
		}
		.eb-features {
			padding: 3rem 1.5rem;
		}
		.eb-quicklist-grid {
			grid-template-columns: 1fr;
		}
		.eb-feature-grid {
			grid-template-columns: 1fr;
			gap: 1.5rem;
		}
		.eb-stats-bar {
			flex-wrap: wrap;
			gap: 2rem;
		}
	}

	@media (max-width: 400px) {
		.eb-ql-phone {
			display: none;
		}
	}
</style>
