<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 4: 90s Website</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="nn">
	<header class="nn-hero">
		<div class="nn-hero-inner">
			<div class="nn-marquee">*** Welcome to ControlCopyPasta! *** Your #1 Recipe Manager on the World Wide Web! ***</div>
			<h1>ControlCopy<span class="nn-accent">Pasta</span></h1>
			<p class="nn-hero-sub">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="nn-hero-btns">
				<button class="nn-btn">&#9658; Get Started</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="nn-btn nn-btn-alt">&#128279; View Source Code</a>
			</div>
			<div class="nn-badges">
				<span class="nn-badge-item">OPEN SOURCE</span>
				<span class="nn-badge-item">SELF-HOSTED</span>
				<span class="nn-badge-item">NO TRACKING</span>
			</div>
		</div>
		<div class="nn-hero-side">
			<div class="nn-hero-img-frame">
				<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
			</div>
			<p class="nn-img-caption">~ Featured Recipe of the Day ~</p>
		</div>
	</header>

	<div class="nn-separator">
		<hr />
	</div>

	<section class="nn-how">
		<h2>// How It Works //</h2>
		<div class="nn-how-grid">
			<div class="nn-how-step">
				<div class="nn-how-num">Step 1</div>
				<h3>Paste a URL</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything &mdash; ingredients, instructions, images, and nutrition data.</p>
			</div>
			<div class="nn-how-step">
				<div class="nn-how-num">Step 2</div>
				<h3>Organize Your Way</h3>
				<p>Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection that mirrors how you actually cook.</p>
			</div>
			<div class="nn-how-step">
				<div class="nn-how-num">Step 3</div>
				<h3>Cook With Confidence</h3>
				<p>Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists. Print clean recipe cards for the kitchen counter.</p>
			</div>
		</div>
	</section>

	<div class="nn-separator">
		<hr />
	</div>

	<section class="nn-showcase">
		<div class="nn-showcase-text">
			<h2>// Recipe Collection //</h2>
			<p>Every recipe from every corner of the web, in one place. Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs &mdash; any site with a recipe. The browser extension makes it one click.</p>
		</div>
		<div class="nn-showcase-cards">
			{#each recipes.slice(0, 3) as recipe}
				<div class="nn-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="nn-showcase-info">
						<span class="nn-showcase-source">[{recipe.source_domain}]</span>
						<h4>{recipe.title}</h4>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<div class="nn-separator">
		<hr />
	</div>

	<section class="nn-features">
		<h2>// Features //</h2>
		<div class="nn-feat-grid">
			<div class="nn-feat">
				<h3>&#9658; Clip from any site</h3>
				<p>Paste a URL or use the browser extension. We extract ingredients, steps, and images automatically.</p>
			</div>
			<div class="nn-feat">
				<h3>&#9658; Scale with confidence</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="nn-feat">
				<h3>&#9658; Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from verified sources.</p>
			</div>
			<div class="nn-feat">
				<h3>&#9658; Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="nn-feat">
				<h3>&#9658; Find connections</h3>
				<p>Discover which recipes share ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="nn-feat">
				<h3>&#9658; Own your data</h3>
				<p>Self-host on your own server. Import from Copy Me That. Export anytime. AGPL licensed.</p>
			</div>
		</div>
	</section>

	<section class="nn-stats">
		<div class="nn-stat">
			<span class="nn-stat-num">200+</span>
			<span class="nn-stat-lbl">Supported Sites</span>
		</div>
		<div class="nn-stat">
			<span class="nn-stat-num">30s</span>
			<span class="nn-stat-lbl">Average Import</span>
		</div>
		<div class="nn-stat">
			<span class="nn-stat-num">100%</span>
			<span class="nn-stat-lbl">Open Source</span>
		</div>
		<div class="nn-stat">
			<span class="nn-stat-num">0</span>
			<span class="nn-stat-lbl">Tracking Scripts</span>
		</div>
	</section>

	<section class="nn-cta">
		<h2>Ready to organize your recipe collection?</h2>
		<p>Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
		<button class="nn-btn">&#9658; Get Started Now!</button>
		<p class="nn-counter">You are visitor #00{Math.floor(Math.random() * 9000 + 1000)}</p>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="nn">
	<div class="nn-dash">
		<header class="nn-dash-header">
			<div>
				<h1>Welcome back!</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="nn-add-form">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="nn-btn nn-btn-sm">Save</button>
			</div>
		</header>

		<section class="nn-section">
			<h2>// Tonight's Inspiration //</h2>
			<div class="nn-hero-card">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} />
				<div class="nn-hero-card-overlay">
					<span class="nn-time-badge">{dinnerIdeas[0].total_time_minutes} min</span>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="nn-card-grid">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="nn-card">
						<div class="nn-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="nn-card-body">
							<h3>{recipe.title}</h3>
							<div class="nn-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>[{recipe.source_domain}]</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="nn-section">
			<h2>// Recently Added //</h2>
			<div class="nn-card-grid">
				{#each recentlyAdded as recipe}
					<div class="nn-card">
						<div class="nn-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="nn-card-body">
							<h3>{recipe.title}</h3>
							<div class="nn-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>[{recipe.source_domain}]</span>
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
<div class="nn">
	<div class="nn-recipe">
		<div class="nn-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="nn-recipe-hero-overlay">
				<div class="nn-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="nn-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="nn-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="nn-recipe-content">
			<div class="nn-recipe-meta">
				<div class="nn-meta-item">
					<span class="nn-meta-lbl">PREP</span>
					<span class="nn-meta-val">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="nn-meta-item">
					<span class="nn-meta-lbl">COOK</span>
					<span class="nn-meta-val">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="nn-meta-item">
					<span class="nn-meta-lbl">TOTAL</span>
					<span class="nn-meta-val">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="nn-meta-item">
					<span class="nn-meta-lbl">SERVES</span>
					<span class="nn-meta-val">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="nn-recipe-desc">{featuredRecipe.description}</p>

			<div class="nn-recipe-actions">
				<button class="nn-btn nn-btn-sm">&#128722; Add to Shopping List</button>
				<button class="nn-btn nn-btn-sm nn-btn-alt">&#128424; Print</button>
				<button class="nn-btn nn-btn-sm nn-btn-alt">&#9998; Edit</button>
				<div class="nn-scale">
					<button class="nn-scale-btn">&minus;</button>
					<span>1x</span>
					<button class="nn-scale-btn">+</button>
				</div>
			</div>

			<div class="nn-recipe-body">
				<aside class="nn-ingredients">
					<h2>// Ingredients //</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>&#9632; {ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="nn-instructions">
					<h2>// Instructions //</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="nn-step-num">Step {i + 1}.</span>
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
		background: #000080;
		color: #ffff00;
		font-size: var(--text-sm);
		font-family: 'Courier New', monospace;
		border-bottom: 3px solid #c0c0c0;
	}
	.mockup-nav .back { color: #00ffff; text-decoration: underline; }
	.mockup-nav .back:hover { color: #ff00ff; }
	.mockup-nav .label { flex: 1; font-weight: bold; }
	.mockup-nav .views { display: flex; gap: 4px; }
	.mockup-nav .views button {
		padding: 4px 12px;
		background: #c0c0c0;
		color: #000;
		border: 2px outset #fff;
		cursor: pointer;
		font-size: 11px;
		font-family: 'Courier New', monospace;
		font-weight: bold;
	}
	.mockup-nav .views button.active {
		background: #ffff00;
		color: #000080;
		border-style: inset;
	}

	/* === 90s THEME === */
	.nn {
		font-family: 'Verdana', 'Geneva', sans-serif;
		color: #000;
		background: #fff;
		background-image:
			linear-gradient(90deg, rgba(0,0,128,0.03) 1px, transparent 1px),
			linear-gradient(rgba(0,0,128,0.03) 1px, transparent 1px);
		background-size: 20px 20px;
	}

	/* BUTTONS */
	.nn-btn {
		padding: 8px 20px;
		background: #000080;
		color: #ffff00;
		border: 3px outset #9999cc;
		font-family: 'Verdana', sans-serif;
		font-size: 0.875rem;
		font-weight: bold;
		cursor: pointer;
		text-decoration: none;
		display: inline-block;
		transition: none;
	}
	.nn-btn:hover { background: #0000aa; }
	.nn-btn:active { border-style: inset; }
	.nn-btn-alt {
		background: #c0c0c0;
		color: #000;
		border-color: #fff;
	}
	.nn-btn-alt:hover { background: #d0d0d0; }
	.nn-btn-sm { padding: 4px 14px; font-size: 0.75rem; }

	/* LANDING - HERO */
	.nn-hero {
		display: grid;
		grid-template-columns: 1.2fr 1fr;
		min-height: 70vh;
		padding: 2rem;
		gap: 2rem;
		max-width: 1100px;
		margin: 0 auto;
	}
	.nn-hero-inner {
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.nn-marquee {
		padding: 6px 12px;
		background: #000080;
		color: #ffff00;
		font-family: 'Courier New', monospace;
		font-size: 0.75rem;
		font-weight: bold;
		margin-bottom: 1.5rem;
		overflow: hidden;
		white-space: nowrap;
		letter-spacing: 0.05em;
	}
	.nn-hero-inner h1 {
		font-size: 3rem;
		line-height: 1.1;
		margin: 0 0 1rem;
		color: #000080;
		font-weight: bold;
	}
	.nn-accent { color: #ff0000; }
	.nn-hero-sub {
		font-size: 1rem;
		line-height: 1.65;
		color: #333;
		margin: 0 0 1.5rem;
		max-width: 440px;
	}
	.nn-hero-btns { display: flex; gap: 0.75rem; margin-bottom: 1.5rem; }
	.nn-badges { display: flex; gap: 0.5rem; }
	.nn-badge-item {
		padding: 3px 10px;
		background: #ffff00;
		color: #000080;
		border: 2px solid #000080;
		font-size: 0.625rem;
		font-weight: bold;
		font-family: 'Courier New', monospace;
		letter-spacing: 0.08em;
	}

	.nn-hero-side {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
	}
	.nn-hero-img-frame {
		border: 4px solid #000080;
		padding: 4px;
		background: white;
		box-shadow: 4px 4px 0 #c0c0c0;
	}
	.nn-hero-img-frame img {
		width: 100%;
		max-width: 380px;
		display: block;
	}
	.nn-img-caption {
		font-family: 'Courier New', monospace;
		font-size: 0.75rem;
		color: #666;
		margin: 0.75rem 0 0;
		font-style: italic;
	}

	/* SEPARATOR */
	.nn-separator {
		max-width: 1100px;
		margin: 0 auto;
		padding: 0 2rem;
	}
	.nn-separator hr {
		border: none;
		height: 3px;
		background: linear-gradient(90deg, #ff0000, #ffff00, #00ff00, #00ffff, #0000ff, #ff00ff, #ff0000);
	}

	/* HOW IT WORKS */
	.nn-how {
		max-width: 1000px;
		margin: 0 auto;
		padding: 2.5rem 2rem;
	}
	.nn-how h2, .nn-features h2, .nn-showcase-text h2 {
		font-size: 1.5rem;
		color: #000080;
		margin: 0 0 2rem;
		text-align: center;
		font-weight: bold;
	}
	.nn-how-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.5rem;
	}
	.nn-how-step {
		background: #fffff0;
		border: 2px solid #000080;
		padding: 1.5rem;
		text-align: center;
	}
	.nn-how-num {
		display: inline-block;
		padding: 2px 12px;
		background: #000080;
		color: #ffff00;
		font-family: 'Courier New', monospace;
		font-size: 0.75rem;
		font-weight: bold;
		margin-bottom: 0.75rem;
		letter-spacing: 0.08em;
	}
	.nn-how-step h3 {
		font-size: 1.0625rem;
		margin: 0 0 0.5rem;
		color: #000080;
	}
	.nn-how-step p {
		color: #333;
		line-height: 1.6;
		margin: 0;
		font-size: 0.875rem;
	}

	/* SHOWCASE */
	.nn-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2.5rem 2rem;
		display: grid;
		grid-template-columns: 1fr 1.2fr;
		gap: 2.5rem;
		align-items: center;
	}
	.nn-showcase-text h2 { text-align: left; }
	.nn-showcase-text p {
		color: #333;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}
	.nn-showcase-cards {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}
	.nn-showcase-card {
		display: flex;
		gap: 0.75rem;
		background: #fffff0;
		border: 2px solid #000080;
		overflow: hidden;
		transition: background 150ms;
		cursor: pointer;
	}
	.nn-showcase-card:hover { background: #ffffcc; }
	.nn-showcase-card img {
		width: 100px;
		height: 70px;
		object-fit: cover;
		flex-shrink: 0;
		border-right: 2px solid #000080;
	}
	.nn-showcase-info {
		padding: 0.5rem 0.75rem;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.nn-showcase-source {
		font-family: 'Courier New', monospace;
		font-size: 0.625rem;
		color: #0000ff;
		font-weight: bold;
		margin-bottom: 0.25rem;
	}
	.nn-showcase-info h4 {
		font-size: 0.875rem;
		margin: 0;
		color: #000080;
		line-height: 1.3;
	}

	/* FEATURES */
	.nn-features {
		max-width: 1000px;
		margin: 0 auto;
		padding: 2.5rem 2rem;
	}
	.nn-feat-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1rem;
	}
	.nn-feat {
		padding: 1.25rem;
		background: #fffff0;
		border: 2px solid #c0c0c0;
		border-left: 4px solid #000080;
	}
	.nn-feat:hover { border-color: #000080; }
	.nn-feat h3 {
		font-size: 0.9375rem;
		margin: 0 0 0.375rem;
		color: #000080;
	}
	.nn-feat p {
		color: #333;
		line-height: 1.55;
		margin: 0;
		font-size: 0.8125rem;
	}

	/* STATS */
	.nn-stats {
		display: flex;
		justify-content: center;
		gap: 2rem;
		padding: 2rem;
		background: #000080;
		color: white;
	}
	.nn-stat {
		text-align: center;
		padding: 1rem 2rem;
		border: 2px solid #ffff00;
	}
	.nn-stat-num {
		display: block;
		font-size: 2rem;
		font-weight: bold;
		color: #ffff00;
		font-family: 'Courier New', monospace;
		line-height: 1;
		margin-bottom: 0.25rem;
	}
	.nn-stat-lbl {
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: #c0c0ff;
	}

	/* CTA */
	.nn-cta {
		text-align: center;
		padding: 3rem 2rem;
		background: #fffff0;
		border-top: 3px solid #000080;
		border-bottom: 3px solid #000080;
	}
	.nn-cta h2 {
		font-size: 1.5rem;
		color: #000080;
		margin: 0 0 0.5rem;
	}
	.nn-cta p {
		color: #666;
		font-size: 0.9375rem;
		margin: 0 0 1.5rem;
	}
	.nn-counter {
		font-family: 'Courier New', monospace;
		font-size: 0.75rem;
		color: #999;
		margin-top: 1.5rem !important;
		letter-spacing: 0.05em;
	}

	/* DASHBOARD */
	.nn-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.nn-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 2rem;
		padding-bottom: 1rem;
		border-bottom: 3px solid #000080;
	}
	.nn-dash-header h1 {
		font-size: 1.75rem;
		margin: 0;
		color: #000080;
	}
	.nn-dash-header p {
		margin: 0.25rem 0 0;
		color: #666;
		font-size: 0.9375rem;
	}
	.nn-add-form { display: flex; gap: 4px; }
	.nn-add-form input {
		padding: 4px 10px;
		border: 2px inset #c0c0c0;
		font-size: 0.875rem;
		width: 280px;
		background: white;
		font-family: 'Verdana', sans-serif;
	}
	.nn-add-form input:focus { outline: 2px solid #000080; }

	.nn-section { margin-bottom: 2.5rem; }
	.nn-section h2 {
		font-size: 1.125rem;
		color: #000080;
		margin: 0 0 1rem;
		font-weight: bold;
	}

	.nn-hero-card {
		position: relative;
		overflow: hidden;
		margin-bottom: 1rem;
		aspect-ratio: 21/9;
		border: 3px solid #000080;
	}
	.nn-hero-card img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.nn-hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 2.5rem 1.5rem 1.5rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
		color: white;
	}
	.nn-time-badge {
		display: inline-block;
		padding: 2px 8px;
		background: #ffff00;
		color: #000080;
		font-family: 'Courier New', monospace;
		font-size: 0.6875rem;
		font-weight: bold;
		margin-bottom: 0.5rem;
	}
	.nn-hero-card-overlay h3 {
		font-size: 1.5rem;
		margin: 0 0 0.375rem;
		font-weight: bold;
	}
	.nn-hero-card-overlay p {
		margin: 0;
		font-size: 0.8125rem;
		opacity: 0.85;
		max-width: 480px;
	}

	.nn-card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1rem;
	}
	.nn-card {
		background: white;
		border: 2px solid #c0c0c0;
		overflow: hidden;
		cursor: pointer;
		transition: border-color 150ms;
	}
	.nn-card:hover { border-color: #000080; }
	.nn-card-img {
		aspect-ratio: 16/10;
		overflow: hidden;
		border-bottom: 2px solid #c0c0c0;
	}
	.nn-card-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.nn-card-body { padding: 0.75rem; }
	.nn-card-body h3 {
		font-size: 0.875rem;
		margin: 0 0 0.25rem;
		color: #000080;
		line-height: 1.35;
	}
	.nn-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.6875rem;
		color: #0000ff;
		font-family: 'Courier New', monospace;
	}

	/* RECIPE */
	.nn-recipe-hero {
		position: relative;
		height: 50vh;
		min-height: 350px;
		overflow: hidden;
		border-bottom: 3px solid #000080;
	}
	.nn-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.nn-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 2rem 2rem;
		background: linear-gradient(transparent, rgba(0, 0, 128, 0.85));
		color: white;
	}
	.nn-recipe-tags { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; }
	.nn-tag {
		padding: 2px 10px;
		background: #ffff00;
		color: #000080;
		font-size: 0.625rem;
		font-weight: bold;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		font-family: 'Courier New', monospace;
	}
	.nn-recipe-hero-overlay h1 {
		font-size: 2.25rem;
		margin: 0 0 0.5rem;
		font-weight: bold;
		line-height: 1.15;
	}
	.nn-recipe-source {
		font-size: 0.8125rem;
		opacity: 0.7;
		margin: 0;
		font-family: 'Courier New', monospace;
	}

	.nn-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}

	.nn-recipe-meta {
		display: flex;
		gap: 1.5rem;
		padding: 1rem;
		background: #fffff0;
		border: 2px solid #000080;
		margin-bottom: 1.5rem;
	}
	.nn-meta-item { text-align: center; flex: 1; }
	.nn-meta-lbl {
		display: block;
		font-size: 0.5625rem;
		letter-spacing: 0.12em;
		color: #000080;
		font-weight: bold;
		margin-bottom: 0.25rem;
		font-family: 'Courier New', monospace;
	}
	.nn-meta-val {
		font-size: 1rem;
		color: #000;
		font-weight: bold;
	}

	.nn-recipe-desc {
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #333;
		margin: 0 0 1.5rem;
	}

	.nn-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 2rem;
		padding-bottom: 1.5rem;
		border-bottom: 3px solid #c0c0c0;
	}
	.nn-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 4px;
		font-size: 0.875rem;
		color: #333;
		font-weight: bold;
		font-family: 'Courier New', monospace;
	}
	.nn-scale-btn {
		width: 28px;
		height: 28px;
		border: 2px outset #c0c0c0;
		background: #c0c0c0;
		cursor: pointer;
		font-size: 1rem;
		color: #000;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: bold;
	}
	.nn-scale-btn:active { border-style: inset; }

	.nn-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 2rem;
	}
	.nn-ingredients h2,
	.nn-instructions h2 {
		font-size: 1rem;
		color: #000080;
		margin: 0 0 1rem;
		font-weight: bold;
	}
	.nn-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.nn-ingredients li {
		padding: 0.5rem 0;
		border-bottom: 1px dashed #c0c0c0;
		font-size: 0.875rem;
		color: #333;
		line-height: 1.5;
	}
	.nn-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.nn-instructions li {
		margin-bottom: 1.5rem;
	}
	.nn-step-num {
		display: block;
		font-family: 'Courier New', monospace;
		font-size: 0.75rem;
		font-weight: bold;
		color: #000080;
		margin-bottom: 0.375rem;
	}
	.nn-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #333;
	}
</style>
