<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 3: Warm & Playful</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING -->
<div class="wp">
	<header class="wp-hero">
		<div class="wp-hero-blob"></div>
		<div class="wp-hero-content">
			<div class="wp-pill">100% open source</div>
			<h1>Save any recipe.<br />Cook with joy.</h1>
			<p>Your personal recipe box that lives on your server. Clip recipes from the web, scale for any crowd, and never lose a favorite again.</p>
			<div class="wp-hero-btns">
				<button class="wp-btn-primary">Start Cooking</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="wp-btn-outline">View Source</a>
			</div>
		</div>
		<div class="wp-hero-cards">
			{#each recipes.slice(0, 3) as recipe}
				<div class="wp-preview-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<span>{recipe.title}</span>
				</div>
			{/each}
		</div>
	</header>

	<section class="wp-how">
		<h2>How it works</h2>
		<div class="wp-how-grid">
			<div class="wp-how-step">
				<div class="wp-how-bubble">1</div>
				<h3>Paste a URL</h3>
				<p>Find a recipe you love anywhere on the web. Paste the link and we'll extract everything — ingredients, instructions, images, and nutrition data.</p>
			</div>
			<div class="wp-how-step">
				<div class="wp-how-bubble">2</div>
				<h3>Organize your way</h3>
				<p>Tag recipes by meal type, cuisine, or season. Browse by source. Build a collection that mirrors how you actually cook.</p>
			</div>
			<div class="wp-how-step">
				<div class="wp-how-bubble">3</div>
				<h3>Cook with confidence</h3>
				<p>Scale ingredients for any crowd. Check nutrition facts. Generate shopping lists. Print clean recipe cards for the kitchen counter.</p>
			</div>
		</div>
	</section>

	<section class="wp-showcase">
		<div class="wp-showcase-text">
			<div class="wp-pill">Your collection</div>
			<h2>Every recipe from every corner of the web, in one place.</h2>
			<p>Import from Bon Appetit, NYT Cooking, Serious Eats, food blogs — any site with a recipe. The browser extension makes it one click.</p>
		</div>
		<div class="wp-showcase-cards">
			{#each recipes.slice(0, 4) as recipe}
				<div class="wp-showcase-card">
					<img src={recipe.image_url} alt={recipe.title} />
					<div class="wp-showcase-info">
						<span class="wp-showcase-source">{recipe.source_domain}</span>
						<h4>{recipe.title}</h4>
						<span class="wp-showcase-time">{recipe.total_time_minutes} min</span>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<section class="wp-features">
		<h2>Everything you need to cook smarter</h2>
		<div class="wp-feat-grid">
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#127758;</div>
				<h3>Save from anywhere</h3>
				<p>Paste a URL or use the browser extension for Chrome and Firefox.</p>
			</div>
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#9878;&#65039;</div>
				<h3>Scale up or down</h3>
				<p>Cooking for 2? Or 20? Adjust quantities with one click.</p>
			</div>
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#129367;</div>
				<h3>Nutrition info</h3>
				<p>Calories, protein, carbs, and fat for every recipe and serving.</p>
			</div>
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#128722;</div>
				<h3>Smart lists</h3>
				<p>Build shopping lists with automatic grouping and quantities.</p>
			</div>
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#127991;</div>
				<h3>Tag & organize</h3>
				<p>Custom tags, search, filter. Find that recipe in seconds.</p>
			</div>
			<div class="wp-feat-card">
				<div class="wp-feat-emoji">&#128274;</div>
				<h3>Own your data</h3>
				<p>Self-host on your server. AGPL licensed. No vendor lock-in.</p>
			</div>
		</div>
	</section>

	<section class="wp-stats">
		<div class="wp-stat">
			<span class="wp-stat-num">200+</span>
			<span class="wp-stat-label">Supported sites</span>
		</div>
		<div class="wp-stat">
			<span class="wp-stat-num">30s</span>
			<span class="wp-stat-label">Average import</span>
		</div>
		<div class="wp-stat">
			<span class="wp-stat-num">100%</span>
			<span class="wp-stat-label">Open source</span>
		</div>
		<div class="wp-stat">
			<span class="wp-stat-num">0</span>
			<span class="wp-stat-label">Tracking scripts</span>
		</div>
	</section>

	<section class="wp-cta-bottom">
		<div class="wp-cta-inner">
			<h2>Ready to organize your recipes?</h2>
			<p class="wp-cta-sub">Deploy in minutes with Docker. Your recipes stay on your server, forever.</p>
			<button class="wp-btn-primary wp-btn-lg">Get Started Free</button>
		</div>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="wp">
	<div class="wp-dash">
		<header class="wp-dash-header">
			<div>
				<h1>Hey there! &#128075;</h1>
				<p>What sounds good tonight?</p>
			</div>
			<div class="wp-add-form">
				<input type="text" placeholder="Paste a recipe URL to save it..." />
				<button class="wp-btn-primary wp-btn-sm">Save Recipe</button>
			</div>
		</header>

		<section class="wp-section">
			<div class="wp-section-top">
				<h2>Dinner inspiration</h2>
				<button class="wp-text-btn">Shuffle picks</button>
			</div>
			<div class="wp-card-grid">
				{#each dinnerIdeas as recipe}
					<div class="wp-card">
						<div class="wp-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
							{#if recipe.total_time_minutes}
								<span class="wp-card-badge">{recipe.total_time_minutes} min</span>
							{/if}
						</div>
						<div class="wp-card-content">
							<h3>{recipe.title}</h3>
							<p>{recipe.source_domain}</p>
							<div class="wp-card-tags">
								{#each recipe.tags as tag}
									<span class="wp-tag">{tag.name}</span>
								{/each}
							</div>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="wp-section">
			<div class="wp-section-top">
				<h2>Recently added</h2>
				<button class="wp-text-btn">See all</button>
			</div>
			<div class="wp-card-grid">
				{#each recentlyAdded as recipe}
					<div class="wp-card">
						<div class="wp-card-img">
							<img src={recipe.image_url} alt={recipe.title} />
							{#if recipe.total_time_minutes}
								<span class="wp-card-badge">{recipe.total_time_minutes} min</span>
							{/if}
						</div>
						<div class="wp-card-content">
							<h3>{recipe.title}</h3>
							<p>{recipe.source_domain}</p>
						</div>
					</div>
				{/each}
			</div>
		</section>
	</div>
</div>

{:else}
<!-- RECIPE -->
<div class="wp">
	<div class="wp-recipe">
		<div class="wp-recipe-top-grid">
			<div class="wp-recipe-img-wrap">
				<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			</div>
			<div class="wp-recipe-info">
				<div class="wp-recipe-tag-row">
					{#each featuredRecipe.tags as tag}
						<span class="wp-tag">{tag.name}</span>
					{/each}
				</div>
				<h1>{featuredRecipe.title}</h1>
				<p class="wp-recipe-source">From {featuredRecipe.source_domain}</p>
				<p class="wp-recipe-desc">{featuredRecipe.description}</p>

				<div class="wp-time-pills">
					<div class="wp-pill-item">
						<span class="wp-pill-label">Prep</span>
						<span class="wp-pill-val">{featuredRecipe.prep_time_minutes}m</span>
					</div>
					<div class="wp-pill-item">
						<span class="wp-pill-label">Cook</span>
						<span class="wp-pill-val">{featuredRecipe.cook_time_minutes}m</span>
					</div>
					<div class="wp-pill-item">
						<span class="wp-pill-label">Total</span>
						<span class="wp-pill-val">{featuredRecipe.total_time_minutes}m</span>
					</div>
					<div class="wp-pill-item">
						<span class="wp-pill-label">Serves</span>
						<span class="wp-pill-val">{featuredRecipe.servings}</span>
					</div>
				</div>

				<div class="wp-recipe-actions">
					<button class="wp-btn-primary wp-btn-sm">Add to Shopping List</button>
					<button class="wp-btn-outline wp-btn-sm">Print</button>
					<button class="wp-btn-outline wp-btn-sm">Edit</button>
					<div class="wp-scale">
						<button class="wp-scale-btn">-</button>
						<span>1x</span>
						<button class="wp-scale-btn">+</button>
					</div>
				</div>
			</div>
		</div>

		<div class="wp-recipe-body">
			<div class="wp-ingredients-col">
				<div class="wp-section-card">
					<h2>Ingredients</h2>
					<ul>
						{#each featuredRecipe.ingredients as ing}
							<li>
								<span class="wp-check"></span>
								{ing.text}
							</li>
						{/each}
					</ul>
				</div>
			</div>
			<div class="wp-instructions-col">
				<div class="wp-section-card">
					<h2>Instructions</h2>
					<ol>
						{#each featuredRecipe.instructions as step, i}
							<li>
								<div class="wp-step-bubble">{i + 1}</div>
								<div class="wp-step-text">{step.text}</div>
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
	.mockup-nav .back { color: rgba(255,255,255,0.6); text-decoration: none; }
	.mockup-nav .back:hover { color: white; }
	.mockup-nav .label { flex: 1; font-weight: var(--font-medium); }
	.mockup-nav .views { display: flex; gap: 2px; }
	.mockup-nav .views button {
		padding: var(--space-1) var(--space-3);
		background: rgba(255,255,255,0.1);
		color: rgba(255,255,255,0.7);
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-xs);
	}
	.mockup-nav .views button.active { background: white; color: #1a1a1a; }

	/* === WARM & PLAYFUL === */
	.wp {
		font-family: 'Inter', system-ui, sans-serif;
		color: #2d2a26;
		background: #fffcf7;
	}

	/* LANDING */
	.wp-hero {
		position: relative;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2rem;
		padding: 4rem 3rem;
		max-width: 1200px;
		margin: 0 auto;
		overflow: hidden;
	}
	.wp-hero-blob {
		position: absolute;
		top: -100px;
		right: -100px;
		width: 500px;
		height: 500px;
		background: radial-gradient(circle, rgba(234, 179, 8, 0.12) 0%, transparent 70%);
		border-radius: 50%;
		pointer-events: none;
	}
	.wp-hero-content {
		display: flex;
		flex-direction: column;
		justify-content: center;
		z-index: 1;
	}
	.wp-pill {
		display: inline-block;
		padding: 0.375rem 0.875rem;
		background: linear-gradient(135deg, #fef3c7, #fde68a);
		color: #92400e;
		border-radius: 20px;
		font-size: 0.75rem;
		font-weight: 600;
		width: fit-content;
		margin-bottom: 1.5rem;
	}
	.wp h1 {
		font-size: 2.75rem;
		font-weight: 700;
		line-height: 1.15;
		margin: 0 0 1rem;
		color: #2d2a26;
		letter-spacing: -0.02em;
	}
	.wp-hero-content > p {
		font-size: 1.0625rem;
		line-height: 1.65;
		color: #6b6560;
		margin: 0 0 2rem;
		max-width: 440px;
	}
	.wp-hero-btns { display: flex; gap: 0.75rem; }

	.wp-btn-primary {
		padding: 0.75rem 1.75rem;
		background: linear-gradient(135deg, #f59e0b, #d97706);
		color: white;
		border: none;
		border-radius: 12px;
		font-size: 0.9375rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 200ms;
		box-shadow: 0 2px 8px rgba(245, 158, 11, 0.3);
	}
	.wp-btn-primary:hover {
		transform: translateY(-1px);
		box-shadow: 0 4px 16px rgba(245, 158, 11, 0.4);
	}
	.wp-btn-sm { padding: 0.5rem 1.25rem; font-size: 0.8125rem; border-radius: 10px; }
	.wp-btn-lg { padding: 1rem 2.5rem; font-size: 1.0625rem; border-radius: 14px; }

	.wp-btn-outline {
		padding: 0.75rem 1.75rem;
		background: none;
		color: #6b6560;
		border: 1.5px solid #e5ddd4;
		border-radius: 12px;
		font-size: 0.9375rem;
		font-weight: 500;
		cursor: pointer;
		text-decoration: none;
		transition: all 200ms;
	}
	.wp-btn-outline:hover { border-color: #d97706; color: #d97706; }

	.wp-hero-cards {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
		z-index: 1;
	}
	.wp-preview-card {
		display: flex;
		align-items: center;
		gap: 1rem;
		padding: 0.75rem;
		background: white;
		border-radius: 16px;
		box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);
		transition: transform 200ms;
	}
	.wp-preview-card:hover { transform: translateX(4px); }
	.wp-preview-card img {
		width: 72px;
		height: 54px;
		object-fit: cover;
		border-radius: 10px;
	}
	.wp-preview-card span {
		font-size: 0.875rem;
		font-weight: 500;
		color: #2d2a26;
	}

	/* How it works */
	.wp-how {
		max-width: 1000px;
		margin: 0 auto;
		padding: 4rem 2rem;
	}
	.wp-how h2 {
		font-size: 1.75rem;
		font-weight: 700;
		text-align: center;
		margin: 0 0 2.5rem;
		color: #2d2a26;
	}
	.wp-how-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 2rem;
	}
	.wp-how-step { text-align: center; }
	.wp-how-bubble {
		width: 48px;
		height: 48px;
		border-radius: 14px;
		background: linear-gradient(135deg, #fef3c7, #fde68a);
		color: #92400e;
		display: inline-flex;
		align-items: center;
		justify-content: center;
		font-size: 1.125rem;
		font-weight: 700;
		margin-bottom: 1rem;
	}
	.wp-how-step h3 {
		font-size: 1.0625rem;
		font-weight: 600;
		margin: 0 0 0.5rem;
		color: #2d2a26;
	}
	.wp-how-step p {
		color: #6b6560;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}

	/* Showcase */
	.wp-showcase {
		max-width: 1100px;
		margin: 0 auto;
		padding: 3rem 2rem 4rem;
		display: grid;
		grid-template-columns: 1fr 1.3fr;
		gap: 3rem;
		align-items: center;
	}
	.wp-showcase-text h2 {
		font-size: 1.75rem;
		font-weight: 700;
		line-height: 1.25;
		margin: 0 0 1rem;
		color: #2d2a26;
	}
	.wp-showcase-text p {
		color: #6b6560;
		line-height: 1.65;
		margin: 0;
		font-size: 0.9375rem;
	}
	.wp-showcase-text .wp-pill { margin-bottom: 1rem; }
	.wp-showcase-cards {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 0.875rem;
	}
	.wp-showcase-card {
		background: white;
		border-radius: 16px;
		overflow: hidden;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
		transition: transform 200ms, box-shadow 200ms;
		cursor: pointer;
	}
	.wp-showcase-card:hover {
		transform: translateY(-3px);
		box-shadow: 0 6px 20px rgba(0, 0, 0, 0.1);
	}
	.wp-showcase-card img {
		width: 100%;
		aspect-ratio: 16/10;
		object-fit: cover;
		display: block;
	}
	.wp-showcase-info {
		padding: 0.75rem 1rem;
	}
	.wp-showcase-source {
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: #9a928a;
		display: block;
		margin-bottom: 0.25rem;
	}
	.wp-showcase-info h4 {
		font-size: 0.8125rem;
		font-weight: 600;
		margin: 0 0 0.25rem;
		color: #2d2a26;
		line-height: 1.35;
	}
	.wp-showcase-time {
		font-size: 0.6875rem;
		color: #d97706;
		font-weight: 500;
	}

	/* Features */
	.wp-features {
		padding: 4rem 2rem;
		max-width: 1000px;
		margin: 0 auto;
		text-align: center;
	}
	.wp-features h2 {
		font-size: 1.75rem;
		font-weight: 700;
		margin: 0 0 2.5rem;
		color: #2d2a26;
	}
	.wp-feat-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1.25rem;
		text-align: left;
	}
	.wp-feat-card {
		padding: 1.5rem;
		background: white;
		border-radius: 16px;
		box-shadow: 0 1px 8px rgba(0, 0, 0, 0.04);
		transition: transform 200ms, box-shadow 200ms;
	}
	.wp-feat-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
	}
	.wp-feat-emoji { font-size: 1.75rem; margin-bottom: 0.75rem; }
	.wp-feat-card h3 {
		font-size: 0.9375rem;
		font-weight: 600;
		margin: 0 0 0.5rem;
	}
	.wp-feat-card p {
		font-size: 0.8125rem;
		color: #6b6560;
		line-height: 1.55;
		margin: 0;
	}

	/* Stats */
	.wp-stats {
		display: flex;
		justify-content: center;
		gap: 3rem;
		padding: 2.5rem 2rem;
		max-width: 800px;
		margin: 0 auto;
	}
	.wp-stat { text-align: center; }
	.wp-stat-num {
		display: block;
		font-size: 2.25rem;
		font-weight: 700;
		color: #d97706;
		line-height: 1;
		margin-bottom: 0.375rem;
	}
	.wp-stat-label {
		font-size: 0.75rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: #9a928a;
		font-weight: 500;
	}

	.wp-cta-bottom { padding: 3rem 2rem 5rem; }
	.wp-cta-inner {
		max-width: 600px;
		margin: 0 auto;
		text-align: center;
		padding: 3rem;
		background: linear-gradient(135deg, #fffbeb, #fef3c7);
		border-radius: 24px;
	}
	.wp-cta-inner h2 {
		font-size: 1.5rem;
		font-weight: 700;
		margin: 0 0 0.75rem;
		color: #2d2a26;
	}
	.wp-cta-sub {
		color: #6b6560;
		font-size: 0.9375rem;
		margin: 0 0 1.5rem;
	}

	/* DASHBOARD */
	.wp-dash {
		max-width: 1000px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.wp-dash-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 2.5rem;
	}
	.wp-dash-header h1 {
		font-size: 1.75rem;
		margin: 0;
	}
	.wp-dash-header > div > p {
		margin: 0.25rem 0 0;
		color: #6b6560;
		font-size: 0.9375rem;
	}
	.wp-add-form { display: flex; gap: 0.5rem; }
	.wp-add-form input {
		padding: 0.5rem 1rem;
		border: 1.5px solid #e5ddd4;
		border-radius: 10px;
		font-size: 0.8125rem;
		width: 300px;
		background: white;
	}
	.wp-add-form input::placeholder { color: #bbb5ad; }
	.wp-add-form input:focus { outline: none; border-color: #f59e0b; }

	.wp-section { margin-bottom: 2.5rem; }
	.wp-section-top {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1rem;
	}
	.wp-section-top h2 {
		font-size: 1.125rem;
		font-weight: 600;
		margin: 0;
	}
	.wp-text-btn {
		background: none;
		border: none;
		font-size: 0.8125rem;
		color: #d97706;
		cursor: pointer;
		font-weight: 500;
	}
	.wp-text-btn:hover { text-decoration: underline; }

	.wp-card-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
		gap: 1rem;
	}
	.wp-card {
		background: white;
		border-radius: 16px;
		overflow: hidden;
		box-shadow: 0 1px 8px rgba(0, 0, 0, 0.05);
		transition: transform 200ms, box-shadow 200ms;
		cursor: pointer;
	}
	.wp-card:hover {
		transform: translateY(-3px);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
	}
	.wp-card-img {
		position: relative;
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.wp-card-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		transition: transform 300ms;
	}
	.wp-card:hover .wp-card-img img { transform: scale(1.04); }
	.wp-card-badge {
		position: absolute;
		top: 0.5rem;
		right: 0.5rem;
		padding: 0.25rem 0.625rem;
		background: rgba(255, 255, 255, 0.9);
		backdrop-filter: blur(4px);
		border-radius: 8px;
		font-size: 0.6875rem;
		font-weight: 600;
		color: #92400e;
	}
	.wp-card-content { padding: 1rem; }
	.wp-card-content h3 {
		font-size: 0.9375rem;
		font-weight: 600;
		margin: 0 0 0.25rem;
		line-height: 1.35;
	}
	.wp-card-content p {
		font-size: 0.75rem;
		color: #9a928a;
		margin: 0;
	}
	.wp-card-tags { display: flex; gap: 0.375rem; margin-top: 0.625rem; }
	.wp-tag {
		display: inline-block;
		padding: 0.1875rem 0.5rem;
		background: linear-gradient(135deg, #fef3c7, #fde68a);
		color: #92400e;
		border-radius: 6px;
		font-size: 0.6875rem;
		font-weight: 600;
	}

	/* RECIPE */
	.wp-recipe {
		max-width: 1000px;
		margin: 0 auto;
		padding: 2rem 1.5rem;
	}
	.wp-recipe-top-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 2.5rem;
		margin-bottom: 2.5rem;
	}
	.wp-recipe-img-wrap {
		border-radius: 20px;
		overflow: hidden;
		box-shadow: 0 4px 24px rgba(0, 0, 0, 0.1);
	}
	.wp-recipe-img-wrap img {
		width: 100%;
		aspect-ratio: 4/3;
		object-fit: cover;
	}
	.wp-recipe-info {
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	.wp-recipe-tag-row { display: flex; gap: 0.5rem; margin-bottom: 1rem; }
	.wp-recipe-info h1 {
		font-size: 2rem;
		line-height: 1.2;
		margin: 0 0 0.5rem;
	}
	.wp-recipe-source {
		font-size: 0.8125rem;
		color: #9a928a;
		margin: 0 0 1rem;
	}
	.wp-recipe-desc {
		font-size: 0.9375rem;
		line-height: 1.6;
		color: #6b6560;
		margin: 0 0 1.5rem;
	}
	.wp-time-pills {
		display: flex;
		gap: 0.75rem;
		margin-bottom: 1.5rem;
	}
	.wp-pill-item {
		padding: 0.5rem 1rem;
		background: white;
		border-radius: 12px;
		box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
		text-align: center;
	}
	.wp-pill-label {
		display: block;
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: #9a928a;
	}
	.wp-pill-val {
		font-size: 0.875rem;
		font-weight: 600;
		color: #2d2a26;
	}
	.wp-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		flex-wrap: wrap;
	}
	.wp-scale {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.375rem;
		font-size: 0.875rem;
		color: #6b6560;
		font-weight: 500;
	}
	.wp-scale-btn {
		width: 30px;
		height: 30px;
		border: 1.5px solid #e5ddd4;
		border-radius: 8px;
		background: white;
		cursor: pointer;
		font-size: 1rem;
		color: #6b6560;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: border-color 150ms;
	}
	.wp-scale-btn:hover { border-color: #d97706; }

	.wp-recipe-body {
		display: grid;
		grid-template-columns: 320px 1fr;
		gap: 2rem;
	}
	.wp-section-card {
		background: white;
		border-radius: 20px;
		padding: 1.75rem;
		box-shadow: 0 1px 8px rgba(0, 0, 0, 0.04);
	}
	.wp-section-card h2 {
		font-size: 1.125rem;
		font-weight: 600;
		margin: 0 0 1.25rem;
		color: #2d2a26;
	}
	.wp-section-card ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.wp-section-card ul li {
		display: flex;
		align-items: flex-start;
		gap: 0.75rem;
		padding: 0.625rem 0;
		border-bottom: 1px solid #f5f0ea;
		font-size: 0.875rem;
		color: #4a4541;
		line-height: 1.5;
	}
	.wp-section-card ul li:last-child { border-bottom: none; }
	.wp-check {
		flex-shrink: 0;
		width: 18px;
		height: 18px;
		border: 2px solid #e5ddd4;
		border-radius: 5px;
		margin-top: 2px;
		transition: border-color 150ms;
	}
	.wp-section-card ul li:hover .wp-check { border-color: #f59e0b; }

	.wp-section-card ol {
		list-style: none;
		padding: 0;
		margin: 0;
	}
	.wp-section-card ol li {
		display: flex;
		gap: 1rem;
		margin-bottom: 1.5rem;
		align-items: flex-start;
	}
	.wp-step-bubble {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 10px;
		background: linear-gradient(135deg, #fef3c7, #fde68a);
		color: #92400e;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.8125rem;
		font-weight: 700;
	}
	.wp-step-text {
		font-size: 0.9375rem;
		line-height: 1.65;
		color: #4a4541;
		padding-top: 0.25rem;
	}
</style>
