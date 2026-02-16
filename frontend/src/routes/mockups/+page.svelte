<div class="mockups-index">
	<h1>Design Mockups</h1>
	<p class="subtitle">Three design directions for ControlCopyPasta. Each includes a public landing page, logged-in dashboard, and recipe detail view.</p>

	<div class="directions">
		<a href="/mockups/1" class="direction-card">
			<div class="direction-number">1</div>
			<h2>Editorial Kitchen</h2>
			<p>Magazine-inspired. Big hero images, serif typography, warm earth tones. Feels like a premium cooking publication. Content-forward with generous whitespace.</p>
			<div class="tags">
				<span class="tag">Serif headings</span>
				<span class="tag">Full-bleed images</span>
				<span class="tag">Warm palette</span>
			</div>
		</a>

		<a href="/mockups/2" class="direction-card">
			<div class="direction-number">2</div>
			<h2>Minimal Utility</h2>
			<p>Clean, dense, functional. Tight grid, small type, monospace accents. Designed for people with 200+ recipes who want to find things fast. Information-dense without clutter.</p>
			<div class="tags">
				<span class="tag">Compact grid</span>
				<span class="tag">Monospace accents</span>
				<span class="tag">Neutral palette</span>
			</div>
		</a>

		<a href="/mockups/3" class="direction-card">
			<div class="direction-number">3</div>
			<h2>Warm & Playful</h2>
			<p>Rounded corners, soft shadows, organic shapes. Friendly and approachable with hand-drawn-feeling accents. Makes cooking feel like fun, not a chore.</p>
			<div class="tags">
				<span class="tag">Rounded UI</span>
				<span class="tag">Soft gradients</span>
				<span class="tag">Vibrant accents</span>
			</div>
		</a>
	</div>
</div>

<style>
	.mockups-index {
		max-width: 960px;
		margin: 0 auto;
		padding: var(--space-8) var(--space-4);
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-2);
	}

	.subtitle {
		color: var(--text-secondary);
		font-size: var(--text-lg);
		margin: 0 0 var(--space-8);
	}

	.directions {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-6);
	}

	.direction-card {
		display: block;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-normal);
		border: 2px solid transparent;
	}

	.direction-card:hover {
		transform: translateY(-4px);
		box-shadow: var(--shadow-lg);
		border-color: var(--color-marinara-300);
	}

	.direction-number {
		width: 40px;
		height: 40px;
		border-radius: var(--radius-full);
		background: var(--color-marinara-500);
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: var(--font-bold);
		font-size: var(--text-lg);
		margin-bottom: var(--space-4);
	}

	.direction-card h2 {
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-2);
	}

	.direction-card p {
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
		margin: 0 0 var(--space-4);
		font-size: var(--text-sm);
	}

	.tags {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
	}

	.tag {
		padding: var(--space-1) var(--space-2);
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}
</style>
