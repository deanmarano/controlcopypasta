<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 2: Dark Kitchen</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING PAGE -->
<div class="dk">
	<header class="dk-hero">
		<div class="dk-hero-bg">
			<img src={recipes[0].image_url} alt="" />
			<div class="dk-hero-scrim"></div>
		</div>
		<div class="dk-hero-content">
			<p class="dk-eyebrow">Open source &middot; Self-hosted &middot; No tracking</p>
			<h1>Save recipes.<br />Cook better.</h1>
			<p class="dk-hero-sub">Clip recipes from any website. Scale ingredients, track nutrition, build shopping lists. Your data lives on your server.</p>
			<div class="dk-hero-actions">
				<button class="dk-btn-accent">Get Started</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="dk-btn-ghost">View on GitHub</a>
			</div>
		</div>
	</header>

	<section class="dk-how">
		<div class="dk-how-grid">
			<div class="dk-how-step">
				<div class="dk-how-num">01</div>
				<h3>Clip</h3>
				<p>Paste any recipe URL. We pull ingredients, instructions, images, and metadata automatically. Works with hundreds of sites.</p>
			</div>
			<div class="dk-how-step">
				<div class="dk-how-num">02</div>
				<h3>Organize</h3>
				<p>Tag by meal, cuisine, or mood. Browse by source domain. Search across your entire collection in milliseconds.</p>
			</div>
			<div class="dk-how-step">
				<div class="dk-how-num">03</div>
				<h3>Cook</h3>
				<p>Scale for any crowd. Get per-serving nutrition. Print clean recipe cards. Generate combined shopping lists.</p>
			</div>
		</div>
	</section>

	<section class="dk-showcase">
		<div class="dk-showcase-text">
			<h2>Built for people who actually cook.</h2>
			<p>Not another bookmarking app. ControlCopyPasta understands ingredients — it can scale them, calculate nutrition, detect duplicates, and build smart shopping lists.</p>
		</div>
		<div class="dk-showcase-grid">
			{#each recipes.slice(0, 4) as recipe}
				<div class="dk-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="dk-showcase-card-info">
						<h4>{recipe.title}</h4>
						<span>{recipe.total_time_minutes} min &middot; {recipe.source_domain}</span>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<section class="dk-features">
		<div class="dk-features-grid">
			<div class="dk-feat">
				<div class="dk-feat-icon">&#9889;</div>
				<h3>Instant import</h3>
				<p>Paste a URL or use the browser extension. JSON-LD parsing with custom scraper fallbacks.</p>
			</div>
			<div class="dk-feat">
				<div class="dk-feat-icon">&#9878;</div>
				<h3>Smart scaling</h3>
				<p>0.25x to 4x with proper fraction handling. Never wonder about half of three-quarters again.</p>
			</div>
			<div class="dk-feat">
				<div class="dk-feat-icon">&#9776;</div>
				<h3>Nutrition data</h3>
				<p>Calories, macros, and micronutrients per recipe and per serving. Multiple verified sources.</p>
			</div>
			<div class="dk-feat">
				<div class="dk-feat-icon">&#10003;</div>
				<h3>Shopping lists</h3>
				<p>Generate lists from any recipe. Items auto-grouped by category, quantities intelligently combined.</p>
			</div>
			<div class="dk-feat">
				<div class="dk-feat-icon">&#128279;</div>
				<h3>Find connections</h3>
				<p>See which recipes share ingredients. Browse by source. Discover patterns in your cooking.</p>
			</div>
			<div class="dk-feat">
				<div class="dk-feat-icon">&#128274;</div>
				<h3>Own everything</h3>
				<p>Self-host with Docker. Import from Copy Me That. Export anytime. AGPL licensed, forever open.</p>
			</div>
		</div>
	</section>

	<section class="dk-cta">
		<h2>Your recipes deserve better than a bookmark folder.</h2>
		<p>Deploy in minutes. Import your collection. Start cooking.</p>
		<button class="dk-btn-accent">Get Started</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="dk">
	<div class="dk-dash">
		<header class="dk-dash-header">
			<div>
				<h1>Good evening.</h1>
				<p class="dk-dash-sub">What's for dinner?</p>
			</div>
			<div class="dk-add-recipe">
				<input type="text" placeholder="Paste a recipe URL..." />
				<button class="dk-btn-accent dk-btn-sm">Save</button>
			</div>
		</header>

		<section class="dk-dash-section">
			<div class="dk-section-header">
				<h2>Tonight's inspiration</h2>
				<button class="dk-btn-text">Shuffle</button>
			</div>
			<div class="dk-hero-banner">
				<img src={dinnerIdeas[0].image_url} alt={dinnerIdeas[0].title} />
				<div class="dk-hero-banner-overlay">
					<div class="dk-banner-meta">
						<span class="dk-pill">{dinnerIdeas[0].total_time_minutes} min</span>
						{#each dinnerIdeas[0].tags as tag}
							<span class="dk-pill">{tag.name}</span>
						{/each}
					</div>
					<h3>{dinnerIdeas[0].title}</h3>
					<p>{dinnerIdeas[0].description}</p>
				</div>
			</div>
			<div class="dk-card-grid">
				{#each dinnerIdeas.slice(1) as recipe}
					<div class="dk-card">
						<div class="dk-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
							<span class="dk-card-time">{recipe.total_time_minutes} min</span>
						</div>
						<div class="dk-card-body">
							<h3>{recipe.title}</h3>
							<span class="dk-card-source">{recipe.source_domain}</span>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="dk-dash-section">
			<div class="dk-section-header">
				<h2>Recently added</h2>
				<a href="/recipes" class="dk-btn-text">View all</a>
			</div>
			<div class="dk-card-grid dk-card-grid-4">
				{#each recentlyAdded as recipe}
					<div class="dk-card">
						<div class="dk-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
							<span class="dk-card-time">{recipe.total_time_minutes} min</span>
						</div>
						<div class="dk-card-body">
							<h3>{recipe.title}</h3>
							<span class="dk-card-source">{recipe.source_domain}</span>
						</div>
					</div>
				{/each}
			</div>
		</section>
	</div>
</div>

{:else}
<!-- RECIPE DETAIL -->
<div class="dk">
	<div class="dk-recipe">
		<div class="dk-recipe-hero">
			<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			<div class="dk-recipe-hero-overlay">
				<div class="dk-recipe-pills">
					{#each featuredRecipe.tags as tag}
						<span class="dk-pill">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="dk-recipe-source">{featuredRecipe.source_domain}</p>
			</div>
		</div>

		<div class="dk-recipe-content">
			<div class="dk-recipe-meta">
				<div class="dk-meta-item">
					<span class="dk-meta-val">{featuredRecipe.prep_time_minutes}</span>
					<span class="dk-meta-lbl">min prep</span>
				</div>
				<div class="dk-meta-divider"></div>
				<div class="dk-meta-item">
					<span class="dk-meta-val">{featuredRecipe.cook_time_minutes}</span>
					<span class="dk-meta-lbl">min cook</span>
				</div>
				<div class="dk-meta-divider"></div>
				<div class="dk-meta-item">
					<span class="dk-meta-val">{featuredRecipe.total_time_minutes}</span>
					<span class="dk-meta-lbl">min total</span>
				</div>
				<div class="dk-meta-divider"></div>
				<div class="dk-meta-item">
					<span class="dk-meta-val">{featuredRecipe.servings}</span>
					<span class="dk-meta-lbl">&nbsp;</span>
				</div>
			</div>

			<p class="dk-recipe-desc">{featuredRecipe.description}</p>

			<div class="dk-recipe-actions">
				<button class="dk-btn-accent dk-btn-sm">Add to Shopping List</button>
				<button class="dk-btn-outline dk-btn-sm">Print</button>
				<button class="dk-btn-outline dk-btn-sm">Edit</button>
				<div class="dk-scale">
					<button class="dk-scale-btn">&minus;</button>
					<span>1x</span>
					<button class="dk-scale-btn">+</button>
				</div>
			</div>

			<div class="dk-recipe-body">
				<aside class="dk-ingredients">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>{ing.text}</li>
						{/each}
					</ul>
				</aside>
				<div class="dk-instructions">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<span class="dk-step-num">{i + 1}</span>
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
		background: #0a0a0a;
		color: white;
		font-size: var(--text-sm);
		border-bottom: 1px solid #222;
	}
	.mockup-nav .back {
		color: rgba(255, 255, 255, 0.5);
		text-decoration: none;
	}
	.mockup-nav .back:hover { color: white; }
	.mockup-nav .label { flex: 1; font-weight: var(--font-medium); }
	.mockup-nav .views { display: flex; gap: 2px; }
	.mockup-nav .views button {
		padding: var(--space-1) var(--space-3);
		background: rgba(255, 255, 255, 0.08);
		color: rgba(255, 255, 255, 0.6);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
	}
	.mockup-nav .views button.active {
		background: #c47d4e;
		color: white;
	}

	/* === DARK KITCHEN THEME === */
	.dk {
		font-family: 'Inter', system-ui, sans-serif;
		color: #e8e4e0;
		background: #111;
	}

	/* LANDING - HERO */
	.dk-hero {
		position: relative;
		min-height: 85vh;
		display: flex;
		align-items: center;
		overflow: hidden;
	}
	.dk-hero-bg {
		position: absolute;
		inset: 0;
	}
	.dk-hero-bg img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.dk-hero-scrim {
		position: absolute;
		inset: 0;
		background: linear-gradient(
			135deg,
			rgba(0, 0, 0, 0.85) 0%,
			rgba(0, 0, 0, 0.6) 50%,
			rgba(0, 0, 0, 0.4) 100%
		);
	}
	.dk-hero-content {
		position: relative;
		max-width: 640px;
		padding: 4rem 4rem 4rem 6rem;
	}
	.dk-eyebrow {
		font-size: 0.8125rem;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: #c47d4e;
		margin: 0 0 1.5rem;
		font-weight: 500;
	}
	.dk-hero-content h1 {
		font-size: 4rem;
		font-weight: 700;
		line-height: 1.05;
		margin: 0 0 1.5rem;
		color: white;
		letter-spacing: -0.02em;
	}
	.dk-hero-sub {
		font-size: 1.125rem;
		line-height: 1.7;
		color: rgba(255, 255, 255, 0.75);
		margin: 0 0 2.5rem;
	}
	.dk-hero-actions { display: flex; gap: 1rem; }

	/* BUTTONS */
	.dk-btn-accent {
		padding: 0.875rem 2.25rem;
		background: #c47d4e;
		color: white;
		border: none;
		border-radius: 4px;
		font-size: 0.9375rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 200ms;
		letter-spacing: 0.01em;
	}
	.dk-btn-accent:hover { background: #d4925f; transform: translateY(-1px); }
	.dk-btn-sm { padding: 0.5rem 1.25rem; font-size: 0.8125rem; }

	.dk-btn-ghost {
		padding: 0.875rem 2.25rem;
		background: none;
		color: rgba(255, 255, 255, 0.8);
		border: 1.5px solid rgba(255, 255, 255, 0.25);
		border-radius: 4px;
		font-size: 0.9375rem;
		font-weight: 500;
		text-decoration: none;
		transition: all 200ms;
	}
	.dk-btn-ghost:hover { border-color: rgba(255, 255, 255, 0.6); color: white; }

	.dk-btn-outline {
		padding: 0.5rem 1.25rem;
		background: none;
		color: #a09890;
		border: 1.5px solid #333;
		border-radius: 4px;
		font-size: 0.8125rem;
		cursor: pointer;
		transition: all 200ms;
	}
	.dk-btn-outline:hover { border-color: #c47d4e; color: #c47d4e; }

	.dk-btn-text {
		background: none;
		border: none;
		color: #c47d4e;
		font-size: 0.875rem;
		cursor: pointer;
		text-decoration: none;
		font-weight: 500;
	}
	.dk-btn-text:hover { color: #d4925f; }

	/* LANDING - HOW */
	.dk-how {
		padding: 5rem 3rem;
		max-width: 1100px;
		margin: 0 auto;
		border-bottom: 1px solid #222;
	}
	.dk-how-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 3rem;
	}
	.dk-how-num {
		font-size: 0.75rem;
		font-weight: 700;
		color: #c47d4e;
		letter-spacing: 0.1em;
		margin-bottom: 1rem;
		font-variant-numeric: tabular-nums;
	}
	.dk-how-step h3 {
		font-size: 1.375rem;
		font-weight: 600;
		margin: 0 0 0.75rem;
		color: white;
	}
	.dk-how-step p {
		color: #8a8480;
		line-height: 1.7;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* LANDING - SHOWCASE */
	.dk-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 5rem 3rem;
	}
	.dk-showcase-text {
		max-width: 560px;
		margin-bottom: 3rem;
	}
	.dk-showcase-text h2 {
		font-size: 2rem;
		font-weight: 700;
		margin: 0 0 1rem;
		color: white;
		letter-spacing: -0.01em;
	}
	.dk-showcase-text p {
		color: #8a8480;
		line-height: 1.7;
		margin: 0;
		font-size: 1rem;
	}
	.dk-showcase-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1.25rem;
	}
	.dk-showcase-card {
		border-radius: 6px;
		overflow: hidden;
		background: #1a1a1a;
		border: 1px solid #222;
		transition: border-color 200ms, transform 200ms;
		cursor: pointer;
	}
	.dk-showcase-card:hover {
		border-color: #333;
		transform: translateY(-2px);
	}
	.dk-showcase-card img {
		width: 100%;
		aspect-ratio: 16/9;
		object-fit: cover;
		display: block;
	}
	.dk-showcase-card-info {
		padding: 1rem 1.25rem;
	}
	.dk-showcase-card-info h4 {
		font-size: 0.9375rem;
		font-weight: 500;
		margin: 0 0 0.375rem;
		color: #e8e4e0;
		line-height: 1.4;
	}
	.dk-showcase-card-info span {
		font-size: 0.75rem;
		color: #666;
	}

	/* LANDING - FEATURES */
	.dk-features {
		padding: 5rem 3rem;
		max-width: 1100px;
		margin: 0 auto;
		border-top: 1px solid #222;
	}
	.dk-features-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2.5rem;
	}
	.dk-feat-icon {
		font-size: 1.25rem;
		margin-bottom: 0.75rem;
		width: 40px;
		height: 40px;
		border-radius: 8px;
		background: rgba(196, 125, 78, 0.12);
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.dk-feat h3 {
		font-size: 1rem;
		font-weight: 600;
		margin: 0 0 0.5rem;
		color: white;
	}
	.dk-feat p {
		color: #8a8480;
		line-height: 1.65;
		margin: 0;
		font-size: 0.875rem;
	}

	/* LANDING - CTA */
	.dk-cta {
		text-align: center;
		padding: 5rem 2rem;
		border-top: 1px solid #222;
	}
	.dk-cta h2 {
		font-size: 2rem;
		font-weight: 700;
		color: white;
		margin: 0 0 0.75rem;
		letter-spacing: -0.01em;
	}
	.dk-cta p {
		color: #666;
		font-size: 1rem;
		margin: 0 0 2rem;
	}

	/* DASHBOARD */
	.dk-dash {
		max-width: 1100px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.dk-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #222;
	}
	.dk-dash-header h1 {
		font-size: 2rem;
		font-weight: 700;
		color: white;
		margin: 0;
		letter-spacing: -0.01em;
	}
	.dk-dash-sub {
		color: #666;
		font-size: 1rem;
		margin: 0.25rem 0 0;
	}
	.dk-add-recipe { display: flex; gap: 0.5rem; }
	.dk-add-recipe input {
		padding: 0.5rem 1rem;
		border: 1.5px solid #333;
		border-radius: 4px;
		font-size: 0.875rem;
		width: 320px;
		background: #1a1a1a;
		color: #e8e4e0;
	}
	.dk-add-recipe input::placeholder { color: #555; }
	.dk-add-recipe input:focus { outline: none; border-color: #c47d4e; }

	.dk-dash-section { margin-bottom: 3rem; }
	.dk-section-header {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1.25rem;
	}
	.dk-section-header h2 {
		font-size: 1.25rem;
		font-weight: 600;
		color: white;
		margin: 0;
	}

	.dk-hero-banner {
		position: relative;
		border-radius: 8px;
		overflow: hidden;
		margin-bottom: 1.25rem;
		aspect-ratio: 21/9;
	}
	.dk-hero-banner img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.dk-hero-banner-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 3rem 2rem 2rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.85));
	}
	.dk-banner-meta {
		display: flex;
		gap: 0.5rem;
		margin-bottom: 0.75rem;
	}
	.dk-pill {
		padding: 0.25rem 0.75rem;
		background: rgba(196, 125, 78, 0.3);
		border: 1px solid rgba(196, 125, 78, 0.4);
		border-radius: 100px;
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		font-weight: 500;
		color: #ddb893;
	}
	.dk-hero-banner-overlay h3 {
		font-size: 1.75rem;
		font-weight: 600;
		margin: 0 0 0.5rem;
		color: white;
	}
	.dk-hero-banner-overlay p {
		margin: 0;
		font-size: 0.875rem;
		color: rgba(255, 255, 255, 0.65);
		max-width: 500px;
		line-height: 1.6;
	}

	.dk-card-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1rem;
	}
	.dk-card-grid-4 {
		grid-template-columns: repeat(4, 1fr);
	}
	.dk-card {
		background: #1a1a1a;
		border-radius: 6px;
		overflow: hidden;
		border: 1px solid #222;
		transition: border-color 200ms, transform 200ms;
		cursor: pointer;
	}
	.dk-card:hover {
		border-color: #444;
		transform: translateY(-2px);
	}
	.dk-card-img {
		position: relative;
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.dk-card-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.dk-card:hover .dk-card-img img {
		transform: scale(1.04);
	}
	.dk-card-time {
		position: absolute;
		top: 0.5rem;
		right: 0.5rem;
		padding: 0.2rem 0.5rem;
		background: rgba(0, 0, 0, 0.7);
		backdrop-filter: blur(4px);
		border-radius: 4px;
		font-size: 0.6875rem;
		font-weight: 500;
		color: rgba(255, 255, 255, 0.9);
	}
	.dk-card-body {
		padding: 0.875rem 1rem;
	}
	.dk-card-body h3 {
		font-size: 0.875rem;
		font-weight: 500;
		margin: 0 0 0.375rem;
		color: #e8e4e0;
		line-height: 1.4;
	}
	.dk-card-source {
		font-size: 0.6875rem;
		color: #555;
	}

	/* RECIPE */
	.dk-recipe-hero {
		position: relative;
		height: 55vh;
		min-height: 380px;
		overflow: hidden;
	}
	.dk-recipe-hero img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.dk-recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 4rem 3rem 3rem;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.85));
	}
	.dk-recipe-pills {
		display: flex;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}
	.dk-recipe-hero-overlay h1 {
		font-size: 2.5rem;
		font-weight: 700;
		margin: 0 0 0.5rem;
		color: white;
		line-height: 1.15;
		letter-spacing: -0.01em;
	}
	.dk-recipe-source {
		font-size: 0.875rem;
		color: rgba(255, 255, 255, 0.5);
		margin: 0;
	}

	.dk-recipe-content {
		max-width: 900px;
		margin: 0 auto;
		padding: 2.5rem 1.5rem;
	}

	.dk-recipe-meta {
		display: flex;
		align-items: center;
		gap: 1.5rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #222;
		margin-bottom: 2rem;
	}
	.dk-meta-item { text-align: center; }
	.dk-meta-val {
		display: block;
		font-size: 1.25rem;
		font-weight: 600;
		color: white;
	}
	.dk-meta-lbl {
		font-size: 0.6875rem;
		text-transform: uppercase;
		letter-spacing: 0.1em;
		color: #555;
	}
	.dk-meta-divider {
		width: 1px;
		height: 32px;
		background: #333;
	}

	.dk-recipe-desc {
		font-size: 1rem;
		line-height: 1.7;
		color: #8a8480;
		margin: 0 0 2rem;
	}

	.dk-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		margin-bottom: 3rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #222;
	}
	.dk-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.875rem;
		color: #666;
	}
	.dk-scale-btn {
		width: 28px;
		height: 28px;
		border: 1.5px solid #333;
		border-radius: 4px;
		background: none;
		cursor: pointer;
		font-size: 1rem;
		color: #888;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: border-color 200ms;
	}
	.dk-scale-btn:hover { border-color: #c47d4e; color: #c47d4e; }

	.dk-recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: 3rem;
	}
	.dk-ingredients h2,
	.dk-instructions h2 {
		font-size: 1.125rem;
		font-weight: 600;
		margin: 0 0 1.25rem;
		color: white;
	}
	.dk-ingredients ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.dk-ingredients li {
		padding: 0.75rem 0;
		border-bottom: 1px solid #1f1f1f;
		font-size: 0.9375rem;
		color: #a09890;
		line-height: 1.5;
	}
	.dk-instructions ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.dk-instructions li {
		display: flex;
		gap: 1.25rem;
		margin-bottom: 1.75rem;
		align-items: flex-start;
	}
	.dk-step-num {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: rgba(196, 125, 78, 0.15);
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.8125rem;
		color: #c47d4e;
		font-weight: 600;
		margin-top: 2px;
	}
	.dk-instructions p {
		margin: 0;
		font-size: 0.9375rem;
		line-height: 1.7;
		color: #a09890;
	}
</style>
