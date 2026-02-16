<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 6: Frutiger Aero</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="fa">
	<header class="fa-hero">
		<div class="fa-hero-bg"></div>
		<div class="fa-hero-content">
			<div class="fa-hero-text">
				<h1 class="fa-title">Your recipes.<br/>Beautifully organized.</h1>
				<p class="fa-subtitle">Save recipes from anywhere on the web. Scale, organize, and cook with a tool that feels as fresh as your ingredients.</p>
				<div class="fa-hero-actions">
					<button class="fa-btn-primary">Get Started</button>
					<a href="https://github.com/deanmarano/controlcopypasta" class="fa-btn-glass">View on GitHub</a>
				</div>
			</div>
			<div class="fa-hero-visual">
				<div class="fa-glass-card fa-hero-card">
					<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
					<div class="fa-hero-card-info">
						<h3>{recipes[0].title}</h3>
						<span>{recipes[0].source_domain}</span>
					</div>
				</div>
				<div class="fa-floating-orb fa-orb-1"></div>
				<div class="fa-floating-orb fa-orb-2"></div>
			</div>
		</div>
	</header>

	<section class="fa-how-it-works">
		<h2>How it works</h2>
		<p class="fa-section-sub">Getting started takes just a few minutes.</p>
		<div class="fa-steps">
			<div class="fa-step-card">
				<div class="fa-step-icon">
					<div class="fa-step-num">1</div>
				</div>
				<h3>Paste a URL</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything automatically.</p>
			</div>
			<div class="fa-step-card">
				<div class="fa-step-icon">
					<div class="fa-step-num">2</div>
				</div>
				<h3>Organize your way</h3>
				<p>Tag by meal, cuisine, or season. Browse by source. Build a collection that mirrors how you cook.</p>
			</div>
			<div class="fa-step-card">
				<div class="fa-step-icon">
					<div class="fa-step-num">3</div>
				</div>
				<h3>Cook with confidence</h3>
				<p>Scale ingredients, check nutrition, generate shopping lists, and print clean recipe cards.</p>
			</div>
		</div>
	</section>

	<section class="fa-showcase">
		<div class="fa-showcase-text">
			<span class="fa-pill">Your collection</span>
			<h2>Every recipe from every corner of the web, in one place.</h2>
			<p>Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs — any site with a recipe.</p>
		</div>
		<div class="fa-showcase-cards">
			{#each recipes.slice(0, 3) as recipe}
				<div class="fa-glass-card fa-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="fa-showcase-card-info">
						<span class="fa-source-badge">{recipe.source_domain}</span>
						<h4>{recipe.title}</h4>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<section class="fa-features">
		<h2>Everything you need</h2>
		<p class="fa-section-sub">Powerful tools, beautiful simplicity.</p>
		<div class="fa-feature-grid">
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#127760;</div>
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. Ingredients, steps, and images — all captured.</p>
			</div>
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#9878;</div>
				<h3>Scale with ease</h3>
				<p>Cooking for 2 or 12? Adjust quantities from 0.25x to 4x with smart fraction handling.</p>
			</div>
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#127823;</div>
				<h3>Know your nutrition</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, and micronutrients.</p>
			</div>
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#128722;</div>
				<h3>Shop smarter</h3>
				<p>Generate shopping lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#128279;</div>
				<h3>Find connections</h3>
				<p>Discover shared ingredients. Compare side by side. Browse by source.</p>
			</div>
			<div class="fa-feature-card">
				<div class="fa-feature-icon">&#128737;</div>
				<h3>Own your data</h3>
				<p>Self-host on your own server. Import, export, AGPL licensed. Your recipes stay yours.</p>
			</div>
		</div>
	</section>

	<section class="fa-stats-bar">
		<div class="fa-stat"><span class="fa-stat-num">200+</span><span class="fa-stat-label">Supported sites</span></div>
		<div class="fa-stat"><span class="fa-stat-num">30s</span><span class="fa-stat-label">Average import</span></div>
		<div class="fa-stat"><span class="fa-stat-num">100%</span><span class="fa-stat-label">Open source</span></div>
		<div class="fa-stat"><span class="fa-stat-num">0</span><span class="fa-stat-label">Tracking scripts</span></div>
	</section>

	<section class="fa-cta">
		<div class="fa-cta-inner">
			<h2>Ready to take control?</h2>
			<p>Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
			<button class="fa-btn-primary fa-btn-lg">Get Started Free</button>
		</div>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="fa">
	<div class="fa-dash">
		<header class="fa-dash-header">
			<div class="fa-dash-greeting">
				<h1>Good evening.</h1>
				<p>What are we cooking tonight?</p>
			</div>
			<div class="fa-add-recipe">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="fa-btn-primary fa-btn-sm">Save</button>
			</div>
		</header>

		<section class="fa-dash-section">
			<div class="fa-section-head">
				<h2>Tonight's inspiration</h2>
				<button class="fa-btn-text">Shuffle</button>
			</div>
			<div class="fa-hero-recipe">
				<div class="fa-glass-card fa-hero-recipe-card">
					<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} class="fa-hero-img" />
					<div class="fa-hero-overlay">
						<span class="fa-time-pill">{dinnerIdeas[0].total_time_minutes} min</span>
						<h3>{dinnerIdeas[0].title}</h3>
						<p>{dinnerIdeas[0].description}</p>
					</div>
				</div>
			</div>
			<div class="fa-card-grid">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="fa-glass-card fa-recipe-card">
						<div class="fa-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="fa-card-body">
							<h3>{recipe.title}</h3>
							<div class="fa-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="fa-dash-section">
			<div class="fa-section-head">
				<h2>Recently added</h2>
				<a href="/recipes" class="fa-btn-text">View all</a>
			</div>
			<div class="fa-card-grid">
				{#each recentlyAdded as recipe}
					<div class="fa-glass-card fa-recipe-card">
						<div class="fa-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="fa-card-body">
							<h3>{recipe.title}</h3>
							<div class="fa-card-meta">
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
<div class="fa">
	<div class="fa-recipe">
		<div class="fa-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} class="fa-recipe-hero-img" />
			<div class="fa-recipe-hero-glass">
				<div class="fa-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="fa-pill">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="fa-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="fa-recipe-content">
			<div class="fa-glass-card fa-meta-bar">
				<div class="fa-meta-item">
					<span class="fa-meta-label">Prep</span>
					<span class="fa-meta-value">{featuredRecipe.prep_time_minutes} min</span>
				</div>
				<div class="fa-meta-item">
					<span class="fa-meta-label">Cook</span>
					<span class="fa-meta-value">{featuredRecipe.cook_time_minutes} min</span>
				</div>
				<div class="fa-meta-item">
					<span class="fa-meta-label">Total</span>
					<span class="fa-meta-value">{featuredRecipe.total_time_minutes} min</span>
				</div>
				<div class="fa-meta-item">
					<span class="fa-meta-label">Serves</span>
					<span class="fa-meta-value">{featuredRecipe.servings}</span>
				</div>
			</div>

			<p class="fa-recipe-desc">{featuredRecipe.description}</p>

			<div class="fa-recipe-actions">
				<button class="fa-btn-primary fa-btn-sm">Add to Shopping List</button>
				<button class="fa-btn-glass fa-btn-sm">Print</button>
				<button class="fa-btn-glass fa-btn-sm">Edit</button>
				<div class="fa-scale">
					<button class="fa-scale-btn">-</button>
					<span>1x</span>
					<button class="fa-scale-btn">+</button>
				</div>
			</div>

			<div class="fa-recipe-body">
				<aside class="fa-ingredients">
					<div class="fa-glass-card fa-ingredients-card">
						<h2>Ingredients</h2>
						<ul>
							{#each featuredRecipe.ingredients as ing}
								<li>{ing.text}</li>
							{/each}
						</ul>
					</div>
				</aside>
				<div class="fa-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<div class="fa-step-orb">{i + 1}</div>
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

	/* === FRUTIGER AERO THEME === */
	.fa {
		font-family: 'Segoe UI', system-ui, -apple-system, sans-serif;
		color: #1a2b3c;
		background: linear-gradient(180deg, #dceefb 0%, #e8f4f0 30%, #f0f7ed 60%, #fafcf8 100%);
		min-height: 100vh;
	}

	/* GLASS CARD */
	.fa-glass-card {
		background: rgba(255, 255, 255, 0.72);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.85);
		border-radius: 12px;
		box-shadow:
			0 2px 8px rgba(0, 60, 120, 0.08),
			0 1px 2px rgba(0, 60, 120, 0.05),
			inset 0 1px 0 rgba(255, 255, 255, 0.9);
	}

	/* PILL */
	.fa-pill {
		display: inline-block;
		padding: 0.2rem 0.7rem;
		background: linear-gradient(180deg, rgba(255,255,255,0.9) 0%, rgba(220,238,251,0.8) 100%);
		border: 1px solid rgba(0, 120, 212, 0.25);
		border-radius: 20px;
		font-size: 0.75rem;
		color: #0068b8;
		font-weight: 500;
	}

	/* BUTTONS */
	.fa-btn-primary {
		padding: 0.75rem 2rem;
		background: linear-gradient(180deg, #5bb8f5 0%, #0078d4 50%, #006cbe 51%, #005ea6 100%);
		color: white;
		border: 1px solid #004e8c;
		border-radius: 8px;
		font-size: 0.9375rem;
		font-weight: 600;
		cursor: pointer;
		text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.2);
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.35),
			0 2px 4px rgba(0, 78, 140, 0.3);
		transition: all 150ms;
	}
	.fa-btn-primary:hover {
		background: linear-gradient(180deg, #6cc4ff 0%, #0084e8 50%, #0078d4 51%, #006abe 100%);
	}
	.fa-btn-sm { padding: 0.45rem 1.1rem; font-size: 0.8125rem; }
	.fa-btn-lg { padding: 0.9rem 2.5rem; font-size: 1rem; }

	.fa-btn-glass {
		padding: 0.75rem 2rem;
		background: rgba(255, 255, 255, 0.65);
		backdrop-filter: blur(8px);
		color: #1a2b3c;
		border: 1px solid rgba(255, 255, 255, 0.85);
		border-radius: 8px;
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
		text-decoration: none;
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.9),
			0 2px 4px rgba(0, 0, 0, 0.06);
		transition: all 150ms;
	}
	.fa-btn-glass:hover {
		background: rgba(255, 255, 255, 0.85);
	}
	.fa-btn-glass.fa-btn-sm { padding: 0.45rem 1.1rem; font-size: 0.8125rem; }

	.fa-btn-text {
		background: none;
		border: none;
		color: #0078d4;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: none;
		font-weight: 500;
	}
	.fa-btn-text:hover { color: #005ea6; text-decoration: underline; }

	/* SOURCE BADGE */
	.fa-source-badge {
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: #5a8a6a;
		font-weight: 600;
	}

	/* FLOATING ORBS */
	.fa-floating-orb {
		position: absolute;
		border-radius: 50%;
		filter: blur(40px);
		opacity: 0.4;
	}
	.fa-orb-1 {
		width: 200px;
		height: 200px;
		background: radial-gradient(circle, #7bc8ff 0%, transparent 70%);
		top: -40px;
		right: -60px;
	}
	.fa-orb-2 {
		width: 150px;
		height: 150px;
		background: radial-gradient(circle, #a8e6a3 0%, transparent 70%);
		bottom: -30px;
		left: -40px;
	}

	/* === LANDING === */
	.fa-hero {
		position: relative;
		overflow: hidden;
		padding: 5rem 0 4rem;
	}
	.fa-hero-bg {
		position: absolute;
		inset: 0;
		background:
			radial-gradient(ellipse at 20% 50%, rgba(135, 206, 250, 0.3) 0%, transparent 60%),
			radial-gradient(ellipse at 80% 30%, rgba(144, 238, 144, 0.2) 0%, transparent 50%);
	}
	.fa-hero-content {
		position: relative;
		max-width: 1100px;
		margin: 0 auto;
		padding: 0 3rem;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 3rem;
		align-items: center;
	}
	.fa-title {
		font-size: 3.25rem;
		line-height: 1.12;
		margin: 0 0 1.25rem;
		color: #0a1f33;
		font-weight: 700;
	}
	.fa-subtitle {
		font-size: 1.0625rem;
		line-height: 1.7;
		color: #3d5a6e;
		margin: 0 0 2rem;
		max-width: 440px;
	}
	.fa-hero-actions { display: flex; gap: 1rem; }

	.fa-hero-visual { position: relative; }
	.fa-hero-card {
		overflow: hidden;
		padding: 0;
	}
	.fa-hero-card img {
		width: 100%;
		aspect-ratio: 16/10;
		object-fit: cover;
		display: block;
		border-radius: 12px 12px 0 0;
	}
	.fa-hero-card-info {
		padding: 1rem 1.25rem;
	}
	.fa-hero-card-info h3 {
		font-size: 1rem;
		margin: 0 0 0.25rem;
		color: #0a1f33;
		font-weight: 600;
	}
	.fa-hero-card-info span {
		font-size: 0.8125rem;
		color: #5a8a6a;
	}

	/* HOW IT WORKS */
	.fa-how-it-works {
		max-width: 1000px;
		margin: 0 auto;
		padding: 4rem 3rem;
		text-align: center;
	}
	.fa-how-it-works h2 {
		font-size: 2rem;
		color: #0a1f33;
		margin: 0 0 0.5rem;
		font-weight: 700;
	}
	.fa-section-sub {
		color: #5a7a8e;
		font-size: 1rem;
		margin: 0 0 2.5rem;
	}
	.fa-steps {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.5rem;
	}
	.fa-step-card {
		background: rgba(255, 255, 255, 0.6);
		backdrop-filter: blur(12px);
		border: 1px solid rgba(255, 255, 255, 0.8);
		border-radius: 12px;
		padding: 2rem 1.5rem;
		box-shadow: 0 2px 8px rgba(0, 60, 120, 0.06);
		text-align: center;
	}
	.fa-step-icon {
		display: flex;
		justify-content: center;
		margin-bottom: 1rem;
	}
	.fa-step-num {
		width: 44px;
		height: 44px;
		border-radius: 50%;
		background: linear-gradient(180deg, #5bb8f5 0%, #0078d4 100%);
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 1.125rem;
		font-weight: 700;
		text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.15);
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.35),
			0 2px 6px rgba(0, 78, 140, 0.3);
	}
	.fa-step-card h3 {
		font-size: 1.125rem;
		color: #0a1f33;
		margin: 0 0 0.5rem;
		font-weight: 600;
	}
	.fa-step-card p {
		color: #5a7a8e;
		line-height: 1.6;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* SHOWCASE */
	.fa-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 3rem;
		display: grid;
		grid-template-columns: 1fr 1.3fr;
		gap: 3rem;
		align-items: center;
	}
	.fa-showcase-text h2 {
		font-size: 1.875rem;
		line-height: 1.25;
		color: #0a1f33;
		margin: 0.75rem 0 1rem;
		font-weight: 700;
	}
	.fa-showcase-text p {
		color: #5a7a8e;
		line-height: 1.7;
		margin: 0;
	}
	.fa-showcase-cards {
		display: flex;
		flex-direction: column;
		gap: 0.875rem;
	}
	.fa-showcase-card {
		display: flex;
		gap: 1rem;
		padding: 0.5rem;
		overflow: hidden;
		transition: transform 200ms, box-shadow 200ms;
	}
	.fa-showcase-card:hover {
		transform: translateX(4px);
		box-shadow: 0 4px 16px rgba(0, 60, 120, 0.12);
	}
	.fa-showcase-card img {
		width: 110px;
		height: 75px;
		object-fit: cover;
		border-radius: 8px;
		flex-shrink: 0;
	}
	.fa-showcase-card-info {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 0.25rem 0;
	}
	.fa-showcase-card-info h4 {
		font-size: 0.9375rem;
		margin: 0.25rem 0 0;
		color: #0a1f33;
		font-weight: 600;
		line-height: 1.35;
	}

	/* FEATURES */
	.fa-features {
		max-width: 1000px;
		margin: 0 auto;
		padding: 4rem 3rem;
		text-align: center;
	}
	.fa-features h2 {
		font-size: 2rem;
		color: #0a1f33;
		margin: 0 0 0.5rem;
		font-weight: 700;
	}
	.fa-feature-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.25rem;
	}
	.fa-feature-card {
		background: rgba(255, 255, 255, 0.55);
		backdrop-filter: blur(10px);
		border: 1px solid rgba(255, 255, 255, 0.75);
		border-radius: 12px;
		padding: 1.5rem;
		text-align: left;
		box-shadow: 0 1px 4px rgba(0, 60, 120, 0.05);
		transition: transform 200ms, box-shadow 200ms;
	}
	.fa-feature-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(0, 60, 120, 0.1);
	}
	.fa-feature-icon {
		font-size: 1.75rem;
		margin-bottom: 0.5rem;
	}
	.fa-feature-card h3 {
		font-size: 1rem;
		color: #0a1f33;
		margin: 0 0 0.4rem;
		font-weight: 600;
	}
	.fa-feature-card p {
		color: #5a7a8e;
		line-height: 1.6;
		margin: 0;
		font-size: 0.875rem;
	}

	/* STATS */
	.fa-stats-bar {
		display: flex;
		justify-content: center;
		gap: 4rem;
		padding: 2.5rem 2rem;
		background: rgba(255, 255, 255, 0.45);
		backdrop-filter: blur(12px);
		border-top: 1px solid rgba(255, 255, 255, 0.7);
		border-bottom: 1px solid rgba(255, 255, 255, 0.7);
	}
	.fa-stat { text-align: center; }
	.fa-stat-num {
		display: block;
		font-size: 2.25rem;
		color: #0078d4;
		font-weight: 700;
		line-height: 1;
		margin-bottom: 0.375rem;
	}
	.fa-stat-label {
		font-size: 0.8125rem;
		color: #5a7a8e;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		font-weight: 500;
	}

	/* CTA */
	.fa-cta {
		padding: 4rem 2rem;
	}
	.fa-cta-inner {
		max-width: 600px;
		margin: 0 auto;
		text-align: center;
		background: rgba(255, 255, 255, 0.6);
		backdrop-filter: blur(16px);
		border: 1px solid rgba(255, 255, 255, 0.85);
		border-radius: 16px;
		padding: 3rem;
		box-shadow: 0 4px 16px rgba(0, 60, 120, 0.08);
	}
	.fa-cta-inner h2 {
		font-size: 1.875rem;
		color: #0a1f33;
		margin: 0 0 0.75rem;
		font-weight: 700;
	}
	.fa-cta-inner p {
		color: #5a7a8e;
		margin: 0 0 1.75rem;
		font-size: 1rem;
	}

	/* === DASHBOARD === */
	.fa-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.fa-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 2.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 1px solid rgba(0, 120, 212, 0.12);
	}
	.fa-dash-greeting h1 {
		font-size: 2rem;
		margin: 0;
		color: #0a1f33;
		font-weight: 700;
	}
	.fa-dash-greeting p {
		margin: 0.25rem 0 0;
		color: #5a7a8e;
	}
	.fa-add-recipe { display: flex; gap: 0.5rem; }
	.fa-add-recipe input {
		padding: 0.5rem 1rem;
		background: rgba(255, 255, 255, 0.7);
		backdrop-filter: blur(8px);
		border: 1px solid rgba(0, 120, 212, 0.2);
		border-radius: 8px;
		font-size: 0.875rem;
		width: 320px;
		color: #1a2b3c;
		box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.04);
	}
	.fa-add-recipe input::placeholder { color: #8ca8b8; }
	.fa-add-recipe input:focus {
		outline: none;
		border-color: #0078d4;
		box-shadow: 0 0 0 3px rgba(0, 120, 212, 0.15), inset 0 1px 2px rgba(0, 0, 0, 0.04);
	}

	.fa-dash-section { margin-bottom: 3rem; }
	.fa-section-head {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1.25rem;
	}
	.fa-section-head h2 {
		font-size: 1.375rem;
		margin: 0;
		color: #0a1f33;
		font-weight: 600;
	}

	/* HERO RECIPE */
	.fa-hero-recipe { margin-bottom: 1.5rem; }
	.fa-hero-recipe-card {
		position: relative;
		overflow: hidden;
		padding: 0;
	}
	.fa-hero-img {
		width: 100%;
		aspect-ratio: 21/9;
		object-fit: cover;
		display: block;
		border-radius: 12px 12px 0 0;
	}
	.fa-hero-overlay {
		padding: 1.5rem;
		background: linear-gradient(transparent, rgba(10, 31, 51, 0.6));
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		border-radius: 0 0 12px 12px;
		color: white;
	}
	.fa-time-pill {
		display: inline-block;
		padding: 0.2rem 0.6rem;
		background: rgba(255, 255, 255, 0.25);
		backdrop-filter: blur(8px);
		border-radius: 20px;
		font-size: 0.75rem;
		margin-bottom: 0.5rem;
		font-weight: 500;
	}
	.fa-hero-overlay h3 {
		font-size: 1.5rem;
		margin: 0 0 0.375rem;
		font-weight: 600;
	}
	.fa-hero-overlay p {
		margin: 0;
		font-size: 0.875rem;
		opacity: 0.85;
		max-width: 500px;
	}

	/* CARD GRID */
	.fa-card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1.25rem;
	}
	.fa-recipe-card {
		overflow: hidden;
		padding: 0;
		cursor: pointer;
		transition: transform 200ms, box-shadow 200ms;
	}
	.fa-recipe-card:hover {
		transform: translateY(-3px);
		box-shadow: 0 6px 20px rgba(0, 60, 120, 0.12);
	}
	.fa-card-img {
		overflow: hidden;
	}
	.fa-card-img img {
		width: 100%;
		aspect-ratio: 16/10;
		object-fit: cover;
		display: block;
		border-radius: 12px 12px 0 0;
		transition: transform 300ms;
	}
	.fa-recipe-card:hover .fa-card-img img {
		transform: scale(1.03);
	}
	.fa-card-body {
		padding: 0.875rem 1rem;
	}
	.fa-card-body h3 {
		font-size: 0.9375rem;
		margin: 0 0 0.35rem;
		color: #0a1f33;
		font-weight: 600;
		line-height: 1.35;
	}
	.fa-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.75rem;
		color: #5a8a6a;
	}

	/* === RECIPE DETAIL === */
	.fa-recipe-hero {
		position: relative;
		height: 55vh;
		min-height: 380px;
		overflow: hidden;
	}
	.fa-recipe-hero-img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.fa-recipe-hero-glass {
		position: absolute;
		bottom: 2rem;
		left: 50%;
		transform: translateX(-50%);
		width: 90%;
		max-width: 800px;
		background: rgba(255, 255, 255, 0.75);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border: 1px solid rgba(255, 255, 255, 0.9);
		border-radius: 16px;
		padding: 2rem 2.5rem;
		box-shadow: 0 8px 32px rgba(0, 30, 60, 0.15);
	}
	.fa-recipe-hero-glass h1 {
		font-size: 2.25rem;
		margin: 0.75rem 0 0.5rem;
		color: #0a1f33;
		font-weight: 700;
		line-height: 1.15;
	}
	.fa-recipe-tags { display: flex; gap: 0.5rem; }
	.fa-recipe-source {
		font-size: 0.875rem;
		color: #5a8a6a;
		margin: 0;
	}

	.fa-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.fa-meta-bar {
		display: flex;
		gap: 2.5rem;
		padding: 1.25rem 2rem;
		margin-bottom: 2rem;
	}
	.fa-meta-item { text-align: center; }
	.fa-meta-label {
		display: block;
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #5a7a8e;
		margin-bottom: 0.2rem;
		font-weight: 500;
	}
	.fa-meta-value {
		font-size: 1.125rem;
		color: #0a1f33;
		font-weight: 600;
	}

	.fa-recipe-desc {
		font-size: 1.0625rem;
		line-height: 1.7;
		color: #3d5a6e;
		margin: 0 0 2rem;
	}

	.fa-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 2.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 1px solid rgba(0, 120, 212, 0.1);
	}
	.fa-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.875rem;
		color: #3d5a6e;
	}
	.fa-scale-btn {
		width: 28px;
		height: 28px;
		background: rgba(255, 255, 255, 0.6);
		border: 1px solid rgba(0, 120, 212, 0.2);
		border-radius: 6px;
		cursor: pointer;
		font-size: 1rem;
		color: #0078d4;
		display: flex;
		align-items: center;
		justify-content: center;
		box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.8);
	}

	.fa-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 2.5rem;
	}
	.fa-ingredients-card {
		padding: 1.5rem;
		position: sticky;
		top: 60px;
	}
	.fa-ingredients-card h2 {
		font-size: 1.125rem;
		margin: 0 0 1rem;
		color: #0a1f33;
		font-weight: 600;
	}
	.fa-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.fa-ingredients li {
		padding: 0.625rem 0;
		border-bottom: 1px solid rgba(0, 120, 212, 0.08);
		font-size: 0.9375rem;
		color: #1a2b3c;
		line-height: 1.45;
	}
	.fa-instructions h2 {
		font-size: 1.125rem;
		margin: 0 0 1.25rem;
		color: #0a1f33;
		font-weight: 600;
	}
	.fa-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.fa-instructions li {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
		align-items: flex-start;
	}
	.fa-step-orb {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: linear-gradient(180deg, #5bb8f5 0%, #0078d4 100%);
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.8125rem;
		font-weight: 700;
		text-shadow: 0 -1px 0 rgba(0, 0, 0, 0.15);
		box-shadow:
			inset 0 1px 0 rgba(255, 255, 255, 0.35),
			0 2px 4px rgba(0, 78, 140, 0.25);
		margin-top: 2px;
	}
	.fa-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.7;
		color: #1a2b3c;
	}
</style>
