<script lang="ts">
	let { href = '/login' }: { href?: string } = $props();

	let animating = $state(false);
	let containerEl = $state<HTMLElement | null>(null);

	// IntersectionObserver for auto-play
	$effect(() => {
		if (!containerEl) return;
		const observer = new IntersectionObserver(
			(entries) => {
				for (const entry of entries) {
					animating = entry.isIntersecting;
				}
			},
			{ threshold: 0.3 }
		);
		observer.observe(containerEl);
		return () => observer.disconnect();
	});
</script>

<a {href} class="ql-card ql-feed" bind:this={containerEl}>
	<div class="ql-text">
		<strong>Instagram Style</strong>
		<span>Scroll a full-screen feed. Double-tap to save, just like your favorite app.</span>
		<span class="ql-action">Try scrolling &rarr;</span>
	</div>
	<div class="ql-phone" aria-hidden="true">
		<div class="phone-frame phone-frame-dark">
			<div class="feed-mock-scroll" class:feed-animating={animating}>
				<div class="feed-mock-slide">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/64b959a840c6917d162cf62b_salmon-quiona-salad-thumbnail.webp" alt="" class="feed-mock-photo" />
					<div class="feed-mock-overlay">
						<div class="feed-mock-source">
							<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
							<span class="feed-mock-domain">sigsbeestreet.co</span>
						</div>
						<div class="feed-mock-name">Salmon Quinoa Salad</div>
					</div>
					<div class="feed-mock-rail">
						<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
						<div class="feed-rail-dot"></div>
						<div class="feed-rail-dot"></div>
					</div>
				</div>
				<div class="feed-mock-slide">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/6470dfae89487940cd3f2c85_one-pot-lemon-pasta-thumbnail.webp" alt="" class="feed-mock-photo" />
					<div class="feed-mock-overlay">
						<div class="feed-mock-source">
							<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
							<span class="feed-mock-domain">sigsbeestreet.co</span>
						</div>
						<div class="feed-mock-name">One Pot Lemon Pasta</div>
					</div>
					<div class="feed-mock-rail">
						<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
						<div class="feed-rail-dot"></div>
						<div class="feed-rail-dot"></div>
					</div>
				</div>
				<div class="feed-mock-slide">
					<img src="https://cdn.prod.website-files.com/60805a0f5f83cfc3688b8d9f/63ac55080a308b862e48c9b2_639a44e8692ea801789551cd_quinoa-pesto-bowl-thumbnail.webp" alt="" class="feed-mock-photo" />
					<div class="feed-mock-overlay">
						<div class="feed-mock-source">
							<img src="https://www.google.com/s2/favicons?domain=sigsbeestreet.co&sz=16" alt="" class="feed-mock-fav" />
							<span class="feed-mock-domain">sigsbeestreet.co</span>
						</div>
						<div class="feed-mock-name">Quinoa Pesto Bowl</div>
					</div>
					<div class="feed-mock-rail">
						<svg class="feed-rail-heart" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2.5"><path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/></svg>
						<div class="feed-rail-dot"></div>
						<div class="feed-rail-dot"></div>
					</div>
				</div>
			</div>
			<div class="feed-mock-heart-burst" class:heart-animating={animating}>
				<svg width="32" height="32" viewBox="0 0 24 24" fill="#ff3040" stroke="none">
					<path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
				</svg>
			</div>
		</div>
	</div>
</a>

<style>
	.ql-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 1.5rem;
		padding: 1.75rem 2rem;
		border-radius: 8px;
		text-decoration: none;
		transition: all 200ms;
		overflow: hidden;
		border: 1px solid;
	}
	.ql-feed {
		background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
		border-color: #2a2a4a;
	}
	.ql-feed:hover {
		border-color: #4a4a6a;
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.25);
	}
	.ql-feed .ql-text strong { color: #fff; }
	.ql-feed .ql-text span { color: rgba(255, 255, 255, 0.6); }
	.ql-feed .ql-action { color: #ff3040 !important; }
	.ql-card:hover .ql-phone { transform: scale(1.03); }

	.ql-text {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		flex: 1;
		min-width: 0;
	}
	.ql-text strong {
		color: #1b3a2d;
		font-size: 1.25rem;
		font-family: 'Cormorant Garamond', Georgia, serif;
	}
	.ql-text span {
		color: #5a7264;
		font-size: 0.875rem;
		line-height: 1.7;
	}
	.ql-action {
		color: #2d5a47 !important;
		font-weight: 600;
		font-size: 0.9375rem !important;
		margin-top: 0.25rem;
	}

	/* Phone mockup */
	.ql-phone {
		flex-shrink: 0;
		transition: transform 200ms;
	}
	.phone-frame-dark {
		width: 140px;
		height: 200px;
		background: #000;
		border-radius: 16px;
		box-shadow: 0 8px 24px rgba(27, 58, 45, 0.12);
		padding: 0;
		display: flex;
		flex-direction: column;
		overflow: hidden;
		border: 2px solid #333;
		position: relative;
	}

	.feed-mock-scroll { animation: none; }
	.feed-animating { animation: feedScroll 6s ease-in-out infinite; }
	@keyframes feedScroll {
		0%, 20% { transform: translateY(0); }
		33%, 53% { transform: translateY(-33.333%); }
		66%, 86% { transform: translateY(-66.666%); }
		100% { transform: translateY(0); }
	}

	.feed-mock-slide {
		width: 100%;
		aspect-ratio: 140 / 200;
		position: relative;
		overflow: hidden;
	}
	.feed-mock-photo {
		width: 100%;
		height: 100%;
		object-fit: cover;
		display: block;
	}
	.feed-mock-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: 24px 6px 8px;
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.75));
	}
	.feed-mock-source {
		display: flex;
		align-items: center;
		gap: 3px;
		margin-bottom: 2px;
	}
	.feed-mock-fav {
		width: 8px;
		height: 8px;
		border-radius: 1px;
	}
	.feed-mock-domain {
		font-size: 5px;
		color: rgba(255, 255, 255, 0.6);
		font-weight: 600;
	}
	.feed-mock-name {
		font-size: 7px;
		font-weight: 700;
		color: white;
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.5);
	}
	.feed-mock-rail {
		position: absolute;
		right: 5px;
		bottom: 8px;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		z-index: 3;
	}
	.feed-rail-heart {
		filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.4));
	}
	.feed-rail-dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		border: 1.5px solid rgba(255, 255, 255, 0.7);
	}
	.feed-mock-heart-burst {
		position: absolute;
		top: 50%;
		left: 45%;
		transform: translate(-50%, -50%) scale(0);
		z-index: 5;
		opacity: 0;
		pointer-events: none;
	}
	.heart-animating { animation: heartBurst 6s ease-in-out infinite; }
	@keyframes heartBurst {
		0%, 10% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		12% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		14% { transform: translate(-50%, -50%) scale(0.9); }
		16% { transform: translate(-50%, -50%) scale(1.05); }
		20% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		33%, 64% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
		76% { opacity: 1; transform: translate(-50%, -50%) scale(1.4); }
		78% { transform: translate(-50%, -50%) scale(0.9); }
		80% { transform: translate(-50%, -50%) scale(1.05); }
		84% { opacity: 0; transform: translate(-50%, -50%) scale(1); }
		85%, 100% { opacity: 0; transform: translate(-50%, -50%) scale(0); }
	}

	@media (max-width: 400px) {
		.ql-phone {
			display: none;
		}
	}
</style>
