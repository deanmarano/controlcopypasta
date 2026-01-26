<script lang="ts">
	import { isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	$effect(() => {
		if ($isAuthenticated) {
			goto('/recipes');
		}
	});
</script>

<div class="landing">
	<div class="hero">
		<h1>ControlCopyPasta</h1>
		<p class="tagline">Your self-hosted recipe manager</p>
		<p class="description">
			Save recipes from any website, organize them with tags, and access them anytime.
			Take control of your recipe collection.
		</p>
		<a href="/login" class="cta">Get Started</a>
	</div>

	<div class="features">
		<div class="feature">
			<div class="icon">&#128214;</div>
			<h2>Import from Anywhere</h2>
			<p>Paste a URL and automatically extract recipe details from any website using Schema.org data.</p>
		</div>
		<div class="feature">
			<div class="icon">&#127991;</div>
			<h2>Organize with Tags</h2>
			<p>Create custom tags to organize your recipes. Filter and search to find what you need.</p>
		</div>
		<div class="feature">
			<div class="icon">&#128274;</div>
			<h2>Self-Hosted</h2>
			<p>Your data stays on your server. No ads, no tracking, no vendor lock-in.</p>
		</div>
	</div>
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
		background: var(--color-basil-500);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-size: var(--text-xl);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		box-shadow: var(--shadow-md);
	}

	.cta:hover {
		background: var(--color-basil-600);
		box-shadow: var(--shadow-basil);
		transform: translateY(-2px);
	}

	.features {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-8);
		padding: var(--space-8);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		box-shadow: var(--shadow-lg);
	}

	.feature {
		padding: var(--space-6);
	}

	.icon {
		font-size: var(--text-5xl);
		margin-bottom: var(--space-4);
	}

	.feature h2 {
		font-size: var(--text-xl);
		margin: 0 0 var(--space-2);
		color: var(--color-marinara-700);
	}

	.feature p {
		margin: 0;
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
	}
</style>
