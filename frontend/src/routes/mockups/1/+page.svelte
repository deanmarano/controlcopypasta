<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 1: Editorial Kitchen</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="ed">
	<header class="ed-hero">
		<div class="ed-hero-inner">
			<p class="ed-eyebrow">Self-hosted recipe management</p>
			<h1 class="ed-title">Your recipes,<br />your kitchen,<br />your rules.</h1>
			<p class="ed-subtitle">Save recipes from anywhere on the web. Scale, organize, and cook with confidence. No subscriptions, no ads, no data harvesting.</p>
			<div class="ed-hero-actions">
				<button class="ed-btn-primary">Get Started</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="ed-btn-ghost">View on GitHub</a>
			</div>
		</div>
		<div class="ed-hero-image">
			<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
		</div>
	</header>

	<section class="ed-features">
		<div class="ed-feature-grid">
			<div class="ed-feature">
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. We extract ingredients, steps, and images automatically.</p>
			</div>
			<div class="ed-feature">
				<h3>Scale with confidence</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="ed-feature">
				<h3>Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients from verified sources.</p>
			</div>
			<div class="ed-feature">
				<h3>Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="ed-feature">
				<h3>Find connections</h3>
				<p>Discover which recipes share ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="ed-feature">
				<h3>Own your data</h3>
				<p>Self-host on your own server. Import from Copy Me That. Export anytime. AGPL licensed.</p>
			</div>
		</div>
	</section>

	<section class="ed-cta-section">
		<h2>Ready to take control of your recipe collection?</h2>
		<button class="ed-btn-primary">Get Started</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="ed">
	<div class="ed-dash">
		<header class="ed-dash-header">
			<div class="ed-dash-greeting">
				<h1>Good evening.</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="ed-add-recipe">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="ed-btn-primary ed-btn-sm">Save</button>
			</div>
		</header>

		<section class="ed-section">
			<div class="ed-section-header">
				<h2>Tonight's inspiration</h2>
				<button class="ed-btn-text">Shuffle</button>
			</div>
			<div class="ed-hero-card">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} class="ed-hero-card-img" />
				<div class="ed-hero-card-overlay">
					<span class="ed-hero-card-tag">{dinnerIdeas[0].total_time_minutes} min</span>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="ed-card-row">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="ed-card">
						<div class="ed-card-img-wrap">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="ed-card-body">
							<h3>{recipe.title}</h3>
							<div class="ed-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="ed-section">
			<div class="ed-section-header">
				<h2>Recently added</h2>
				<a href="/recipes" class="ed-btn-text">View all</a>
			</div>
			<div class="ed-card-row">
				{#each recentlyAdded as recipe}
					<div class="ed-card">
						<div class="ed-card-img-wrap">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="ed-card-body">
							<h3>{recipe.title}</h3>
							<div class="ed-card-meta">
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
<div class="ed">
	<div class="ed-recipe">
		<div class="ed-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="ed-recipe-hero-overlay">
				<div class="ed-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="ed-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="ed-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="ed-recipe-content">
			<div class="ed-recipe-meta-bar">
				<div class="ed-meta-item">
					<span class="ed-meta-label">Prep</span>
					<span class="ed-meta-value">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="ed-meta-item">
					<span class="ed-meta-label">Cook</span>
					<span class="ed-meta-value">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="ed-meta-item">
					<span class="ed-meta-label">Total</span>
					<span class="ed-meta-value">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="ed-meta-item">
					<span class="ed-meta-label">Serves</span>
					<span class="ed-meta-value">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="ed-recipe-desc">{featuredRecipe.description}</p>

			<div class="ed-recipe-actions">
				<button class="ed-btn-primary ed-btn-sm">Add to Shopping List</button>
				<button class="ed-btn-outline ed-btn-sm">Print</button>
				<button class="ed-btn-outline ed-btn-sm">Edit</button>
				<div class="ed-scale">
					<button class="ed-scale-btn">-</button>
					<span>1x</span>
					<button class="ed-scale-btn">+</button>
				</div>
			</div>

			<div class="ed-recipe-body">
				<aside class="ed-ingredients">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>{ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="ed-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="ed-step-num">{i + 1}</span>
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

	/* === EDITORIAL THEME === */
	.ed {
		font-family: 'Inter', system-ui, sans-serif;
		color: #2c2420;
		background: #faf8f5;
	}

	/* LANDING */
	.ed-hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		min-height: 80vh;
		overflow: hidden;
	}
	.ed-hero-inner {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 4rem 3rem 4rem 6rem;
	}
	.ed-eyebrow {
		text-transform: uppercase;
		letter-spacing: 0.15em;
		font-size: 0.75rem;
		color: #96705a;
		margin: 0 0 1.5rem;
		font-weight: 500;
	}
	.ed-title {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 3.5rem;
		line-height: 1.1;
		margin: 0 0 1.5rem;
		color: #2c2420;
		font-weight: 700;
	}
	.ed-subtitle {
		font-size: 1.125rem;
		line-height: 1.7;
		color: #6b5c52;
		margin: 0 0 2.5rem;
		max-width: 420px;
	}
	.ed-hero-actions { display: flex; gap: 1rem; }
	.ed-hero-image { position: relative; overflow: hidden; }
	.ed-hero-image img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}

	.ed-btn-primary {
		padding: 0.875rem 2rem;
		background: #2c2420;
		color: #faf8f5;
		border: none;
		border-radius: 2px;
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
		letter-spacing: 0.02em;
		transition: background 200ms;
	}
	.ed-btn-primary:hover { background: #4a3f38; }
	.ed-btn-sm { padding: 0.5rem 1.25rem; font-size: 0.8125rem; }

	.ed-btn-ghost {
		padding: 0.875rem 2rem;
		background: none;
		color: #2c2420;
		border: 1.5px solid #c4b5a8;
		border-radius: 2px;
		font-size: 0.9375rem;
		font-weight: 500;
		text-decoration: none;
		transition: all 200ms;
	}
	.ed-btn-ghost:hover { border-color: #2c2420; }

	.ed-btn-outline {
		padding: 0.5rem 1.25rem;
		background: none;
		color: #6b5c52;
		border: 1.5px solid #d4c8bb;
		border-radius: 2px;
		font-size: 0.8125rem;
		cursor: pointer;
		transition: all 200ms;
	}
	.ed-btn-outline:hover { border-color: #2c2420; color: #2c2420; }

	.ed-btn-text {
		background: none;
		border: none;
		color: #96705a;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: none;
		font-weight: 500;
		letter-spacing: 0.02em;
	}
	.ed-btn-text:hover { color: #2c2420; }

	/* Features */
	.ed-features {
		padding: 5rem 3rem;
		max-width: 1100px;
		margin: 0 auto;
	}
	.ed-feature-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2.5rem;
	}
	.ed-feature h3 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 1.25rem;
		margin: 0 0 0.75rem;
		color: #2c2420;
	}
	.ed-feature p {
		color: #6b5c52;
		line-height: 1.7;
		margin: 0;
		font-size: 0.9375rem;
	}

	.ed-cta-section {
		text-align: center;
		padding: 5rem 2rem;
		background: #2c2420;
		color: #faf8f5;
	}
	.ed-cta-section h2 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 2rem;
		margin: 0 0 2rem;
		font-weight: 400;
	}
	.ed-cta-section .ed-btn-primary {
		background: #faf8f5;
		color: #2c2420;
	}
	.ed-cta-section .ed-btn-primary:hover {
		background: #e8e2da;
	}

	/* DASHBOARD */
	.ed-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.ed-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #e8e2da;
	}
	.ed-dash-greeting h1 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 2.25rem;
		margin: 0;
		color: #2c2420;
		font-weight: 400;
	}
	.ed-dash-greeting p {
		margin: 0.25rem 0 0;
		color: #96705a;
		font-size: 1rem;
	}
	.ed-add-recipe {
		display: flex;
		gap: 0.5rem;
	}
	.ed-add-recipe input {
		padding: 0.5rem 1rem;
		border: 1.5px solid #d4c8bb;
		border-radius: 2px;
		font-size: 0.875rem;
		width: 320px;
		background: transparent;
		color: #2c2420;
	}
	.ed-add-recipe input::placeholder { color: #b5a696; }
	.ed-add-recipe input:focus { outline: none; border-color: #2c2420; }

	.ed-section { margin-bottom: 3rem; }
	.ed-section-header {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1.25rem;
	}
	.ed-section-header h2 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 1.375rem;
		margin: 0;
		color: #2c2420;
		font-weight: 400;
	}

	.ed-hero-card {
		position: relative;
		border-radius: 4px;
		overflow: hidden;
		margin-bottom: 1.25rem;
		aspect-ratio: 21/9;
	}
	.ed-hero-card-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.ed-hero-card-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 2rem 2rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
		color: white;
	}
	.ed-hero-card-overlay h3 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 1.75rem;
		margin: 0 0 0.5rem;
		font-weight: 400;
	}
	.ed-hero-card-overlay p {
		margin: 0;
		font-size: 0.875rem;
		opacity: 0.85;
		max-width: 500px;
	}
	.ed-hero-card-tag {
		display: inline-block;
		padding: 0.25rem 0.625rem;
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: 2px;
		font-size: 0.75rem;
		margin-bottom: 0.75rem;
		font-weight: 500;
	}

	.ed-card-row {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1.25rem;
	}
	.ed-card {
		background: white;
		border-radius: 4px;
		overflow: hidden;
		transition: transform 200ms, box-shadow 200ms;
		cursor: pointer;
	}
	.ed-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 24px rgba(44, 36, 32, 0.1);
	}
	.ed-card-img-wrap {
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.ed-card-img-wrap img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.ed-card:hover .ed-card-img-wrap img {
		transform: scale(1.03);
	}
	.ed-card-body {
		padding: 1rem;
	}
	.ed-card-body h3 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 1rem;
		margin: 0 0 0.5rem;
		color: #2c2420;
		font-weight: 400;
		line-height: 1.4;
	}
	.ed-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.75rem;
		color: #96705a;
	}

	/* RECIPE */
	.ed-recipe-hero {
		position: relative;
		height: 60vh;
		min-height: 400px;
		overflow: hidden;
	}
	.ed-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.ed-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 4rem 3rem 3rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
		color: white;
	}
	.ed-recipe-hero-overlay h1 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 2.75rem;
		margin: 0 0 0.5rem;
		font-weight: 400;
		line-height: 1.15;
	}
	.ed-recipe-source {
		font-size: 0.875rem;
		opacity: 0.7;
		margin: 0;
	}
	.ed-recipe-tags { display: flex; gap: 0.5rem; margin-bottom: 1rem; }
	.ed-tag {
		padding: 0.25rem 0.75rem;
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: 2px;
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		font-weight: 500;
	}

	.ed-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2.5rem 1.5rem;
	}

	.ed-recipe-meta-bar {
		display: flex;
		gap: 2.5rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #e8e2da;
		margin-bottom: 2rem;
	}
	.ed-meta-item { text-align: center; }
	.ed-meta-label {
		display: block;
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: #96705a;
		margin-bottom: 0.25rem;
	}
	.ed-meta-value {
		font-size: 1.125rem;
		color: #2c2420;
		font-weight: 500;
	}

	.ed-recipe-desc {
		font-size: 1.0625rem;
		line-height: 1.7;
		color: #6b5c52;
		margin: 0 0 2rem;
	}

	.ed-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #e8e2da;
	}
	.ed-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.875rem;
		color: #6b5c52;
	}
	.ed-scale-btn {
		width: 28px;
		height: 28px;
		border: 1.5px solid #d4c8bb;
		border-radius: 2px;
		background: none;
		cursor: pointer;
		font-size: 1rem;
		color: #6b5c52;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.ed-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 3rem;
	}
	.ed-ingredients h2,
	.ed-instructions h2 {
		font-family: 'Playfair Display', Georgia, serif;
		font-size: 1.25rem;
		margin: 0 0 1.25rem;
		color: #2c2420;
		font-weight: 400;
	}
	.ed-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.ed-ingredients li {
		padding: 0.75rem 0;
		border-bottom: 1px solid #ede8e1;
		font-size: 0.9375rem;
		color: #4a3f38;
		line-height: 1.5;
	}
	.ed-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
		counter-reset: none;
	}
	.ed-instructions li {
		display: flex;
		gap: 1.25rem;
		margin-bottom: 1.75rem;
		align-items: flex-start;
	}
	.ed-step-num {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: 1.5px solid #d4c8bb;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.8125rem;
		color: #96705a;
		font-weight: 500;
		margin-top: 2px;
	}
	.ed-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.7;
		color: #4a3f38;
	}
</style>
