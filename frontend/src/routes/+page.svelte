<script lang="ts">
	import { isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	$effect(() => {
		if ($isAuthenticated) {
			goto('/home');
		}
	});
</script>

<div class="landing">
	<div class="hero">
		<p class="eyebrow">Self-hosted recipe management</p>
		<h1>Your recipes, your kitchen, your rules.</h1>
		<p class="description">
			Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No
			subscriptions, no ads, no data harvesting.
		</p>
		<div class="hero-actions">
			<a href="/login" class="cta">Get Started</a>
			<a href="https://github.com/deanmarano/controlcopypasta" class="cta-ghost">View on GitHub</a>
		</div>
	</div>

	<section class="how-it-works">
		<h2>How it works</h2>
		<div class="steps">
			<div class="step">
				<div class="step-number">1</div>
				<h3>Paste a URL</h3>
				<p>
					Find a recipe you love anywhere on the web. Paste the link and we'll extract
					everything — ingredients, instructions, images, and nutrition data.
				</p>
			</div>
			<div class="step">
				<div class="step-number">2</div>
				<h3>Organize your way</h3>
				<p>
					Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection
					that mirrors how you actually cook.
				</p>
			</div>
			<div class="step">
				<div class="step-number">3</div>
				<h3>Cook with confidence</h3>
				<p>
					Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists.
					Print clean recipe cards for the kitchen counter.
				</p>
			</div>
		</div>
	</section>

	<section class="feature-section">
		<h2 class="section-title">Tools for the home cook who takes food seriously</h2>
		<div class="features">
			<div class="feature">
				<h3>Clip from any site</h3>
				<p>
					Paste a URL or use the browser extension. We extract ingredients, steps, and images
					automatically.
				</p>
			</div>
			<div class="feature">
				<h3>Scale with confidence</h3>
				<p>
					Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction
					handling.
				</p>
			</div>
			<div class="feature">
				<h3>Know your nutrition</h3>
				<p>
					Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from
					verified sources.
				</p>
			</div>
			<div class="feature">
				<h3>Shop smarter</h3>
				<p>
					Generate shopping lists from any recipe. Items grouped by category, quantities
					combined.
				</p>
			</div>
			<div class="feature">
				<h3>Find connections</h3>
				<p>
					Discover which recipes share ingredients. Compare side by side. Browse by source.
				</p>
			</div>
			<div class="feature">
				<h3>Own your data</h3>
				<p>
					Self-host on your own server. Import from Copy Me That. Export anytime. AGPL
					licensed.
				</p>
			</div>
		</div>
	</section>

	<section class="stats-bar">
		<div class="stat">
			<span class="stat-number">200+</span>
			<span class="stat-label">Supported sites</span>
		</div>
		<div class="stat">
			<span class="stat-number">30s</span>
			<span class="stat-label">Average import time</span>
		</div>
		<div class="stat">
			<span class="stat-number">100%</span>
			<span class="stat-label">Open source</span>
		</div>
		<div class="stat">
			<span class="stat-number">0</span>
			<span class="stat-label">Tracking scripts</span>
		</div>
	</section>

	<section class="final-cta">
		<h2>Ready to take control of your recipe collection?</h2>
		<p class="cta-subtitle">Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
		<a href="/login" class="cta cta-inverted">Get Started</a>
	</section>
</div>

<style>
	.landing {
		text-align: center;
	}

	.hero {
		padding: var(--space-16) var(--space-4);
	}

	.eyebrow {
		text-transform: uppercase;
		letter-spacing: 0.15em;
		font-size: var(--text-xs);
		color: var(--color-marinara-500);
		margin: 0 0 var(--space-4);
		font-weight: var(--font-medium);
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-5xl);
		margin: 0 0 var(--space-4);
		color: var(--color-marinara-800);
		letter-spacing: var(--tracking-tight);
		line-height: var(--leading-tight);
	}

	.description {
		max-width: 600px;
		margin: 0 auto var(--space-8);
		font-size: var(--text-lg);
		line-height: var(--leading-relaxed);
		color: var(--text-secondary);
	}

	.hero-actions {
		display: flex;
		gap: var(--space-4);
		justify-content: center;
	}

	.cta {
		display: inline-block;
		padding: var(--space-4) var(--space-10);
		background: var(--color-marinara-600);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-size: var(--text-xl);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		box-shadow: var(--shadow-md);
	}

	.cta:hover {
		background: var(--color-marinara-700);
		box-shadow: var(--shadow-basil);
		transform: translateY(-2px);
	}

	.cta-ghost {
		display: inline-block;
		padding: var(--space-4) var(--space-10);
		background: none;
		color: var(--color-marinara-700);
		border: var(--border-width-default) solid var(--border-default);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-size: var(--text-xl);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.cta-ghost:hover {
		border-color: var(--color-marinara-600);
		color: var(--color-marinara-800);
	}

	/* How It Works */
	.how-it-works {
		max-width: 960px;
		margin: 0 auto;
		padding: var(--space-12) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.how-it-works h2 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		text-align: center;
		margin: 0 0 var(--space-10);
		color: var(--color-marinara-700);
	}

	.steps {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: var(--space-8);
	}

	.step {
		text-align: center;
	}

	.step-number {
		width: 48px;
		height: 48px;
		border-radius: 50%;
		border: 2px solid var(--color-marinara-700);
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
		margin-bottom: var(--space-4);
	}

	.step h3 {
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-700);
	}

	.step p {
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
		margin: 0;
		font-size: var(--text-base);
	}

	/* Features */
	.feature-section {
		padding: var(--space-12) var(--space-4);
	}

	.section-title {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		color: var(--color-marinara-700);
		margin: 0 0 var(--space-10);
	}

	.features {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: var(--space-8);
		max-width: 960px;
		margin: 0 auto;
		text-align: left;
	}

	.feature {
		padding: var(--space-6);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-md);
	}

	.feature h3 {
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-700);
	}

	.feature p {
		margin: 0;
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
	}

	/* Stats Bar */
	.stats-bar {
		display: flex;
		justify-content: center;
		gap: var(--space-12);
		padding: var(--space-8) var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-default);
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.stat {
		text-align: center;
	}

	.stat-number {
		display: block;
		font-family: var(--font-serif);
		font-size: var(--text-4xl);
		color: var(--color-marinara-700);
		font-weight: var(--font-semibold);
		line-height: 1;
		margin-bottom: var(--space-2);
	}

	.stat-label {
		font-size: var(--text-sm);
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: var(--text-muted);
	}

	/* Final CTA */
	.final-cta {
		padding: var(--space-12) var(--space-4) var(--space-16);
		background: var(--color-marinara-800);
		color: var(--color-white);
	}

	.final-cta h2 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		margin: 0 0 var(--space-3);
	}

	.cta-subtitle {
		color: rgba(255, 255, 255, 0.7);
		font-size: var(--text-base);
		margin: 0 0 var(--space-8);
	}

	.cta-inverted {
		background: var(--color-white);
		color: var(--color-marinara-800);
	}

	.cta-inverted:hover {
		background: var(--color-gray-200);
		color: var(--color-marinara-800);
	}

	/* Responsive */
	@media (max-width: 768px) {
		.steps {
			grid-template-columns: 1fr;
			gap: var(--space-8);
		}

		.features {
			grid-template-columns: 1fr;
		}

		.stats-bar {
			flex-wrap: wrap;
			gap: var(--space-8);
		}

		.hero-actions {
			flex-direction: column;
			align-items: center;
		}
	}
</style>
