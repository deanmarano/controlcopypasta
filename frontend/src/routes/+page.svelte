<script lang="ts">
	import { isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	$effect(() => {
		if ($isAuthenticated) {
			goto('/home');
		}
	});

	const recipes = [
		{
			title: 'Simple Spaghetti Carbonara, Step-by-Step',
			source_domain: 'bonappetit.com',
			image_url:
				'https://assets.bonappetit.com/photos/6917aa378ac0eb7fbdadae2a/16:9/w_4351,h_2447,c_limit/simple-carbonara_RECIPE_V1_111125_13849_VOG_final.jpg'
		},
		{
			title: 'Ruffled Mushroom Pot Pie',
			source_domain: 'bonappetit.com',
			image_url:
				'https://assets.bonappetit.com/photos/6765f1bd9ae953633b06a3d0/16:9/w_4845,h_2726,c_limit/ruffled-mushroom-pot-pie_LEDE_V2_110624_7344_VOG_final.jpg'
		},
		{
			title: 'Herby Cauliflower Fritters',
			source_domain: 'bonappetit.com',
			image_url:
				'https://assets.bonappetit.com/photos/65bbdfe22c3c1e1bdd2c7f07/16:9/w_6176,h_3474,c_limit/20231207-0324-DIS-7172.jpg'
		}
	];
</script>

<div class="eb">
	<header class="eb-hero">
		<div class="eb-hero-inner">
			<p class="eb-eyebrow">Self-hosted recipe management</p>
			<h1 class="eb-title">Your recipes,<br />your kitchen,<br />your rules.</h1>
			<p class="eb-subtitle">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="eb-hero-actions">
				<a href="/login" class="eb-btn-primary">Get Started</a>
				<a href="https://github.com/deanmarano/controlcopypasta" class="eb-btn-ghost">View on GitHub</a>
			</div>
		</div>
		<div class="eb-hero-image">
			<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
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
				<h3>Own your data</h3>
				<p>Self-host on your own server. Export anytime. No vendor lock-in. AGPL licensed.</p>
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
			<span class="eb-stat-number">100%</span>
			<span class="eb-stat-label">Open source</span>
		</div>
		<div class="eb-stat">
			<span class="eb-stat-number">0</span>
			<span class="eb-stat-label">Tracking scripts</span>
		</div>
	</section>

	<section class="eb-cta-section">
		<h2>Ready to take control of your recipe collection?</h2>
		<p class="eb-cta-sub">Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
		<a href="/login" class="eb-btn-primary eb-btn-inverted">Get Started</a>
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
		max-width: 420px;
	}
	.eb-hero-actions { display: flex; gap: 1rem; }
	.eb-hero-image { position: relative; overflow: hidden; }
	.eb-hero-image img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

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
		.eb-feature-grid {
			grid-template-columns: 1fr;
			gap: 1.5rem;
		}
		.eb-stats-bar {
			flex-wrap: wrap;
			gap: 2rem;
		}
	}
</style>
