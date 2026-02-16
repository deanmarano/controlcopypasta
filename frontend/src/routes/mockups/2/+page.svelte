<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 2: Retro 50s Kitchen</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="rt">
	<header class="rt-hero">
		<div class="rt-hero-inner">
			<div class="rt-badge">Self-Hosted &bull; Open Source</div>
			<h1>Your Recipe Box,<br/>Darling!</h1>
			<p class="rt-hero-sub">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="rt-hero-btns">
				<button class="rt-btn-primary">Get Started</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="rt-btn-outline">View on GitHub</a>
			</div>
		</div>
		<div class="rt-hero-img">
			<div class="rt-hero-frame">
				<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
			</div>
		</div>
	</header>

	<div class="rt-divider">
		<span class="rt-divider-diamond"></span>
	</div>

	<section class="rt-how">
		<h2>Easy as Pie!</h2>
		<div class="rt-how-grid">
			<div class="rt-how-step">
				<div class="rt-how-num">1</div>
				<h3>Clip It</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything — ingredients, instructions, images, and nutrition data.</p>
			</div>
			<div class="rt-how-step">
				<div class="rt-how-num">2</div>
				<h3>File It</h3>
				<p>Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection that mirrors how you actually cook.</p>
			</div>
			<div class="rt-how-step">
				<div class="rt-how-num">3</div>
				<h3>Cook It</h3>
				<p>Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists. Print clean recipe cards for the kitchen counter.</p>
			</div>
		</div>
	</section>

	<section class="rt-showcase">
		<div class="rt-showcase-text">
			<div class="rt-badge">Your Collection</div>
			<h2>Every recipe from every corner of the web, in one place.</h2>
			<p>Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs — any site with a recipe. The browser extension makes it one click.</p>
		</div>
		<div class="rt-showcase-cards">
			{#each recipes.slice(0, 3) as recipe}
				<div class="rt-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="rt-showcase-info">
						<span class="rt-showcase-source">{recipe.source_domain}</span>
						<h4>{recipe.title}</h4>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<div class="rt-divider">
		<span class="rt-divider-diamond"></span>
	</div>

	<section class="rt-features">
		<h2>What's Cookin'?</h2>
		<div class="rt-feat-grid">
			<div class="rt-feat">
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. We extract ingredients, steps, and images automatically.</p>
			</div>
			<div class="rt-feat">
				<h3>Scale with confidence</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="rt-feat">
				<h3>Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from verified sources.</p>
			</div>
			<div class="rt-feat">
				<h3>Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="rt-feat">
				<h3>Find connections</h3>
				<p>Discover which recipes share ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="rt-feat">
				<h3>Own your data</h3>
				<p>Self-host on your own server. Import from Copy Me That. Export anytime. AGPL licensed.</p>
			</div>
		</div>
	</section>

	<section class="rt-stats">
		<div class="rt-stat">
			<span class="rt-stat-num">200+</span>
			<span class="rt-stat-lbl">Supported Sites</span>
		</div>
		<div class="rt-stat">
			<span class="rt-stat-num">30s</span>
			<span class="rt-stat-lbl">Average Import</span>
		</div>
		<div class="rt-stat">
			<span class="rt-stat-num">100%</span>
			<span class="rt-stat-lbl">Open Source</span>
		</div>
		<div class="rt-stat">
			<span class="rt-stat-num">0</span>
			<span class="rt-stat-lbl">Tracking Scripts</span>
		</div>
	</section>

	<section class="rt-cta">
		<h2>Ready to organize your recipe collection?</h2>
		<p>Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
		<button class="rt-btn-primary">Get Started</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="rt">
	<div class="rt-dash">
		<header class="rt-dash-header">
			<div>
				<h1>Good Evening, Sugar!</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="rt-add-form">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="rt-btn-primary rt-btn-sm">Save</button>
			</div>
		</header>

		<section class="rt-section">
			<div class="rt-section-top">
				<h2>Tonight's Inspiration</h2>
				<button class="rt-link-btn">Shuffle</button>
			</div>
			<div class="rt-hero-card">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} />
				<div class="rt-hero-card-overlay">
					<span class="rt-badge">{dinnerIdeas[0].total_time_minutes} min</span>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="rt-card-grid">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="rt-card">
						<div class="rt-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="rt-card-body">
							<h3>{recipe.title}</h3>
							<div class="rt-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="rt-section">
			<div class="rt-section-top">
				<h2>Recently Added</h2>
				<a href="/recipes" class="rt-link-btn">View all</a>
			</div>
			<div class="rt-card-grid">
				{#each recentlyAdded as recipe}
					<div class="rt-card">
						<div class="rt-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="rt-card-body">
							<h3>{recipe.title}</h3>
							<div class="rt-card-meta">
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
<div class="rt">
	<div class="rt-recipe">
		<div class="rt-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="rt-recipe-hero-overlay">
				<div class="rt-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="rt-badge">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="rt-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="rt-recipe-content">
			<div class="rt-recipe-meta">
				<div class="rt-meta-item">
					<span class="rt-meta-lbl">Prep</span>
					<span class="rt-meta-val">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="rt-meta-item">
					<span class="rt-meta-lbl">Cook</span>
					<span class="rt-meta-val">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="rt-meta-item">
					<span class="rt-meta-lbl">Total</span>
					<span class="rt-meta-val">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="rt-meta-item">
					<span class="rt-meta-lbl">Serves</span>
					<span class="rt-meta-val">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="rt-recipe-desc">{featuredRecipe.description}</p>

			<div class="rt-recipe-actions">
				<button class="rt-btn-primary rt-btn-sm">Add to Shopping List</button>
				<button class="rt-btn-outline rt-btn-sm">Print</button>
				<button class="rt-btn-outline rt-btn-sm">Edit</button>
				<div class="rt-scale">
					<button class="rt-scale-btn">&minus;</button>
					<span>1x</span>
					<button class="rt-scale-btn">+</button>
				</div>
			</div>

			<div class="rt-recipe-body">
				<aside class="rt-ingredients">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>{ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="rt-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="rt-step-num">{i + 1}</span>
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
		background: #b91c3a;
		color: white;
		font-size: var(--text-sm);
		border-bottom: 3px solid #8b1530;
	}
	.mockup-nav .back { color: rgba(255,255,255,0.7); text-decoration: none; }
	.mockup-nav .back:hover { color: white; }
	.mockup-nav .label { flex: 1; font-weight: var(--font-medium); }
	.mockup-nav .views { display: flex; gap: 2px; }
	.mockup-nav .views button {
		padding: var(--space-1) var(--space-3);
		background: rgba(255,255,255,0.15);
		color: rgba(255,255,255,0.8);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
	}
	.mockup-nav .views button.active { background: #fef3c7; color: #8b1530; font-weight: 600; }

	/* === RETRO 50s THEME === */
	.rt {
		font-family: 'Inter', system-ui, sans-serif;
		color: #3d2b2b;
		background: #fdf6ee;
	}

	/* Shared */
	.rt-badge {
		display: inline-block;
		padding: 0.3rem 0.875rem;
		background: #b91c3a;
		color: white;
		border-radius: 2px;
		font-size: 0.6875rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.1em;
	}

	.rt-divider {
		text-align: center;
		padding: 2rem 0;
	}
	.rt-divider-diamond {
		display: inline-block;
		width: 12px;
		height: 12px;
		background: #b91c3a;
		transform: rotate(45deg);
	}

	/* BUTTONS */
	.rt-btn-primary {
		padding: 0.75rem 2rem;
		background: #b91c3a;
		color: white;
		border: none;
		border-radius: 3px;
		font-size: 0.9375rem;
		font-weight: 700;
		cursor: pointer;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		transition: all 200ms;
		box-shadow: 0 3px 0 #8b1530;
	}
	.rt-btn-primary:hover { background: #d42248; transform: translateY(-1px); box-shadow: 0 4px 0 #8b1530; }
	.rt-btn-primary:active { transform: translateY(1px); box-shadow: 0 1px 0 #8b1530; }
	.rt-btn-sm { padding: 0.5rem 1.25rem; font-size: 0.75rem; }

	.rt-btn-outline {
		padding: 0.75rem 2rem;
		background: none;
		color: #b91c3a;
		border: 2px solid #b91c3a;
		border-radius: 3px;
		font-size: 0.9375rem;
		font-weight: 700;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		cursor: pointer;
		text-decoration: none;
		transition: all 200ms;
	}
	.rt-btn-outline:hover { background: #b91c3a; color: white; }

	.rt-link-btn {
		background: none;
		border: none;
		color: #b91c3a;
		font-size: 0.875rem;
		font-weight: 700;
		cursor: pointer;
		text-decoration: none;
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}
	.rt-link-btn:hover { text-decoration: underline; }

	/* LANDING - HERO */
	.rt-hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		min-height: 75vh;
		overflow: hidden;
	}
	.rt-hero-inner {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 4rem 3rem 4rem 5rem;
		background: repeating-linear-gradient(
			0deg,
			transparent,
			transparent 19px,
			rgba(185, 28, 58, 0.06) 19px,
			rgba(185, 28, 58, 0.06) 20px
		);
	}
	.rt-hero-inner h1 {
		font-family: 'Georgia', serif;
		font-size: 3.25rem;
		line-height: 1.1;
		margin: 1rem 0 1.25rem;
		color: #3d2b2b;
		font-weight: 700;
	}
	.rt-hero-sub {
		font-size: 1.0625rem;
		line-height: 1.65;
		color: #7a6565;
		margin: 0 0 2rem;
		max-width: 400px;
	}
	.rt-hero-btns { display: flex; gap: 1rem; }
	.rt-hero-img {
		display: flex;
		align-items: center;
		justify-content: center;
		padding: 3rem;
		background: #a8d8c8;
	}
	.rt-hero-frame {
		border: 6px solid white;
		border-radius: 4px;
		box-shadow: 0 8px 32px rgba(0,0,0,0.15);
		overflow: hidden;
		transform: rotate(2deg);
	}
	.rt-hero-frame img {
		width: 100%;
		max-width: 440px;
		display: block;
	}

	/* HOW IT WORKS */
	.rt-how {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3rem 2rem 4rem;
		text-align: center;
	}
	.rt-how h2 {
		font-family: 'Georgia', serif;
		font-size: 2.25rem;
		color: #3d2b2b;
		margin: 0 0 2.5rem;
		font-weight: 700;
	}
	.rt-how-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2.5rem;
	}
	.rt-how-step { text-align: center; }
	.rt-how-num {
		width: 52px;
		height: 52px;
		background: #b91c3a;
		color: white;
		border-radius: 50%;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-family: 'Georgia', serif;
		font-size: 1.5rem;
		font-weight: 700;
		margin-bottom: 1rem;
		box-shadow: 0 3px 0 #8b1530;
	}
	.rt-how-step h3 {
		font-family: 'Georgia', serif;
		font-size: 1.25rem;
		margin: 0 0 0.625rem;
		color: #3d2b2b;
	}
	.rt-how-step p {
		color: #7a6565;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* SHOWCASE */
	.rt-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 3rem 2rem 4rem;
		display: grid;
		grid-template-columns: 1fr 1.2fr;
		gap: 3rem;
		align-items: center;
	}
	.rt-showcase-text h2 {
		font-family: 'Georgia', serif;
		font-size: 1.875rem;
		line-height: 1.25;
		margin: 0.75rem 0 1rem;
		color: #3d2b2b;
	}
	.rt-showcase-text p {
		color: #7a6565;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}
	.rt-showcase-cards {
		display: flex;
		flex-direction: column;
		gap: 0.875rem;
	}
	.rt-showcase-card {
		display: flex;
		gap: 1rem;
		background: white;
		border: 2px solid #e8d8cc;
		border-radius: 4px;
		overflow: hidden;
		transition: transform 200ms, border-color 200ms;
	}
	.rt-showcase-card:hover {
		transform: translateX(4px);
		border-color: #b91c3a;
	}
	.rt-showcase-card img {
		width: 110px;
		height: 75px;
		object-fit: cover;
		flex-shrink: 0;
	}
	.rt-showcase-info {
		padding: 0.625rem 1rem 0.625rem 0;
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.rt-showcase-source {
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: #b91c3a;
		font-weight: 700;
		margin-bottom: 0.25rem;
	}
	.rt-showcase-info h4 {
		font-family: 'Georgia', serif;
		font-size: 0.9375rem;
		margin: 0;
		color: #3d2b2b;
		line-height: 1.3;
	}

	/* FEATURES */
	.rt-features {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3rem 2rem 4rem;
		text-align: center;
	}
	.rt-features h2 {
		font-family: 'Georgia', serif;
		font-size: 2.25rem;
		color: #3d2b2b;
		margin: 0 0 2.5rem;
	}
	.rt-feat-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.5rem;
		text-align: left;
	}
	.rt-feat {
		padding: 1.5rem;
		background: white;
		border: 2px solid #e8d8cc;
		border-radius: 4px;
		transition: border-color 200ms;
	}
	.rt-feat:hover { border-color: #b91c3a; }
	.rt-feat h3 {
		font-family: 'Georgia', serif;
		font-size: 1.0625rem;
		margin: 0 0 0.5rem;
		color: #b91c3a;
	}
	.rt-feat p {
		color: #7a6565;
		line-height: 1.6;
		margin: 0;
		font-size: 0.875rem;
	}

	/* STATS */
	.rt-stats {
		display: flex;
		justify-content: center;
		gap: 3rem;
		padding: 3rem 2rem;
		background: #a8d8c8;
	}
	.rt-stat { text-align: center; }
	.rt-stat-num {
		display: block;
		font-family: 'Georgia', serif;
		font-size: 2.5rem;
		font-weight: 700;
		color: #3d2b2b;
		line-height: 1;
		margin-bottom: 0.375rem;
	}
	.rt-stat-lbl {
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #2b6e58;
		font-weight: 700;
	}

	/* CTA */
	.rt-cta {
		text-align: center;
		padding: 4rem 2rem;
		background: #b91c3a;
		color: white;
	}
	.rt-cta h2 {
		font-family: 'Georgia', serif;
		font-size: 2rem;
		margin: 0 0 0.75rem;
		font-weight: 700;
	}
	.rt-cta p {
		color: rgba(255,255,255,0.8);
		font-size: 1rem;
		margin: 0 0 2rem;
	}
	.rt-cta .rt-btn-primary {
		background: white;
		color: #b91c3a;
		box-shadow: 0 3px 0 rgba(0,0,0,0.15);
	}
	.rt-cta .rt-btn-primary:hover { background: #fef3c7; }

	/* DASHBOARD */
	.rt-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.rt-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 2.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 3px solid #e8d8cc;
	}
	.rt-dash-header h1 {
		font-family: 'Georgia', serif;
		font-size: 2rem;
		margin: 0;
		color: #3d2b2b;
	}
	.rt-dash-header p {
		margin: 0.25rem 0 0;
		color: #7a6565;
		font-size: 1rem;
	}
	.rt-add-form { display: flex; gap: 0.5rem; }
	.rt-add-form input {
		padding: 0.5rem 1rem;
		border: 2px solid #e8d8cc;
		border-radius: 3px;
		font-size: 0.875rem;
		width: 300px;
		background: white;
		color: #3d2b2b;
	}
	.rt-add-form input::placeholder { color: #c4b0a0; }
	.rt-add-form input:focus { outline: none; border-color: #b91c3a; }

	.rt-section { margin-bottom: 3rem; }
	.rt-section-top {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1.25rem;
	}
	.rt-section-top h2 {
		font-family: 'Georgia', serif;
		font-size: 1.375rem;
		margin: 0;
		color: #3d2b2b;
	}

	.rt-hero-card {
		position: relative;
		border-radius: 4px;
		overflow: hidden;
		margin-bottom: 1.25rem;
		aspect-ratio: 21/9;
		border: 3px solid #e8d8cc;
	}
	.rt-hero-card img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.rt-hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 2rem 1.5rem;
		background: linear-gradient(transparent, rgba(61, 43, 43, 0.85));
		color: white;
	}
	.rt-hero-card-overlay h3 {
		font-family: 'Georgia', serif;
		font-size: 1.625rem;
		margin: 0.75rem 0 0.5rem;
		font-weight: 700;
	}
	.rt-hero-card-overlay p {
		margin: 0;
		font-size: 0.875rem;
		opacity: 0.85;
		max-width: 500px;
	}

	.rt-card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1.25rem;
	}
	.rt-card {
		background: white;
		border: 2px solid #e8d8cc;
		border-radius: 4px;
		overflow: hidden;
		transition: transform 200ms, border-color 200ms;
		cursor: pointer;
	}
	.rt-card:hover {
		transform: translateY(-2px);
		border-color: #b91c3a;
	}
	.rt-card-img {
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.rt-card-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.rt-card:hover .rt-card-img img { transform: scale(1.03); }
	.rt-card-body { padding: 0.875rem 1rem; }
	.rt-card-body h3 {
		font-family: 'Georgia', serif;
		font-size: 0.9375rem;
		margin: 0 0 0.375rem;
		color: #3d2b2b;
		line-height: 1.35;
	}
	.rt-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.6875rem;
		color: #b91c3a;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		font-weight: 600;
	}

	/* RECIPE */
	.rt-recipe-hero {
		position: relative;
		height: 55vh;
		min-height: 380px;
		overflow: hidden;
	}
	.rt-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.rt-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 4rem 3rem 2.5rem;
		background: linear-gradient(transparent, rgba(61, 43, 43, 0.8));
		color: white;
	}
	.rt-recipe-tags { display: flex; gap: 0.5rem; margin-bottom: 0.75rem; }
	.rt-recipe-hero-overlay h1 {
		font-family: 'Georgia', serif;
		font-size: 2.5rem;
		margin: 0 0 0.5rem;
		font-weight: 700;
		line-height: 1.15;
	}
	.rt-recipe-source {
		font-size: 0.875rem;
		opacity: 0.7;
		margin: 0;
	}

	.rt-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2.5rem 1.5rem;
	}

	.rt-recipe-meta {
		display: flex;
		gap: 2rem;
		padding-bottom: 1.5rem;
		border-bottom: 3px solid #e8d8cc;
		margin-bottom: 1.5rem;
	}
	.rt-meta-item { text-align: center; }
	.rt-meta-lbl {
		display: block;
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: #b91c3a;
		font-weight: 700;
		margin-bottom: 0.25rem;
	}
	.rt-meta-val {
		font-family: 'Georgia', serif;
		font-size: 1.125rem;
		color: #3d2b2b;
		font-weight: 700;
	}

	.rt-recipe-desc {
		font-size: 1rem;
		line-height: 1.7;
		color: #7a6565;
		margin: 0 0 1.5rem;
	}

	.rt-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 2.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 3px solid #e8d8cc;
	}
	.rt-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.375rem;
		font-size: 0.875rem;
		color: #7a6565;
		font-weight: 600;
	}
	.rt-scale-btn {
		width: 30px;
		height: 30px;
		border: 2px solid #e8d8cc;
		border-radius: 3px;
		background: white;
		cursor: pointer;
		font-size: 1rem;
		color: #3d2b2b;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.rt-scale-btn:hover { border-color: #b91c3a; color: #b91c3a; }

	.rt-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 3rem;
	}
	.rt-ingredients h2,
	.rt-instructions h2 {
		font-family: 'Georgia', serif;
		font-size: 1.25rem;
		margin: 0 0 1.25rem;
		color: #b91c3a;
		text-transform: uppercase;
		letter-spacing: 0.04em;
		font-size: 1rem;
	}
	.rt-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.rt-ingredients li {
		padding: 0.625rem 0;
		border-bottom: 2px dashed #e8d8cc;
		font-size: 0.9375rem;
		color: #5a4545;
		line-height: 1.5;
	}
	.rt-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.rt-instructions li {
		display: flex;
		gap: 1.25rem;
		margin-bottom: 1.75rem;
		align-items: flex-start;
	}
	.rt-step-num {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: #b91c3a;
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: 'Georgia', serif;
		font-size: 0.8125rem;
		font-weight: 700;
		margin-top: 2px;
		box-shadow: 0 2px 0 #8b1530;
	}
	.rt-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.7;
		color: #5a4545;
	}
</style>
