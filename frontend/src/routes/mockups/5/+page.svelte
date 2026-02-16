<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 5: Scrapbook</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="sb">
	<header class="sb-hero">
		<div class="sb-hero-inner">
			<div class="sb-tape sb-tape-tl"></div>
			<h1 class="sb-title">My Recipe<br/>Collection</h1>
			<p class="sb-subtitle">Save recipes from all over the internet into your own personal cookbook. Like a recipe binder, but digital and way less sticky.</p>
			<div class="sb-hero-actions">
				<button class="sb-btn-primary">Start Collecting</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="sb-btn-ghost">View on GitHub</a>
			</div>
		</div>
		<div class="sb-hero-photo">
			<div class="sb-photo-frame">
				<img src={recipes[0].image_url} alt="Spaghetti Carbonara" />
				<div class="sb-tape sb-tape-tr"></div>
				<div class="sb-tape sb-tape-bl"></div>
			</div>
		</div>
	</header>

	<section class="sb-how-it-works">
		<h2 class="sb-section-title"><span class="sb-underline-squiggle">How it works</span></h2>
		<div class="sb-steps">
			<div class="sb-step-card">
				<div class="sb-step-num">1</div>
				<h3>Find a recipe</h3>
				<p>Spot something delicious online? Paste the URL or use the browser extension to clip it in one click.</p>
			</div>
			<div class="sb-step-card">
				<div class="sb-step-num">2</div>
				<h3>It goes in the book</h3>
				<p>We pull out the ingredients, instructions, and photos. Tag it, file it, make it yours.</p>
			</div>
			<div class="sb-step-card">
				<div class="sb-step-num">3</div>
				<h3>Cook & enjoy</h3>
				<p>Scale for any crowd, check nutrition, print a clean card. Your recipes, your way, forever.</p>
			</div>
		</div>
	</section>

	<section class="sb-showcase">
		<div class="sb-showcase-text">
			<p class="sb-label-sticker">Your collection</p>
			<h2>Recipes from everywhere, all in one cozy place.</h2>
			<p>Bon Appetit, NYT Cooking, food blogs, grandma's email — they all belong here together.</p>
		</div>
		<div class="sb-showcase-photos">
			{#each recipes.slice(0, 3) as recipe, i}
				<div class="sb-showcase-item" style="transform: rotate({i === 0 ? -3 : i === 1 ? 2 : -1}deg)">
					<div class="sb-tape sb-tape-top"></div>
					<img src={recipe.image_url} alt={recipe.title} />
					<p class="sb-photo-caption">{recipe.title}</p>
				</div>
			{/each}
		</div>
	</section>

	<section class="sb-features">
		<h2 class="sb-section-title"><span class="sb-underline-squiggle">What's inside</span></h2>
		<div class="sb-feature-grid">
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#9986;</div>
				<h3>Clip from any site</h3>
				<p>Paste a URL or use the browser extension. Ingredients, steps, and images — all captured.</p>
			</div>
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#9878;</div>
				<h3>Scale it up or down</h3>
				<p>Cooking for 2 or 12? Adjust quantities with smart fraction handling.</p>
			</div>
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#9733;</div>
				<h3>Nutrition facts</h3>
				<p>Per-recipe and per-serving breakdowns. Calories, macros, micronutrients.</p>
			</div>
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#128722;</div>
				<h3>Shopping lists</h3>
				<p>Generate lists from any recipe. Items grouped by category, quantities combined.</p>
			</div>
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#128269;</div>
				<h3>Find connections</h3>
				<p>Discover shared ingredients. Compare recipes side by side. Browse by source.</p>
			</div>
			<div class="sb-feature-card">
				<div class="sb-feature-doodle">&#128274;</div>
				<h3>Own your data</h3>
				<p>Self-hosted, open source, AGPL. Your recipes never leave your server.</p>
			</div>
		</div>
	</section>

	<section class="sb-stats-bar">
		<div class="sb-stat"><span class="sb-stat-num">200+</span><span class="sb-stat-text">Supported sites</span></div>
		<div class="sb-stat"><span class="sb-stat-num">30s</span><span class="sb-stat-text">Average import</span></div>
		<div class="sb-stat"><span class="sb-stat-num">100%</span><span class="sb-stat-text">Open source</span></div>
		<div class="sb-stat"><span class="sb-stat-num">0</span><span class="sb-stat-text">Tracking scripts</span></div>
	</section>

	<section class="sb-cta">
		<div class="sb-cta-card">
			<h2>Ready to start your collection?</h2>
			<p>Deploy in minutes. Your recipes stay on your server, forever.</p>
			<button class="sb-btn-primary">Get Started</button>
		</div>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="sb">
	<div class="sb-dash">
		<header class="sb-dash-header">
			<div class="sb-dash-greeting">
				<h1>Welcome back!</h1>
				<p class="sb-dash-sub">What should we make tonight?</p>
			</div>
			<div class="sb-add-recipe">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="sb-btn-primary sb-btn-sm">Save</button>
			</div>
		</header>

		<section class="sb-dash-section">
			<h2 class="sb-section-title"><span class="sb-underline-squiggle">Tonight's inspiration</span></h2>
			<div class="sb-hero-recipe">
				<div class="sb-hero-recipe-photo">
					<div class="sb-tape sb-tape-tl"></div>
					<div class="sb-tape sb-tape-tr"></div>
					<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} />
				</div>
				<div class="sb-hero-recipe-info">
					<div class="sb-sticker-tag">{dinnerIdeas[0].total_time_minutes} min</div>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
					<span class="sb-source-note">from {dinnerIdeas[0].source_domain}</span>
				</div>
			</div>

			<div class="sb-recipe-grid">
				{#each dinnerIdeas.slice(1) as recipe, i}
					<div class="sb-recipe-card" style="transform: rotate({i === 0 ? -1 : i === 1 ? 0.5 : -0.5}deg)">
						<div class="sb-tape sb-tape-top"></div>
						<div class="sb-card-photo">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="sb-card-info">
							<h3>{recipe.title}</h3>
							<div class="sb-card-meta">
								{#if recipe.total_time_minutes}<span>{recipe.total_time_minutes} min</span>{/if}
								<span>{recipe.source_domain}</span>
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="sb-dash-section">
			<h2 class="sb-section-title"><span class="sb-underline-squiggle">Recently added</span></h2>
			<div class="sb-recipe-grid">
				{#each recentlyAdded as recipe, i}
					<div class="sb-recipe-card" style="transform: rotate({i === 0 ? 1 : i === 1 ? -0.5 : i === 2 ? 0.5 : -1}deg)">
						<div class="sb-tape sb-tape-top"></div>
						<div class="sb-card-photo">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="sb-card-info">
							<h3>{recipe.title}</h3>
							<div class="sb-card-meta">
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
<div class="sb">
	<div class="sb-recipe">
		<div class="sb-recipe-top">
			<div class="sb-recipe-photo-wrap">
				<div class="sb-tape sb-tape-tl"></div>
				<div class="sb-tape sb-tape-tr"></div>
				<div class="sb-tape sb-tape-bl"></div>
				<div class="sb-tape sb-tape-br"></div>
				<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			</div>
			<div class="sb-recipe-header">
				<div class="sb-recipe-tags">
					{#each featuredRecipe.tags as tag}
						<span class="sb-sticker-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="sb-source-note">from {featuredRecipe.source_domain}</p>
				<p class="sb-recipe-desc">{featuredRecipe.description}</p>

				<div class="sb-recipe-meta-bar">
					<div class="sb-meta-item">
						<span class="sb-meta-label">Prep</span>
						<span class="sb-meta-value">{featuredRecipe.prep_time_minutes} min</span>
					</div>
					<div class="sb-meta-item">
						<span class="sb-meta-label">Cook</span>
						<span class="sb-meta-value">{featuredRecipe.cook_time_minutes} min</span>
					</div>
					<div class="sb-meta-item">
						<span class="sb-meta-label">Total</span>
						<span class="sb-meta-value">{featuredRecipe.total_time_minutes} min</span>
					</div>
					<div class="sb-meta-item">
						<span class="sb-meta-label">Serves</span>
						<span class="sb-meta-value">{featuredRecipe.servings}</span>
					</div>
				</div>

				<div class="sb-recipe-actions">
					<button class="sb-btn-primary sb-btn-sm">Add to Shopping List</button>
					<button class="sb-btn-ghost sb-btn-sm">Print</button>
					<button class="sb-btn-ghost sb-btn-sm">Edit</button>
					<div class="sb-scale">
						<button class="sb-scale-btn">-</button>
						<span>1x</span>
						<button class="sb-scale-btn">+</button>
					</div>
				</div>
			</div>
		</div>

		<div class="sb-recipe-body">
			<aside class="sb-ingredients">
				<h2 class="sb-section-title"><span class="sb-underline-squiggle">Ingredients</span></h2>
				<ul>
					{#each featuredRecipe.ingredients as ing}
						<li>
							<span class="sb-checkbox"></span>
							{ing.text}
						</li>
					{/each}
				</ul>
			</aside>
			<div class="sb-instructions">
				<h2 class="sb-section-title"><span class="sb-underline-squiggle">Instructions</span></h2>
				<ol>
					{#each featuredRecipe.instructions as step, i}
						<li>
							<span class="sb-step-circle">{i + 1}</span>
							<p>{step.text}</p>
						</li>
					{/each}
				</ol>
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

	/* === SCRAPBOOK THEME === */
	@import url('https://fonts.googleapis.com/css2?family=Caveat:wght@400;500;600;700&family=Patrick+Hand&display=swap');

	.sb {
		font-family: 'Patrick Hand', cursive;
		color: #3d2c1e;
		background: #faf3e0;
		background-image:
			repeating-linear-gradient(
				0deg,
				transparent,
				transparent 31px,
				#e8d9c0 31px,
				#e8d9c0 32px
			);
		background-size: 100% 32px;
		background-position: 0 8px;
		min-height: 100vh;
	}

	/* TAPE */
	.sb-tape {
		position: absolute;
		width: 60px;
		height: 24px;
		background: rgba(255, 228, 150, 0.6);
		z-index: 2;
		border: 1px solid rgba(200, 180, 100, 0.3);
	}
	.sb-tape-tl { top: -8px; left: 20px; transform: rotate(-8deg); }
	.sb-tape-tr { top: -8px; right: 20px; transform: rotate(6deg); }
	.sb-tape-bl { bottom: -8px; left: 20px; transform: rotate(5deg); }
	.sb-tape-br { bottom: -8px; right: 20px; transform: rotate(-4deg); }
	.sb-tape-top { top: -10px; left: 50%; margin-left: -30px; transform: rotate(-2deg); }

	/* SECTION TITLES */
	.sb-section-title {
		font-family: 'Caveat', cursive;
		font-size: 2rem;
		color: #3d2c1e;
		margin: 0 0 1.5rem;
		font-weight: 600;
	}
	.sb-underline-squiggle {
		background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='8' viewBox='0 0 100 8'%3E%3Cpath d='M0 4 Q12.5 0 25 4 T50 4 T75 4 T100 4' fill='none' stroke='%23c0392b' stroke-width='2' opacity='0.5'/%3E%3C/svg%3E");
		background-repeat: repeat-x;
		background-position: bottom;
		background-size: 100px 8px;
		padding-bottom: 6px;
	}

	/* LABEL STICKER */
	.sb-label-sticker {
		display: inline-block;
		background: #fce4b8;
		color: #8b6914;
		padding: 0.25rem 0.75rem;
		border-radius: 2px;
		font-size: 0.875rem;
		font-family: 'Patrick Hand', cursive;
		transform: rotate(-1deg);
		margin-bottom: 0.75rem;
		border: 1px dashed #d4a843;
	}

	/* STICKER TAG */
	.sb-sticker-tag {
		display: inline-block;
		background: #fce4b8;
		color: #8b6914;
		padding: 0.2rem 0.6rem;
		border-radius: 2px;
		font-size: 0.8125rem;
		font-family: 'Patrick Hand', cursive;
		border: 1px dashed #d4a843;
	}

	/* BUTTONS */
	.sb-btn-primary {
		padding: 0.75rem 1.75rem;
		background: #c0392b;
		color: #fff;
		border: none;
		border-radius: 3px;
		font-family: 'Caveat', cursive;
		font-size: 1.25rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 200ms;
		box-shadow: 2px 3px 0 #8e2a1f;
	}
	.sb-btn-primary:hover {
		background: #a93226;
		transform: translate(1px, 1px);
		box-shadow: 1px 2px 0 #8e2a1f;
	}
	.sb-btn-sm { padding: 0.4rem 1rem; font-size: 1.05rem; }

	.sb-btn-ghost {
		padding: 0.75rem 1.75rem;
		background: none;
		color: #3d2c1e;
		border: 2px dashed #c4a67a;
		border-radius: 3px;
		font-family: 'Caveat', cursive;
		font-size: 1.25rem;
		font-weight: 600;
		cursor: pointer;
		text-decoration: none;
		transition: all 200ms;
	}
	.sb-btn-ghost:hover {
		border-color: #3d2c1e;
		background: rgba(61, 44, 30, 0.05);
	}
	.sb-btn-ghost.sb-btn-sm { padding: 0.4rem 1rem; font-size: 1.05rem; }

	/* SOURCE NOTE */
	.sb-source-note {
		font-size: 0.875rem;
		color: #9a8468;
		font-style: italic;
		margin: 0;
	}

	/* === LANDING === */
	.sb-hero {
		display: grid;
		grid-template-columns: 1fr 1fr;
		max-width: 1100px;
		margin: 0 auto;
		padding: 4rem 3rem;
		gap: 3rem;
		align-items: center;
	}
	.sb-hero-inner {
		position: relative;
	}
	.sb-title {
		font-family: 'Caveat', cursive;
		font-size: 4rem;
		line-height: 1.05;
		margin: 0 0 1.25rem;
		color: #3d2c1e;
		font-weight: 700;
	}
	.sb-subtitle {
		font-size: 1.2rem;
		line-height: 1.6;
		color: #6b5541;
		margin: 0 0 2rem;
	}
	.sb-hero-actions { display: flex; gap: 1rem; align-items: center; }

	.sb-hero-photo { position: relative; }
	.sb-photo-frame {
		position: relative;
		background: white;
		padding: 12px 12px 40px;
		box-shadow: 3px 4px 12px rgba(61, 44, 30, 0.15);
		transform: rotate(2deg);
	}
	.sb-photo-frame img {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
		display: block;
	}

	/* HOW IT WORKS */
	.sb-how-it-works {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3rem 3rem 4rem;
		text-align: center;
	}
	.sb-steps {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2rem;
	}
	.sb-step-card {
		background: white;
		padding: 1.75rem 1.5rem;
		border-radius: 4px;
		box-shadow: 2px 3px 8px rgba(61, 44, 30, 0.1);
		position: relative;
		transform: rotate(-0.5deg);
	}
	.sb-step-card:nth-child(2) { transform: rotate(0.5deg); }
	.sb-step-card:nth-child(3) { transform: rotate(-0.3deg); }
	.sb-step-num {
		width: 40px;
		height: 40px;
		border-radius: 50%;
		background: #c0392b;
		color: white;
		font-family: 'Caveat', cursive;
		font-size: 1.5rem;
		font-weight: 700;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		margin-bottom: 0.75rem;
		box-shadow: 2px 2px 0 #8e2a1f;
	}
	.sb-step-card h3 {
		font-family: 'Caveat', cursive;
		font-size: 1.5rem;
		color: #3d2c1e;
		margin: 0 0 0.5rem;
		font-weight: 600;
	}
	.sb-step-card p {
		color: #6b5541;
		line-height: 1.5;
		margin: 0;
		font-size: 1rem;
	}

	/* SHOWCASE */
	.sb-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 3rem;
	}
	.sb-showcase-text {
		max-width: 600px;
		margin: 0 auto 2.5rem;
		text-align: center;
	}
	.sb-showcase-text h2 {
		font-family: 'Caveat', cursive;
		font-size: 2rem;
		color: #3d2c1e;
		margin: 0 0 0.75rem;
		font-weight: 600;
	}
	.sb-showcase-text p {
		color: #6b5541;
		line-height: 1.5;
		margin: 0;
	}
	.sb-showcase-photos {
		display: flex;
		justify-content: center;
		gap: 2rem;
		flex-wrap: wrap;
	}
	.sb-showcase-item {
		background: white;
		padding: 10px 10px 32px;
		box-shadow: 2px 3px 10px rgba(61, 44, 30, 0.12);
		width: 260px;
		position: relative;
		transition: transform 300ms;
	}
	.sb-showcase-item:hover {
		z-index: 2;
		transform: rotate(0deg) scale(1.04) !important;
	}
	.sb-showcase-item img {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
		display: block;
	}
	.sb-photo-caption {
		font-family: 'Caveat', cursive;
		font-size: 1rem;
		color: #6b5541;
		margin: 8px 0 0;
		text-align: center;
	}

	/* FEATURES */
	.sb-features {
		max-width: 1000px;
		margin: 0 auto;
		padding: 3rem;
		text-align: center;
	}
	.sb-feature-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.5rem;
	}
	.sb-feature-card {
		background: white;
		padding: 1.5rem;
		border-radius: 4px;
		box-shadow: 2px 3px 8px rgba(61, 44, 30, 0.1);
		text-align: left;
	}
	.sb-feature-doodle {
		font-size: 1.75rem;
		margin-bottom: 0.5rem;
	}
	.sb-feature-card h3 {
		font-family: 'Caveat', cursive;
		font-size: 1.4rem;
		color: #3d2c1e;
		margin: 0 0 0.4rem;
		font-weight: 600;
	}
	.sb-feature-card p {
		color: #6b5541;
		line-height: 1.5;
		margin: 0;
		font-size: 0.95rem;
	}

	/* STATS */
	.sb-stats-bar {
		display: flex;
		justify-content: center;
		gap: 3rem;
		padding: 2.5rem 2rem;
		max-width: 800px;
		margin: 0 auto;
		border-top: 2px dashed #c4a67a;
		border-bottom: 2px dashed #c4a67a;
	}
	.sb-stat { text-align: center; }
	.sb-stat-num {
		display: block;
		font-family: 'Caveat', cursive;
		font-size: 2.5rem;
		color: #c0392b;
		font-weight: 700;
		line-height: 1;
		margin-bottom: 0.25rem;
	}
	.sb-stat-text {
		font-size: 0.9rem;
		color: #9a8468;
	}

	/* CTA */
	.sb-cta {
		padding: 3rem;
		display: flex;
		justify-content: center;
	}
	.sb-cta-card {
		background: white;
		padding: 3rem 4rem;
		text-align: center;
		box-shadow: 3px 4px 12px rgba(61, 44, 30, 0.12);
		transform: rotate(-0.5deg);
		position: relative;
		border-radius: 4px;
	}
	.sb-cta-card h2 {
		font-family: 'Caveat', cursive;
		font-size: 2rem;
		color: #3d2c1e;
		margin: 0 0 0.75rem;
		font-weight: 700;
	}
	.sb-cta-card p {
		color: #6b5541;
		margin: 0 0 1.5rem;
	}

	/* === DASHBOARD === */
	.sb-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 2rem;
	}
	.sb-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 2.5rem;
		padding-bottom: 1.5rem;
		border-bottom: 2px dashed #c4a67a;
	}
	.sb-dash-greeting h1 {
		font-family: 'Caveat', cursive;
		font-size: 2.5rem;
		margin: 0;
		color: #3d2c1e;
		font-weight: 700;
	}
	.sb-dash-sub {
		margin: 0;
		color: #9a8468;
		font-size: 1.1rem;
	}
	.sb-add-recipe { display: flex; gap: 0.5rem; }
	.sb-add-recipe input {
		padding: 0.5rem 1rem;
		border: 2px dashed #c4a67a;
		border-radius: 3px;
		font-family: 'Patrick Hand', cursive;
		font-size: 1rem;
		width: 300px;
		background: white;
		color: #3d2c1e;
	}
	.sb-add-recipe input::placeholder { color: #c4a67a; }
	.sb-add-recipe input:focus { outline: none; border-color: #3d2c1e; border-style: solid; }

	.sb-dash-section { margin-bottom: 3rem; }

	/* HERO RECIPE */
	.sb-hero-recipe {
		display: grid;
		grid-template-columns: 1.2fr 1fr;
		gap: 2.5rem;
		background: white;
		padding: 1.5rem;
		box-shadow: 3px 4px 12px rgba(61, 44, 30, 0.1);
		border-radius: 4px;
		margin-bottom: 2rem;
		transform: rotate(-0.3deg);
	}
	.sb-hero-recipe-photo {
		position: relative;
		border-radius: 2px;
		overflow: hidden;
	}
	.sb-hero-recipe-photo img {
		width: 100%;
		aspect-ratio: 16/10;
		object-fit: cover;
		display: block;
	}
	.sb-hero-recipe-info {
		display: flex;
		flex-direction: column;
		justify-content: center;
		padding: 0.5rem 0;
	}
	.sb-hero-recipe-info h3 {
		font-family: 'Caveat', cursive;
		font-size: 1.75rem;
		color: #3d2c1e;
		margin: 0.75rem 0 0.5rem;
		font-weight: 700;
		line-height: 1.2;
	}
	.sb-hero-recipe-info p {
		color: #6b5541;
		line-height: 1.5;
		margin: 0 0 0.75rem;
		font-size: 1rem;
	}

	/* CARD GRID */
	.sb-recipe-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: 1.5rem;
	}
	.sb-recipe-card {
		background: white;
		padding: 10px 10px 12px;
		box-shadow: 2px 3px 8px rgba(61, 44, 30, 0.1);
		cursor: pointer;
		position: relative;
		transition: transform 200ms;
		border-radius: 2px;
	}
	.sb-recipe-card:hover {
		transform: rotate(0deg) scale(1.02) !important;
		z-index: 2;
	}
	.sb-card-photo {
		overflow: hidden;
		border-radius: 2px;
	}
	.sb-card-photo img {
		width: 100%;
		aspect-ratio: 16/10;
		object-fit: cover;
		display: block;
	}
	.sb-card-info {
		padding: 0.75rem 0.25rem 0.25rem;
	}
	.sb-card-info h3 {
		font-family: 'Caveat', cursive;
		font-size: 1.2rem;
		color: #3d2c1e;
		margin: 0 0 0.35rem;
		font-weight: 600;
		line-height: 1.25;
	}
	.sb-card-meta {
		display: flex;
		gap: 0.75rem;
		font-size: 0.8rem;
		color: #9a8468;
	}

	/* === RECIPE DETAIL === */
	.sb-recipe {
		max-width: 1000px;
		margin: 0 auto;
		padding: 2rem;
	}
	.sb-recipe-top {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2.5rem;
		margin-bottom: 3rem;
	}
	.sb-recipe-photo-wrap {
		position: relative;
		background: white;
		padding: 12px;
		box-shadow: 3px 4px 12px rgba(61, 44, 30, 0.15);
		transform: rotate(-1deg);
	}
	.sb-recipe-photo-wrap img {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
		display: block;
	}
	.sb-recipe-header {
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.sb-recipe-tags {
		display: flex;
		gap: 0.5rem;
		margin-bottom: 0.75rem;
	}
	.sb-recipe-header h1 {
		font-family: 'Caveat', cursive;
		font-size: 2.5rem;
		line-height: 1.1;
		margin: 0 0 0.5rem;
		color: #3d2c1e;
		font-weight: 700;
	}
	.sb-recipe-desc {
		color: #6b5541;
		line-height: 1.5;
		margin: 0.75rem 0 1.25rem;
		font-size: 1.05rem;
	}

	.sb-recipe-meta-bar {
		display: flex;
		gap: 1.5rem;
		margin-bottom: 1.25rem;
		padding: 0.75rem 0;
		border-top: 2px dashed #c4a67a;
		border-bottom: 2px dashed #c4a67a;
	}
	.sb-meta-item { text-align: center; }
	.sb-meta-label {
		display: block;
		font-size: 0.75rem;
		color: #9a8468;
		text-transform: uppercase;
		letter-spacing: 0.05em;
		margin-bottom: 0.15rem;
	}
	.sb-meta-value {
		font-family: 'Caveat', cursive;
		font-size: 1.25rem;
		color: #3d2c1e;
		font-weight: 600;
	}

	.sb-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		flex-wrap: wrap;
	}
	.sb-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 1rem;
		color: #6b5541;
	}
	.sb-scale-btn {
		width: 28px;
		height: 28px;
		border: 2px dashed #c4a67a;
		border-radius: 3px;
		background: white;
		cursor: pointer;
		font-size: 1rem;
		color: #3d2c1e;
		font-family: 'Patrick Hand', cursive;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	/* RECIPE BODY */
	.sb-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 3rem;
	}
	.sb-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.sb-ingredients li {
		display: flex;
		align-items: flex-start;
		gap: 0.625rem;
		padding: 0.6rem 0;
		border-bottom: 1px dashed #d4c4a0;
		font-size: 1rem;
		color: #3d2c1e;
		line-height: 1.4;
	}
	.sb-checkbox {
		flex-shrink: 0;
		width: 18px;
		height: 18px;
		border: 2px solid #c4a67a;
		border-radius: 2px;
		margin-top: 2px;
	}
	.sb-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.sb-instructions li {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
		align-items: flex-start;
	}
	.sb-instructions .sb-step-circle {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: #c0392b;
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: 'Caveat', cursive;
		font-size: 1.1rem;
		font-weight: 700;
		box-shadow: 2px 2px 0 #8e2a1f;
		margin-top: 2px;
	}
	.sb-instructions p {
		margin: 0;
		font-size: 1rem;
		line-height: 1.6;
		color: #3d2c1e;
	}
</style>
