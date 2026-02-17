<script lang="ts">
	import { isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	$effect(() => {
		if ($isAuthenticated) {
			goto('/home');
		}
	});
</script>

<div class="landing">
	<div class="hero">
		<h1>ControlCopyPasta</h1>
		<p class="tagline">Your self-hosted recipe manager</p>
		<p class="description">
			Import recipes from any website, plan your shopping, track nutrition, and manage dietary
			needs.
		</p>
		<a href="/login" class="cta">Get Started</a>
		<p class="github-link">
			<a href="https://github.com/deanmarano/controlcopypasta">View on GitHub</a>
		</p>
	</div>

	<section class="feature-section">
		<h2 class="section-title">Cook with Confidence</h2>
		<div class="features">
			<div class="feature">
				<div class="icon">&#128214;</div>
				<h3>Import Recipes</h3>
				<p>Paste a URL to auto-extract recipe details from any website.</p>
			</div>
			<div class="feature">
				<div class="icon">&#128722;</div>
				<h3>Shopping Lists</h3>
				<p>
					Create lists, add recipes to extract ingredients, and check off items while you shop.
				</p>
			</div>
			<div class="feature">
				<div class="icon">&#9878;&#65039;</div>
				<h3>Recipe Scaling</h3>
				<p>Scale any recipe from 0.25x to 4x with automatic quantity conversion.</p>
			</div>
		</div>
	</section>

	<section class="feature-section alt-bg">
		<h2 class="section-title">Organize Your Collection</h2>
		<div class="features">
			<div class="feature">
				<div class="icon">&#127991;</div>
				<h3>Tags &amp; Search</h3>
				<p>Create custom tags to organize your recipes. Filter and search to find what you need.</p>
			</div>
			<div class="feature">
				<div class="icon">&#127760;</div>
				<h3>Browse by Source</h3>
				<p>See your recipes grouped by source website with domain screenshots.</p>
			</div>
			<div class="feature">
				<div class="icon">&#128203;</div>
				<h3>Compare Recipes</h3>
				<p>View recipes side by side to compare ingredients, steps, and nutrition.</p>
			</div>
		</div>
	</section>

	<section class="feature-section">
		<h2 class="section-title">Nutrition &amp; Dietary Needs</h2>
		<div class="features">
			<div class="feature">
				<div class="icon">&#129367;</div>
				<h3>Nutrition Tracking</h3>
				<p>See calories, protein, carbs, and fat per recipe and per serving.</p>
			</div>
			<div class="feature">
				<div class="icon">&#9888;&#65039;</div>
				<h3>Dietary Restrictions</h3>
				<p>
					Avoid ingredients by category, allergen, or animal type. Flagged recipes are marked
					automatically.
				</p>
			</div>
			<div class="feature">
				<div class="icon">&#129382;</div>
				<h3>Ingredient Catalog</h3>
				<p>Browse ingredients by category with nutrition data, allergens, and dietary flags.</p>
			</div>
		</div>
	</section>

	<section class="final-cta">
		<h2>Ready to take control?</h2>
		<a href="/login" class="cta">Get Started</a>
	</section>
</div>

<style>
	.landing {
		text-align: center;
	}

	.hero {
		padding: var(--space-16) var(--space-4);
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-5xl);
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-800);
		letter-spacing: var(--tracking-tight);
	}

	.tagline {
		font-size: var(--text-2xl);
		color: var(--text-muted);
		margin: 0 0 var(--space-6);
	}

	.description {
		max-width: 600px;
		margin: 0 auto var(--space-8);
		font-size: var(--text-lg);
		line-height: var(--leading-relaxed);
		color: var(--text-secondary);
	}

	.cta {
		display: inline-block;
		padding: var(--space-4) var(--space-10);
		background: var(--color-marinara-600);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-size: var(--text-xl);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		box-shadow: var(--shadow-md);
	}

	.cta:hover {
		background: var(--color-marinara-700);
		box-shadow: var(--shadow-basil);
		transform: translateY(-2px);
	}

	.github-link {
		margin-top: var(--space-4);
	}

	.github-link a {
		color: var(--text-muted);
		font-size: var(--text-sm);
		text-decoration: none;
	}

	.github-link a:hover {
		color: var(--text-secondary);
		text-decoration: underline;
	}

	.feature-section {
		padding: var(--space-12) var(--space-4);
	}

	.feature-section.alt-bg {
		background: var(--color-pasta-50);
	}

	.section-title {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		color: var(--color-marinara-700);
		margin: 0 0 var(--space-8);
	}

	.features {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-8);
		max-width: 960px;
		margin: 0 auto;
	}

	.feature {
		padding: var(--space-6);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-md);
	}

	.icon {
		font-size: var(--text-5xl);
		margin-bottom: var(--space-4);
	}

	.feature h3 {
		font-size: var(--text-xl);
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-700);
	}

	.feature p {
		margin: 0;
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
	}

	.final-cta {
		padding: var(--space-12) var(--space-4) var(--space-16);
	}

	.final-cta h2 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		color: var(--color-marinara-700);
		margin: 0 0 var(--space-6);
	}
</style>
