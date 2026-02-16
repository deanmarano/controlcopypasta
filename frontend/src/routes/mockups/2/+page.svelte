<script lang="ts">
	import { recipes, featuredRecipe, dinnerIdeas, recentlyAdded } from '../data';

	let view = $state<'landing' | 'dashboard' | 'recipe'>('landing');
</script>

<div class="mockup-nav">
	<a href="/mockups" class="back">All Mockups</a>
	<span class="label">Direction 2: Minimal Utility</span>
	<div class="views">
		<button class:active={view === 'landing'} onclick={() => (view = 'landing')}>Landing</button>
		<button class:active={view === 'dashboard'} onclick={() => (view = 'dashboard')}>Dashboard</button>
		<button class:active={view === 'recipe'} onclick={() => (view = 'recipe')}>Recipe</button>
	</div>
</div>

{#if view === 'landing'}
<!-- LANDING -->
<div class="mu">
	<header class="mu-hero">
		<div class="mu-hero-content">
			<div class="mu-badge">open source</div>
			<h1>ControlCopyPasta</h1>
			<p class="mu-hero-desc">Self-hosted recipe management. Save from any URL, scale ingredients, calculate nutrition, build shopping lists.</p>
			<div class="mu-hero-actions">
				<button class="mu-btn-primary">Get Started</button>
				<a href="https://github.com/deanmarano/controlcopypasta" class="mu-btn-secondary">GitHub</a>
			</div>
			<div class="mu-stats">
				<div class="mu-stat">
					<span class="mu-stat-val">3</span>
					<span class="mu-stat-label">components</span>
				</div>
				<div class="mu-stat">
					<span class="mu-stat-val">AGPL</span>
					<span class="mu-stat-label">license</span>
				</div>
				<div class="mu-stat">
					<span class="mu-stat-val">Docker</span>
					<span class="mu-stat-label">deploy</span>
				</div>
			</div>
		</div>
	</header>

	<section class="mu-features-section">
		<div class="mu-features-grid">
			<div class="mu-feat">
				<div class="mu-feat-icon">URL</div>
				<div>
					<h3>Clip recipes</h3>
					<p>Paste a URL or use the browser extension. JSON-LD extraction with custom scraper fallback.</p>
				</div>
			</div>
			<div class="mu-feat">
				<div class="mu-feat-icon">0.5x</div>
				<div>
					<h3>Scale ingredients</h3>
					<p>Adjust any recipe 0.25x to 4x. Smart fractions and unit conversion built in.</p>
				</div>
			</div>
			<div class="mu-feat">
				<div class="mu-feat-icon">kcal</div>
				<div>
					<h3>Track nutrition</h3>
					<p>Per-recipe breakdowns with ingredient-level detail. Multiple data sources.</p>
				</div>
			</div>
			<div class="mu-feat">
				<div class="mu-feat-icon">[ ]</div>
				<div>
					<h3>Shopping lists</h3>
					<p>Generate lists from recipes. Auto-grouped by category, quantities combined.</p>
				</div>
			</div>
			<div class="mu-feat">
				<div class="mu-feat-icon">&lt;/&gt;</div>
				<div>
					<h3>Self-hosted</h3>
					<p>Docker deploy. Own your data. Import from Copy Me That. Export anytime.</p>
				</div>
			</div>
			<div class="mu-feat">
				<div class="mu-feat-icon">ext</div>
				<div>
					<h3>Browser extension</h3>
					<p>Chrome and Firefox. One click to save any recipe you're viewing.</p>
				</div>
			</div>
		</div>
	</section>

	<section class="mu-cta-bottom">
		<p>Ready to own your recipes?</p>
		<button class="mu-btn-primary">Get Started</button>
	</section>
</div>

{:else if view === 'dashboard'}
<!-- DASHBOARD -->
<div class="mu">
	<div class="mu-dash">
		<div class="mu-dash-top">
			<div class="mu-dash-left">
				<h1>Dashboard</h1>
			</div>
			<div class="mu-add-bar">
				<input type="text" placeholder="paste url to save recipe" />
				<button class="mu-btn-primary mu-btn-xs">save</button>
			</div>
		</div>

		<section class="mu-section">
			<div class="mu-section-head">
				<h2>dinner ideas</h2>
				<button class="mu-link-btn">shuffle</button>
			</div>
			<div class="mu-grid-dense">
				{#each dinnerIdeas as recipe}
					<div class="mu-item">
						<div class="mu-item-img">
							<img src={recipe.image_url} alt={recipe.title} />
						</div>
						<div class="mu-item-info">
							<span class="mu-item-title">{recipe.title}</span>
							<span class="mu-item-meta">
								{#if recipe.total_time_minutes}{recipe.total_time_minutes}m{/if}
								{#if recipe.total_time_minutes && recipe.source_domain} / {/if}
								{recipe.source_domain}
							</span>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<section class="mu-section">
			<div class="mu-section-head">
				<h2>recently added</h2>
				<button class="mu-link-btn">all recipes</button>
			</div>
			<table class="mu-table">
				<thead>
					<tr>
						<th>Recipe</th>
						<th>Source</th>
						<th>Time</th>
						<th>Servings</th>
						<th>Tags</th>
					</tr>
				</thead>
				<tbody>
					{#each recentlyAdded as recipe}
						<tr>
							<td class="mu-table-title">{recipe.title}</td>
							<td class="mu-table-muted">{recipe.source_domain}</td>
							<td class="mu-table-muted">{recipe.total_time_minutes ? recipe.total_time_minutes + 'm' : '-'}</td>
							<td class="mu-table-muted">{recipe.servings || '-'}</td>
							<td>
								{#each recipe.tags as tag}
									<span class="mu-tag">{tag.name}</span>
								{/each}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</section>
	</div>
</div>

{:else}
<!-- RECIPE -->
<div class="mu">
	<div class="mu-recipe">
		<div class="mu-recipe-top">
			<div class="mu-recipe-header">
				<div class="mu-breadcrumb">recipes / pasta</div>
				<h1>{featuredRecipe.title}</h1>
				<div class="mu-recipe-meta-row">
					<span>{featuredRecipe.source_domain}</span>
					<span class="mu-sep">/</span>
					<span>{featuredRecipe.total_time_minutes} min total</span>
					<span class="mu-sep">/</span>
					<span>{featuredRecipe.servings}</span>
					{#each featuredRecipe.tags as tag}
						<span class="mu-tag">{tag.name}</span>
					{/each}
				</div>
				<p class="mu-recipe-desc">{featuredRecipe.description}</p>
				<div class="mu-recipe-actions">
					<button class="mu-btn-primary mu-btn-xs">add to list</button>
					<button class="mu-btn-secondary mu-btn-xs">print</button>
					<button class="mu-btn-secondary mu-btn-xs">edit</button>
					<div class="mu-scale-control">
						<button class="mu-scale-btn">-</button>
						<span class="mu-scale-val">1x</span>
						<button class="mu-scale-btn">+</button>
					</div>
				</div>
			</div>
			<div class="mu-recipe-img">
				<img src={featuredRecipe.image_url} alt={featuredRecipe.title} />
			</div>
		</div>

		<div class="mu-recipe-body">
			<div class="mu-recipe-col-left">
				<h2>ingredients</h2>
				<ul class="mu-ing-list">
					{#each featuredRecipe.ingredients as ing}
						<li>{ing.text}</li>
					{/each}
				</ul>

				<div class="mu-recipe-times">
					<div class="mu-time-item">
						<span class="mu-time-label">prep</span>
						<span class="mu-time-val">{featuredRecipe.prep_time_minutes}m</span>
					</div>
					<div class="mu-time-item">
						<span class="mu-time-label">cook</span>
						<span class="mu-time-val">{featuredRecipe.cook_time_minutes}m</span>
					</div>
					<div class="mu-time-item">
						<span class="mu-time-label">total</span>
						<span class="mu-time-val">{featuredRecipe.total_time_minutes}m</span>
					</div>
				</div>
			</div>
			<div class="mu-recipe-col-right">
				<h2>steps</h2>
				<div class="mu-steps">
					{#each featuredRecipe.instructions as step, i}
						<div class="mu-step">
							<span class="mu-step-n">{String(i + 1).padStart(2, '0')}</span>
							<p>{step.text}</p>
						</div>
					{/each}
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

	/* === MINIMAL UTILITY === */
	.mu {
		font-family: 'Inter', system-ui, sans-serif;
		color: #1a1a1a;
		background: #ffffff;
	}

	/* LANDING */
	.mu-hero {
		padding: 5rem 2rem 3rem;
		max-width: 640px;
		margin: 0 auto;
	}
	.mu-hero-content { display: flex; flex-direction: column; }
	.mu-badge {
		display: inline-block;
		padding: 0.25rem 0.5rem;
		background: #f0f0f0;
		font-family: 'Fira Code', monospace;
		font-size: 0.6875rem;
		color: #666;
		border-radius: 3px;
		margin-bottom: 1.5rem;
		width: fit-content;
		letter-spacing: 0.02em;
	}
	.mu h1 {
		font-size: 2rem;
		font-weight: 600;
		margin: 0 0 1rem;
		letter-spacing: -0.03em;
		line-height: 1.15;
	}
	.mu-hero-desc {
		font-size: 1rem;
		line-height: 1.65;
		color: #555;
		margin: 0 0 2rem;
	}
	.mu-hero-actions { display: flex; gap: 0.75rem; margin-bottom: 3rem; }

	.mu-btn-primary {
		padding: 0.625rem 1.5rem;
		background: #1a1a1a;
		color: white;
		border: none;
		border-radius: 6px;
		font-size: 0.8125rem;
		font-weight: 500;
		cursor: pointer;
		transition: background 150ms;
	}
	.mu-btn-primary:hover { background: #333; }
	.mu-btn-xs { padding: 0.375rem 0.875rem; font-size: 0.75rem; }

	.mu-btn-secondary {
		padding: 0.625rem 1.5rem;
		background: none;
		color: #1a1a1a;
		border: 1px solid #ddd;
		border-radius: 6px;
		font-size: 0.8125rem;
		font-weight: 500;
		cursor: pointer;
		text-decoration: none;
		transition: border-color 150ms;
	}
	.mu-btn-secondary:hover { border-color: #999; }

	.mu-stats {
		display: flex;
		gap: 2.5rem;
		padding-top: 2rem;
		border-top: 1px solid #eee;
	}
	.mu-stat { display: flex; flex-direction: column; }
	.mu-stat-val {
		font-family: 'Fira Code', monospace;
		font-size: 1.25rem;
		font-weight: 600;
		color: #1a1a1a;
	}
	.mu-stat-label {
		font-size: 0.6875rem;
		color: #999;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}

	.mu-features-section {
		max-width: 800px;
		margin: 0 auto;
		padding: 2rem 2rem 4rem;
	}
	.mu-features-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1.5rem;
	}
	.mu-feat {
		display: flex;
		gap: 1rem;
		padding: 1.25rem;
		border: 1px solid #eee;
		border-radius: 8px;
	}
	.mu-feat-icon {
		flex-shrink: 0;
		width: 40px;
		height: 40px;
		background: #f5f5f5;
		border-radius: 6px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-family: 'Fira Code', monospace;
		font-size: 0.6875rem;
		color: #666;
		font-weight: 600;
	}
	.mu-feat h3 {
		font-size: 0.875rem;
		font-weight: 600;
		margin: 0 0 0.375rem;
	}
	.mu-feat p {
		font-size: 0.8125rem;
		color: #666;
		line-height: 1.5;
		margin: 0;
	}

	.mu-cta-bottom {
		text-align: center;
		padding: 3rem 2rem;
		background: #fafafa;
		border-top: 1px solid #eee;
	}
	.mu-cta-bottom p {
		font-size: 0.9375rem;
		color: #666;
		margin: 0 0 1rem;
	}

	/* DASHBOARD */
	.mu-dash {
		max-width: 960px;
		margin: 0 auto;
		padding: 1.5rem;
	}
	.mu-dash-top {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 2rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid #eee;
	}
	.mu-dash-left h1 {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
		letter-spacing: -0.02em;
	}
	.mu-add-bar { display: flex; gap: 0.375rem; }
	.mu-add-bar input {
		padding: 0.375rem 0.75rem;
		border: 1px solid #ddd;
		border-radius: 6px;
		font-size: 0.75rem;
		width: 280px;
		font-family: 'Fira Code', monospace;
	}
	.mu-add-bar input::placeholder { color: #bbb; }
	.mu-add-bar input:focus { outline: none; border-color: #1a1a1a; }

	.mu-section { margin-bottom: 2.5rem; }
	.mu-section-head {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		margin-bottom: 1rem;
	}
	.mu-section-head h2 {
		font-size: 0.8125rem;
		font-weight: 600;
		margin: 0;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: #999;
	}
	.mu-link-btn {
		background: none;
		border: none;
		font-size: 0.75rem;
		color: #999;
		cursor: pointer;
		text-decoration: none;
	}
	.mu-link-btn:hover { color: #1a1a1a; }

	.mu-grid-dense {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 0.75rem;
	}
	.mu-item {
		border: 1px solid #eee;
		border-radius: 8px;
		overflow: hidden;
		transition: border-color 150ms;
		cursor: pointer;
	}
	.mu-item:hover { border-color: #ccc; }
	.mu-item-img {
		aspect-ratio: 16/10;
		overflow: hidden;
	}
	.mu-item-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
	}
	.mu-item-info { padding: 0.625rem 0.75rem; }
	.mu-item-title {
		display: block;
		font-size: 0.8125rem;
		font-weight: 500;
		line-height: 1.3;
		margin-bottom: 0.25rem;
		color: #1a1a1a;
	}
	.mu-item-meta {
		font-size: 0.6875rem;
		color: #999;
		font-family: 'Fira Code', monospace;
	}

	.mu-table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.8125rem;
	}
	.mu-table th {
		text-align: left;
		font-size: 0.6875rem;
		font-weight: 500;
		color: #999;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		padding: 0.5rem 0.75rem;
		border-bottom: 1px solid #eee;
	}
	.mu-table td {
		padding: 0.625rem 0.75rem;
		border-bottom: 1px solid #f5f5f5;
	}
	.mu-table tbody tr:hover { background: #fafafa; }
	.mu-table-title { font-weight: 500; color: #1a1a1a; }
	.mu-table-muted { color: #999; }
	.mu-tag {
		display: inline-block;
		padding: 0.125rem 0.5rem;
		background: #f0f0f0;
		border-radius: 3px;
		font-size: 0.6875rem;
		color: #666;
		margin-right: 0.25rem;
		font-family: 'Fira Code', monospace;
	}

	/* RECIPE */
	.mu-recipe {
		max-width: 960px;
		margin: 0 auto;
		padding: 1.5rem;
	}
	.mu-recipe-top {
		display: grid;
		grid-template-columns: 1fr 400px;
		gap: 2rem;
		margin-bottom: 2.5rem;
		padding-bottom: 2rem;
		border-bottom: 1px solid #eee;
	}
	.mu-breadcrumb {
		font-size: 0.6875rem;
		color: #999;
		margin-bottom: 0.75rem;
		font-family: 'Fira Code', monospace;
	}
	.mu-recipe-header h1 {
		font-size: 1.75rem;
		font-weight: 600;
		letter-spacing: -0.03em;
		margin: 0 0 0.75rem;
		line-height: 1.2;
	}
	.mu-recipe-meta-row {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.75rem;
		color: #999;
		margin-bottom: 1rem;
		flex-wrap: wrap;
	}
	.mu-sep { color: #ddd; }
	.mu-recipe-desc {
		font-size: 0.9375rem;
		line-height: 1.6;
		color: #555;
		margin: 0 0 1.5rem;
	}
	.mu-recipe-actions {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}
	.mu-scale-control {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: 0.25rem;
	}
	.mu-scale-btn {
		width: 24px;
		height: 24px;
		border: 1px solid #ddd;
		border-radius: 4px;
		background: none;
		cursor: pointer;
		font-size: 0.875rem;
		color: #666;
		display: flex;
		align-items: center;
		justify-content: center;
	}
	.mu-scale-val {
		font-family: 'Fira Code', monospace;
		font-size: 0.75rem;
		color: #666;
		min-width: 24px;
		text-align: center;
	}
	.mu-recipe-img {
		border-radius: 8px;
		overflow: hidden;
	}
	.mu-recipe-img img {
		width: 100%;
		height: 100%;
		object-fit: cover;
		aspect-ratio: 4/3;
	}

	.mu-recipe-body {
		display: grid;
		grid-template-columns: 280px 1fr;
		gap: 3rem;
	}
	.mu-recipe-body h2 {
		font-size: 0.75rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: #999;
		margin: 0 0 1rem;
	}
	.mu-ing-list {
		list-style: none;
		padding: 0;
		margin: 0 0 2rem;
	}
	.mu-ing-list li {
		padding: 0.5rem 0;
		border-bottom: 1px solid #f5f5f5;
		font-size: 0.8125rem;
		color: #333;
		line-height: 1.4;
	}
	.mu-recipe-times {
		display: flex;
		gap: 1.5rem;
		padding-top: 1rem;
		border-top: 1px solid #eee;
	}
	.mu-time-item { display: flex; flex-direction: column; }
	.mu-time-label {
		font-size: 0.625rem;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: #bbb;
	}
	.mu-time-val {
		font-family: 'Fira Code', monospace;
		font-size: 0.9375rem;
		font-weight: 600;
	}

	.mu-steps { display: flex; flex-direction: column; gap: 1.25rem; }
	.mu-step {
		display: flex;
		gap: 1rem;
		align-items: flex-start;
	}
	.mu-step-n {
		flex-shrink: 0;
		font-family: 'Fira Code', monospace;
		font-size: 0.75rem;
		color: #bbb;
		padding-top: 0.25rem;
		min-width: 24px;
	}
	.mu-step p {
		margin: 0;
		font-size: 0.875rem;
		line-height: 1.65;
		color: #333;
	}
</style>
