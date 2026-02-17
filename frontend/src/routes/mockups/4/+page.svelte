<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 4: Editorial Botanical</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="eb">
	<header class="eb-hero">
		<div class="eb-hero-inner">
			<p class="eb-eyebrow">Self-hosted recipe management</p>
			<h1 class="eb-title">Your recipes,<br />your kitchen,<br />your rules.</h1>
			<p class="eb-subtitle">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="eb-hero-actions">
				<button class="eb-btn-primary">Get Started</button>
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
			{#each recipes.slice(0, 3) as recipe}
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
				<p>Self-host on your own server. Import from Copy Me That. Export anytime. AGPL licensed.</p>
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
		<button class="eb-btn-primary">Get Started</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="eb">
	<div class="eb-dash">
		<header class="eb-dash-header">
			<div class="eb-dash-greeting">
				<h1>Good evening.</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="eb-add-recipe">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="eb-btn-primary eb-btn-sm">Save</button>
			</div>
		</header>

		<section class="eb-section">
			<div class="eb-section-header">
				<h2>Tonight's inspiration</h2>
				<button class="eb-btn-text">Shuffle</button>
			</div>
			<div class="eb-hero-card">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} class="eb-hero-card-img" />
				<div class="eb-hero-card-overlay">
					<span class="eb-hero-card-tag">{dinnerIdeas[0].total_time_minutes} min</span>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="eb-card-row">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="eb-card">
						<div class="eb-card-img-wrap">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="eb-card-body">
							<h3>{recipe.title}</h3>
							<div class="eb-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="eb-section">
			<div class="eb-section-header">
				<h2>Recently added</h2>
				<a href="/recipes" class="eb-btn-text">View all</a>
			</div>
			<div class="eb-card-row">
				{#each recentlyAdded as recipe}
					<div class="eb-card">
						<div class="eb-card-img-wrap">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="eb-card-body">
							<h3>{recipe.title}</h3>
							<div class="eb-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>
	</div>
</div>

{:else}
<!-- RECIPE DETAIL -->
<div class="eb">
	<div class="eb-recipe">
		<div class="eb-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="eb-recipe-hero-overlay">
				<div class="eb-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="eb-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="eb-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="eb-recipe-content">
			<div class="eb-recipe-meta-bar">
				<div class="eb-meta-item">
					<span class="eb-meta-label">Prep</span>
					<span class="eb-meta-value">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="eb-meta-item">
					<span class="eb-meta-label">Cook</span>
					<span class="eb-meta-value">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="eb-meta-item">
					<span class="eb-meta-label">Total</span>
					<span class="eb-meta-value">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="eb-meta-item">
					<span class="eb-meta-label">Serves</span>
					<span class="eb-meta-value">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="eb-recipe-desc">{featuredRecipe.description}</p>

			<div class="eb-recipe-actions">
				<button class="eb-btn-primary eb-btn-sm">Add to Shopping List</button>
				<button class="eb-btn-outline eb-btn-sm">Print</button>
				<button class="eb-btn-outline eb-btn-sm">Edit</button>
				<div class="eb-scale">
					<button class="eb-scale-btn">-</button>
					<span>1x</span>
					<button class="eb-scale-btn">+</button>
				</div>
			</div>

			<div class="eb-recipe-body">
				<aside class="eb-ingredients">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>{ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="eb-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="eb-step-circle">{i + 1}</span>
								<p>{step.text}</p>
							</li>
						{/each}
					</ol>
				</div>
			</div>
		</div>
	</div>
</div>
{/if}

<style>
	/* === NAV === */
	.mockup-nav {
		position: sticky;
		top: 0;
		z-index: 100;
		display: flex;
		align-items: center;
		gap: var(--space-4);
		padding: var(--space-2) var(--space-4);
		background: #1a1a1a;
		color: white;
		font-size: var(--text-sm);
	}
	.mockup-nav .back {
		color: rgba(255, 255, 255, 0.6);
		text-decoration: none;
	}
	.mockup-nav .back:hover { color: white; }
	.mockup-nav .label { flex: 1; font-weight: var(--font-medium); }
	.mockup-nav .views { display: flex; gap: 2px; }
	.mockup-nav .views button {
		padding: var(--space-1) var(--space-3);
		background: rgba(255, 255, 255, 0.1);
		color: rgba(255, 255, 255, 0.7);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
	}
	.mockup-nav .views button.active {
		background: white;
		color: #1a1a1a;
	}

	/* === EDITORIAL BOTANICAL THEME === */
	@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400&display=swap');

	.eb {
		font-family: 'Inter', system-ui, sans-serif;
		color: #1b3a2d;
		background: #f7f5f0;
	}

	/* LANDING - HERO */
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
	}
	.eb-btn-primary:hover { background: #2d5a47; }
	.eb-btn-sm { padding: 0.5rem 1.25rem; font-size: 0.8125rem; }

	.eb-btn-ghost {
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

	.eb-btn-outline {
		padding: 0.5rem 1.25rem;
		background: none;
		color: #5a7264;
		border: 1.5px solid #c2d1c8;
		border-radius: 2px;
		font-size: 0.8125rem;
		cursor: pointer;
		transition: all 200ms;
	}
	.eb-btn-outline:hover { border-color: #1b3a2d; color: #1b3a2d; }

	.eb-btn-text {
		background: none;
		border: none;
		color: #c17c5a;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: none;
		font-weight: 500;
		letter-spacing: 0.02em;
	}
	.eb-btn-text:hover { color: #1b3a2d; }

	/* LANDING - HOW IT WORKS */
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

	/* LANDING - PREVIEW */
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

	/* LANDING - FEATURES */
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

	/* LANDING - STATS */
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

	/* LANDING - CTA */
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
	.eb-cta-section .eb-btn-primary {
		background: #f7f5f0;
		color: #1b3a2d;
	}
	.eb-cta-section .eb-btn-primary:hover {
		background: #ddd8ce;
	}

	/* DASHBOARD */
	.eb-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.eb-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #ddd8ce;
	}
	.eb-dash-greeting h1 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2.5rem;
		margin: 0;
		color: #1b3a2d;
		font-weight: 400;
	}
	.eb-dash-greeting p {
		margin: 0.25rem 0 0;
		color: #c17c5a;
		font-size: 1rem;
	}
	.eb-add-recipe {
		display: flex;
		gap: 0.5rem;
	}
	.eb-add-recipe input {
		padding: 0.5rem 1rem;
		border: 1.5px solid #c2d1c8;
		border-radius: 2px;
		font-size: 0.875rem;
		width: 320px;
		background: transparent;
		color: #1b3a2d;
	}
	.eb-add-recipe input::placeholder { color: #a8bfb0; }
	.eb-add-recipe input:focus { outline: none; border-color: #1b3a2d; }

	.eb-section { margin-bottom: 3rem; }
	.eb-section-header {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1.25rem;
	}
	.eb-section-header h2 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.5rem;
		margin: 0;
		color: #1b3a2d;
		font-weight: 400;
	}

	.eb-hero-card {
		position: relative;
		border-radius: 4px;
		overflow: hidden;
		margin-bottom: 1.25rem;
		aspect-ratio: 21/9;
	}
	.eb-hero-card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.eb-hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 2rem 2rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
		color: white;
	}
	.eb-hero-card-overlay h3 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 2rem;
		margin: 0 0 0.5rem;
		font-weight: 400;
	}
	.eb-hero-card-overlay p {
		margin: 0;
		font-size: 0.875rem;
		opacity: 0.85;
		max-width: 500px;
	}
	.eb-hero-card-tag {
		display: inline-block;
		padding: 0.25rem 0.625rem;
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: 2px;
		font-size: 0.75rem;
		margin-bottom: 0.75rem;
		font-weight: 500;
	}

	.eb-card-row {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1.25rem;
	}
	.eb-card {
		background: white;
		border-radius: 4px;
		overflow: hidden;
		transition: transform 200ms, box-shadow 200ms;
		cursor: pointer;
	}
	.eb-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 24px rgba(27, 58, 45, 0.1);
	}
	.eb-card-img-wrap {
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.eb-card-img-wrap img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.eb-card:hover .eb-card-img-wrap img {
		transform: scale(1.03);
	}
	.eb-card-body {
		padding: 1rem;
	}
	.eb-card-body h3 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.0625rem;
		margin: 0 0 0.5rem;
		color: #1b3a2d;
		font-weight: 500;
		line-height: 1.4;
	}
	.eb-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.75rem;
		color: #c17c5a;
	}

	/* RECIPE */
	.eb-recipe-hero {
		position: relative;
		height: 60vh;
		min-height: 400px;
		overflow: hidden;
	}
	.eb-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.eb-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 4rem 3rem 3rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
		color: white;
	}
	.eb-recipe-hero-overlay h1 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 3rem;
		margin: 0 0 0.5rem;
		font-weight: 400;
		line-height: 1.12;
	}
	.eb-recipe-source {
		font-size: 0.875rem;
		opacity: 0.7;
		margin: 0;
	}
	.eb-recipe-tags { display: flex; gap: 0.5rem; margin-bottom: 1rem; }
	.eb-tag {
		padding: 0.25rem 0.75rem;
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: 2px;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		font-weight: 500;
	}

	.eb-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2.5rem 1.5rem;
	}

	.eb-recipe-meta-bar {
		display: flex;
		gap: 2.5rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #ddd8ce;
		margin-bottom: 2rem;
	}
	.eb-meta-item { text-align: center; }
	.eb-meta-label {
		display: block;
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: #c17c5a;
		margin-bottom: 0.25rem;
	}
	.eb-meta-value {
		font-size: 1.125rem;
		color: #1b3a2d;
		font-weight: 500;
	}

	.eb-recipe-desc {
		font-size: 1.0625rem;
		line-height: 1.7;
		color: #5a7264;
		margin: 0 0 2rem;
	}

	.eb-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #ddd8ce;
	}
	.eb-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.875rem;
		color: #5a7264;
	}
	.eb-scale-btn {
		width: 28px;
		height: 28px;
		border: 1.5px solid #c2d1c8;
		border-radius: 2px;
		background: none;
		cursor: pointer;
		font-size: 1rem;
		color: #5a7264;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.eb-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 3rem;
	}
	.eb-ingredients h2,
	.eb-instructions h2 {
		font-family: 'Cormorant Garamond', Georgia, serif;
		font-size: 1.375rem;
		margin: 0 0 1.25rem;
		color: #1b3a2d;
		font-weight: 500;
	}
	.eb-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.eb-ingredients li {
		padding: 0.75rem 0;
		border-bottom: 1px solid #e3ded4;
		font-size: 0.9375rem;
		color: #3a5c4a;
		line-height: 1.5;
	}
	.eb-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
		counter-reset: none;
	}
	.eb-instructions li {
		display: flex;
		gap: 1.25rem;
		margin-bottom: 1.75rem;
		align-items: flex-start;
	}
	.eb-step-circle {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: 1.5px solid #c2d1c8;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.8125rem;
		color: #c17c5a;
		font-weight: 500;
		margin-top: 2px;
	}
	.eb-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.7;
		color: #3a5c4a;
	}
</style>
