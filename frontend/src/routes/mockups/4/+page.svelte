<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 4: Web 2.0</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="w2">
	<header class="w2-hero">
		<div class="w2-hero-inner">
			<div class="w2-logo-row">
				<h1>Control<span class="w2-logo-accent">Copy</span>Pasta</h1>
				<span class="w2-beta">BETA</span>
			</div>
			<p class="w2-tagline">The open source recipe manager that doesn't suck.</p>
			<p class="w2-hero-sub">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="w2-hero-btns">
				<button class="w2-btn-glossy">Sign Up Free &raquo;</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="w2-btn-white">View on GitHub</a>
			</div>
		</div>
		<div class="w2-hero-side">
			<div class="w2-screenshot">
				<div class="w2-screenshot-bar">
					<span class="w2-dot w2-dot-r"></span>
					<span class="w2-dot w2-dot-y"></span>
					<span class="w2-dot w2-dot-g"></span>
				</div>
				<img src={recipes[0].image_url} alt="Recipe screenshot" />
			</div>
		</div>
	</header>

	<section class="w2-how">
		<h2>How It Works</h2>
		<p class="w2-section-sub">Getting started is ridiculously easy.</p>
		<div class="w2-how-grid">
			<div class="w2-how-step">
				<div class="w2-how-icon">1</div>
				<h3>Paste a URL</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything — ingredients, instructions, images, and nutrition data.</p>
			</div>
			<div class="w2-how-step">
				<div class="w2-how-icon">2</div>
				<h3>Organize Your Way</h3>
				<p>Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection that mirrors how you actually cook.</p>
			</div>
			<div class="w2-how-step">
				<div class="w2-how-icon">3</div>
				<h3>Cook With Confidence</h3>
				<p>Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists. Print clean recipe cards for the kitchen counter.</p>
			</div>
		</div>
	</section>

	<section class="w2-showcase">
		<div class="w2-showcase-text">
			<h2>Your collection, beautifully organized.</h2>
			<p>Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs — any site with a recipe. The browser extension makes it one click.</p>
		</div>
		<div class="w2-showcase-cards">
			{#each recipes.slice(0, 3) as recipe}
				<div class="w2-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="w2-showcase-info">
						<span class="w2-showcase-source">{recipe.source_domain}</span>
						<h4>{recipe.title}</h4>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<section class="w2-features">
		<h2>Features</h2>
		<p class="w2-section-sub">Everything you need. Nothing you don't.</p>
		<div class="w2-feat-grid">
			<div class="w2-feat">
				<div class="w2-feat-icon">&#9889;</div>
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. We extract ingredients, steps, and images automatically.</p>
			</div>
			<div class="w2-feat">
				<div class="w2-feat-icon">&#9878;</div>
				<h3>Scale with confidence</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="w2-feat">
				<div class="w2-feat-icon">&#9776;</div>
				<h3>Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from verified sources.</p>
			</div>
			<div class="w2-feat">
				<div class="w2-feat-icon">&#10003;</div>
				<h3>Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="w2-feat">
				<div class="w2-feat-icon">&#128279;</div>
				<h3>Find connections</h3>
				<p>Discover which recipes share ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="w2-feat">
				<div class="w2-feat-icon">&#128274;</div>
				<h3>Own your data</h3>
				<p>Self-host on your own server. Import from Copy Me That. Export anytime. AGPL licensed.</p>
			</div>
		</div>
	</section>

	<section class="w2-stats">
		<div class="w2-stat">
			<span class="w2-stat-num">200+</span>
			<span class="w2-stat-lbl">Supported Sites</span>
		</div>
		<div class="w2-stat">
			<span class="w2-stat-num">30s</span>
			<span class="w2-stat-lbl">Average Import</span>
		</div>
		<div class="w2-stat">
			<span class="w2-stat-num">100%</span>
			<span class="w2-stat-lbl">Open Source</span>
		</div>
		<div class="w2-stat">
			<span class="w2-stat-num">0</span>
			<span class="w2-stat-lbl">Tracking Scripts</span>
		</div>
	</section>

	<section class="w2-cta">
		<h2>Ready to take control of your recipes?</h2>
		<p>Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
		<button class="w2-btn-glossy w2-btn-lg">Get Started Free &raquo;</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="w2">
	<div class="w2-dash">
		<header class="w2-dash-header">
			<div>
				<h1>Welcome back!</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="w2-add-form">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="w2-btn-glossy w2-btn-sm">Save</button>
			</div>
		</header>

		<section class="w2-section">
			<div class="w2-section-top">
				<h2>Tonight's Inspiration</h2>
				<button class="w2-text-link">Shuffle &raquo;</button>
			</div>
			<div class="w2-hero-card">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} />
				<div class="w2-hero-card-overlay">
					<span class="w2-time-pill">{dinnerIdeas[0].total_time_minutes} min</span>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="w2-card-grid">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="w2-card">
						<div class="w2-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="w2-card-body">
							<h3>{recipe.title}</h3>
							<div class="w2-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="w2-section">
			<div class="w2-section-top">
				<h2>Recently Added</h2>
				<a href="/recipes" class="w2-text-link">View all &raquo;</a>
			</div>
			<div class="w2-card-grid">
				{#each recentlyAdded as recipe}
					<div class="w2-card">
						<div class="w2-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="w2-card-body">
							<h3>{recipe.title}</h3>
							<div class="w2-card-meta">
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
<div class="w2">
	<div class="w2-recipe">
		<div class="w2-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="w2-recipe-hero-overlay">
				<div class="w2-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="w2-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="w2-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="w2-recipe-content">
			<div class="w2-recipe-meta">
				<div class="w2-meta-item">
					<span class="w2-meta-lbl">Prep</span>
					<span class="w2-meta-val">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="w2-meta-item">
					<span class="w2-meta-lbl">Cook</span>
					<span class="w2-meta-val">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="w2-meta-item">
					<span class="w2-meta-lbl">Total</span>
					<span class="w2-meta-val">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="w2-meta-item">
					<span class="w2-meta-lbl">Serves</span>
					<span class="w2-meta-val">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="w2-recipe-desc">{featuredRecipe.description}</p>

			<div class="w2-recipe-actions">
				<button class="w2-btn-glossy w2-btn-sm">Add to Shopping List</button>
				<button class="w2-btn-white w2-btn-sm">Print</button>
				<button class="w2-btn-white w2-btn-sm">Edit</button>
				<div class="w2-scale">
					<button class="w2-scale-btn">&minus;</button>
					<span>1x</span>
					<button class="w2-scale-btn">+</button>
				</div>
			</div>

			<div class="w2-recipe-body">
				<aside class="w2-ingredients">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>{ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="w2-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="w2-step-num">{i + 1}</span>
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
		background: linear-gradient(180deg, #4a90d9, #2a6ab8);
		color: white;
		font-size: var(--text-sm);
		border-bottom: 1px solid #1e5a9e;
		box-shadow: 0 1px 3px rgba(0,0,0,0.2);
	}
	.mockup-nav .back { color: rgba(255,255,255,0.7); text-decoration: none; }
	.mockup-nav .back:hover { color: white; text-decoration: underline; }
	.mockup-nav .label { flex: 1; font-weight: bold; text-shadow: 0 1px 1px rgba(0,0,0,0.3); }
	.mockup-nav .views { display: flex; gap: 2px; }
	.mockup-nav .views button {
		padding: var(--space-1) var(--space-3);
		background: rgba(255,255,255,0.15);
		color: rgba(255,255,255,0.85);
		border: 1px solid rgba(255,255,255,0.2);
		border-radius: 3px;
		cursor: pointer;
		font-size: var(--text-xs);
	}
	.mockup-nav .views button.active {
		background: white;
		color: #2a6ab8;
		font-weight: bold;
		border-color: #ccc;
	}

	/* === WEB 2.0 THEME === */
	.w2 {
		font-family: 'Lucida Grande', 'Segoe UI', 'Helvetica Neue', sans-serif;
		color: #333;
		background: #f0f4f8;
	}

	/* BUTTONS */
	.w2-btn-glossy {
		padding: 10px 24px;
		background: linear-gradient(180deg, #6db3f8 0%, #3b82d1 50%, #2a6ab8 51%, #1e5a9e 100%);
		color: white;
		border: 1px solid #1a5090;
		border-radius: 5px;
		font-size: 0.9375rem;
		font-weight: bold;
		cursor: pointer;
		text-shadow: 0 -1px 1px rgba(0,0,0,0.3);
		box-shadow: 0 1px 2px rgba(0,0,0,0.2), inset 0 1px 0 rgba(255,255,255,0.3);
		text-decoration: none;
		display: inline-block;
	}
	.w2-btn-glossy:hover {
		background: linear-gradient(180deg, #7ec0ff 0%, #4a90d9 50%, #3578c6 51%, #2568ac 100%);
	}
	.w2-btn-sm { padding: 6px 16px; font-size: 0.8125rem; }
	.w2-btn-lg { padding: 14px 36px; font-size: 1.0625rem; border-radius: 6px; }

	.w2-btn-white {
		padding: 10px 24px;
		background: linear-gradient(180deg, #fff 0%, #f0f0f0 50%, #e8e8e8 51%, #ddd 100%);
		color: #444;
		border: 1px solid #bbb;
		border-radius: 5px;
		font-size: 0.9375rem;
		font-weight: bold;
		cursor: pointer;
		box-shadow: 0 1px 2px rgba(0,0,0,0.1), inset 0 1px 0 rgba(255,255,255,0.8);
		text-decoration: none;
		display: inline-block;
	}
	.w2-btn-white:hover { background: linear-gradient(180deg, #fff, #f5f5f5 50%, #eee 51%, #e5e5e5 100%); }

	.w2-text-link {
		background: none;
		border: none;
		color: #2a6ab8;
		font-size: 0.875rem;
		font-weight: bold;
		cursor: pointer;
		text-decoration: none;
	}
	.w2-text-link:hover { text-decoration: underline; }

	/* LANDING - HERO */
	.w2-hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 3rem;
		max-width: 1100px;
		margin: 0 auto;
		padding: 4rem 3rem;
	}
	.w2-hero-inner {
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.w2-logo-row {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 0.5rem;
	}
	.w2-logo-row h1 {
		font-size: 2.5rem;
		color: #2a6ab8;
		margin: 0;
		font-weight: bold;
	}
	.w2-logo-accent { color: #ff6b35; }
	.w2-beta {
		padding: 2px 8px;
		background: linear-gradient(180deg, #ff9955, #ff6b35);
		color: white;
		border-radius: 3px;
		font-size: 0.5625rem;
		font-weight: bold;
		letter-spacing: 0.1em;
		text-shadow: 0 -1px 0 rgba(0,0,0,0.2);
		vertical-align: super;
	}
	.w2-tagline {
		font-size: 1.375rem;
		color: #555;
		margin: 0 0 1rem;
		font-weight: normal;
	}
	.w2-hero-sub {
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #777;
		margin: 0 0 2rem;
		max-width: 440px;
	}
	.w2-hero-btns { display: flex; gap: 0.75rem; }

	.w2-hero-side {
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.w2-screenshot {
		background: #e8e8e8;
		border-radius: 8px 8px 4px 4px;
		overflow: hidden;
		box-shadow: 0 4px 20px rgba(0,0,0,0.15), 0 0 0 1px rgba(0,0,0,0.08);
	}
	.w2-screenshot-bar {
		display: flex;
		gap: 6px;
		padding: 8px 12px;
		background: linear-gradient(180deg, #e8e8e8, #d0d0d0);
		border-bottom: 1px solid #bbb;
	}
	.w2-dot { width: 10px; height: 10px; border-radius: 50%; }
	.w2-dot-r { background: #ff5f57; }
	.w2-dot-y { background: #ffbd2e; }
	.w2-dot-g { background: #28ca42; }
	.w2-screenshot img {
		width: 100%;
		max-width: 420px;
		display: block;
	}

	/* HOW IT WORKS */
	.w2-how {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3.5rem 2rem;
		text-align: center;
	}
	.w2-how h2, .w2-features h2 {
		font-size: 1.75rem;
		color: #333;
		margin: 0 0 0.375rem;
	}
	.w2-section-sub {
		color: #888;
		font-size: 0.9375rem;
		margin: 0 0 2.5rem;
	}
	.w2-how-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2rem;
	}
	.w2-how-step {
		background: white;
		border-radius: 8px;
		padding: 2rem 1.5rem;
		box-shadow: 0 1px 4px rgba(0,0,0,0.08);
		border: 1px solid #e0e0e0;
		text-align: center;
	}
	.w2-how-icon {
		width: 44px;
		height: 44px;
		background: linear-gradient(180deg, #6db3f8, #2a6ab8);
		color: white;
		border-radius: 50%;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-size: 1.125rem;
		font-weight: bold;
		margin-bottom: 1rem;
		text-shadow: 0 -1px 1px rgba(0,0,0,0.2);
		box-shadow: 0 2px 4px rgba(42,106,184,0.3);
	}
	.w2-how-step h3 {
		font-size: 1.0625rem;
		margin: 0 0 0.5rem;
		color: #333;
	}
	.w2-how-step p {
		color: #777;
		line-height: 1.6;
		margin: 0;
		font-size: 0.875rem;
	}

	/* SHOWCASE */
	.w2-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 3rem 2rem;
		display: grid;
		grid-template-columns: 1fr 1.2fr;
		gap: 3rem;
		align-items: center;
	}
	.w2-showcase-text h2 {
		font-size: 1.75rem;
		line-height: 1.25;
		margin: 0 0 1rem;
		color: #333;
	}
	.w2-showcase-text p {
		color: #777;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}
	.w2-showcase-cards {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}
	.w2-showcase-card {
		display: flex;
		gap: 0.875rem;
		background: white;
		border-radius: 6px;
		overflow: hidden;
		border: 1px solid #ddd;
		box-shadow: 0 1px 3px rgba(0,0,0,0.06);
		transition: box-shadow 200ms;
		cursor: pointer;
	}
	.w2-showcase-card:hover {
		box-shadow: 0 3px 10px rgba(0,0,0,0.12);
	}
	.w2-showcase-card img {
		width: 110px;
		height: 75px;
		object-fit: cover;
		flex-shrink: 0;
	}
	.w2-showcase-info {
		padding: 0.625rem 0.875rem;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.w2-showcase-source {
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: #2a6ab8;
		font-weight: bold;
		margin-bottom: 0.25rem;
	}
	.w2-showcase-info h4 {
		font-size: 0.875rem;
		margin: 0;
		color: #333;
		line-height: 1.35;
	}

	/* FEATURES */
	.w2-features {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3.5rem 2rem;
		text-align: center;
	}
	.w2-feat-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.25rem;
		text-align: left;
	}
	.w2-feat {
		background: white;
		border-radius: 8px;
		padding: 1.5rem;
		border: 1px solid #e0e0e0;
		box-shadow: 0 1px 3px rgba(0,0,0,0.06);
		transition: box-shadow 200ms;
	}
	.w2-feat:hover { box-shadow: 0 3px 10px rgba(0,0,0,0.1); }
	.w2-feat-icon {
		width: 36px;
		height: 36px;
		background: linear-gradient(180deg, #6db3f8, #2a6ab8);
		border-radius: 8px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1rem;
		margin-bottom: 0.75rem;
		box-shadow: 0 1px 3px rgba(42,106,184,0.25);
	}
	.w2-feat h3 {
		font-size: 0.9375rem;
		margin: 0 0 0.375rem;
		color: #333;
	}
	.w2-feat p {
		color: #777;
		line-height: 1.55;
		margin: 0;
		font-size: 0.8125rem;
	}

	/* STATS */
	.w2-stats {
		display: flex;
		justify-content: center;
		gap: 2rem;
		padding: 2.5rem 2rem;
		background: linear-gradient(180deg, #4a90d9, #2a6ab8);
	}
	.w2-stat {
		text-align: center;
		padding: 1rem 2.5rem;
	}
	.w2-stat-num {
		display: block;
		font-size: 2.25rem;
		font-weight: bold;
		color: white;
		text-shadow: 0 1px 2px rgba(0,0,0,0.2);
		line-height: 1;
		margin-bottom: 0.375rem;
	}
	.w2-stat-lbl {
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: rgba(255,255,255,0.75);
	}

	/* CTA */
	.w2-cta {
		text-align: center;
		padding: 4rem 2rem;
		background: white;
		border-top: 1px solid #e0e0e0;
	}
	.w2-cta h2 {
		font-size: 1.75rem;
		color: #333;
		margin: 0 0 0.5rem;
	}
	.w2-cta p {
		color: #888;
		font-size: 0.9375rem;
		margin: 0 0 2rem;
	}

	/* DASHBOARD */
	.w2-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.w2-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 2rem;
		padding-bottom: 1.25rem;
		border-bottom: 2px solid #dde5ed;
	}
	.w2-dash-header h1 {
		font-size: 1.75rem;
		margin: 0;
		color: #333;
	}
	.w2-dash-header p {
		margin: 0.25rem 0 0;
		color: #888;
		font-size: 0.9375rem;
	}
	.w2-add-form { display: flex; gap: 4px; }
	.w2-add-form input {
		padding: 6px 12px;
		border: 1px solid #ccc;
		border-radius: 4px;
		font-size: 0.875rem;
		width: 300px;
		background: white;
		box-shadow: inset 0 1px 3px rgba(0,0,0,0.08);
	}
	.w2-add-form input:focus { outline: none; border-color: #4a90d9; box-shadow: inset 0 1px 3px rgba(0,0,0,0.08), 0 0 4px rgba(74,144,217,0.3); }

	.w2-section { margin-bottom: 2.5rem; }
	.w2-section-top {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1rem;
	}
	.w2-section-top h2 {
		font-size: 1.25rem;
		margin: 0;
		color: #333;
	}

	.w2-hero-card {
		position: relative;
		border-radius: 8px;
		overflow: hidden;
		margin-bottom: 1rem;
		aspect-ratio: 21/9;
		box-shadow: 0 2px 8px rgba(0,0,0,0.1);
	}
	.w2-hero-card img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.w2-hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 1.5rem 1.5rem;
		background: linear-gradient(transparent, rgba(0,0,0,0.75));
		color: white;
	}
	.w2-time-pill {
		display: inline-block;
		padding: 3px 10px;
		background: linear-gradient(180deg, #6db3f8, #2a6ab8);
		border-radius: 3px;
		font-size: 0.6875rem;
		font-weight: bold;
		margin-bottom: 0.5rem;
		text-shadow: 0 -1px 0 rgba(0,0,0,0.2);
	}
	.w2-hero-card-overlay h3 {
		font-size: 1.5rem;
		margin: 0 0 0.375rem;
		font-weight: bold;
	}
	.w2-hero-card-overlay p {
		margin: 0;
		font-size: 0.8125rem;
		opacity: 0.85;
		max-width: 480px;
	}

	.w2-card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1rem;
	}
	.w2-card {
		background: white;
		border-radius: 6px;
		overflow: hidden;
		border: 1px solid #ddd;
		box-shadow: 0 1px 3px rgba(0,0,0,0.06);
		cursor: pointer;
		transition: box-shadow 200ms, transform 200ms;
	}
	.w2-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(0,0,0,0.12);
	}
	.w2-card-img {
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.w2-card-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.w2-card:hover .w2-card-img img { transform: scale(1.03); }
	.w2-card-body { padding: 0.75rem 1rem; }
	.w2-card-body h3 {
		font-size: 0.875rem;
		margin: 0 0 0.25rem;
		color: #333;
		line-height: 1.35;
	}
	.w2-card-meta {
		display: flex;
		gap: 0.5rem;
		font-size: 0.6875rem;
		color: #2a6ab8;
	}

	/* RECIPE */
	.w2-recipe-hero {
		position: relative;
		height: 55vh;
		min-height: 380px;
		overflow: hidden;
	}
	.w2-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.w2-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 4rem 3rem 2.5rem;
		background: linear-gradient(transparent, rgba(42, 106, 184, 0.85));
		color: white;
	}
	.w2-recipe-tags { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; }
	.w2-tag {
		padding: 3px 10px;
		background: linear-gradient(180deg, #ff9955, #ff6b35);
		border-radius: 3px;
		font-size: 0.625rem;
		font-weight: bold;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		text-shadow: 0 -1px 0 rgba(0,0,0,0.15);
	}
	.w2-recipe-hero-overlay h1 {
		font-size: 2.25rem;
		margin: 0 0 0.5rem;
		font-weight: bold;
		line-height: 1.15;
		text-shadow: 0 1px 3px rgba(0,0,0,0.3);
	}
	.w2-recipe-source {
		font-size: 0.8125rem;
		opacity: 0.75;
		margin: 0;
	}

	.w2-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}

	.w2-recipe-meta {
		display: flex;
		gap: 1.25rem;
		padding: 1rem 1.25rem;
		background: white;
		border-radius: 8px;
		border: 1px solid #ddd;
		box-shadow: 0 1px 3px rgba(0,0,0,0.06);
		margin-bottom: 1.5rem;
	}
	.w2-meta-item { text-align: center; flex: 1; }
	.w2-meta-lbl {
		display: block;
		font-size: 0.5625rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #2a6ab8;
		font-weight: bold;
		margin-bottom: 0.25rem;
	}
	.w2-meta-val {
		font-size: 1rem;
		color: #333;
		font-weight: bold;
	}

	.w2-recipe-desc {
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #666;
		margin: 0 0 1.5rem;
	}

	.w2-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 2rem;
		padding-bottom: 1.5rem;
		border-bottom: 2px solid #dde5ed;
	}
	.w2-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 0.875rem;
		color: #555;
		font-weight: bold;
	}
	.w2-scale-btn {
		width: 28px;
		height: 28px;
		background: linear-gradient(180deg, #fff, #e8e8e8);
		border: 1px solid #bbb;
		border-radius: 4px;
		cursor: pointer;
		font-size: 1rem;
		color: #555;
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: 0 1px 2px rgba(0,0,0,0.08);
	}
	.w2-scale-btn:hover { border-color: #4a90d9; }

	.w2-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 2rem;
	}
	.w2-ingredients h2,
	.w2-instructions h2 {
		font-size: 1rem;
		margin: 0 0 1rem;
		color: #2a6ab8;
		font-weight: bold;
	}
	.w2-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.w2-ingredients li {
		padding: 0.5rem 0;
		border-bottom: 1px solid #eee;
		font-size: 0.875rem;
		color: #555;
		line-height: 1.5;
	}
	.w2-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.w2-instructions li {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
		align-items: flex-start;
	}
	.w2-step-num {
		flex-shrink: 0;
		width: 30px;
		height: 30px;
		border-radius: 50%;
		background: linear-gradient(180deg, #6db3f8, #2a6ab8);
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.75rem;
		font-weight: bold;
		text-shadow: 0 -1px 0 rgba(0,0,0,0.2);
		box-shadow: 0 1px 3px rgba(42,106,184,0.3);
		margin-top: 2px;
	}
	.w2-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #555;
	}
</style>
