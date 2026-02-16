<script lang="ts">
	import { onMount } from 'svelte';
	import { authStore, isAuthenticated, currentUser, isLoading, isAdmin } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';

	let { children } = $props();
	let mobileMenuOpen = $state(false);

	onMount(() => {
		authStore.initialize();
	});

	async function handleLogout() {
		await authStore.logout();
		mobileMenuOpen = false;
		goto('/login');
	}

	function toggleMobileMenu() {
		mobileMenuOpen = !mobileMenuOpen;
	}

	function closeMobileMenu() {
		mobileMenuOpen = false;
	}

	// Close menu when route changes
	$effect(() => {
		$page.url.pathname;
		mobileMenuOpen = false;
	});
</script>

<svelte:head>
	<title>ControlCopyPasta</title>
</svelte:head>

{#if $page.url.pathname.startsWith('/mockups')}
	{@render children()}
{:else if $isLoading}
	<div class="loading">Loading...</div>
{:else}
	<div class="app">
		<header>
			<nav>
				<a href="/" class="brand">ControlCopyPasta</a>
				{#if $isAuthenticated}
					<div class="nav-links desktop-only">
						<a href="/recipes">Recipes</a>
						<a href="/browse">Browse</a>
						<a href="/shopping-lists">Shopping</a>
						<a href="/ingredients">Ingredients</a>
						<a href="/tags">Tags</a>
						<a href="/settings">Settings</a>
						{#if $isAdmin}
							<a href="/admin" class="admin-link">Admin</a>
						{/if}
					</div>
					<div class="user-menu desktop-only">
						<span>{$currentUser?.email}</span>
						<button onclick={handleLogout}>Logout</button>
					</div>
					<button
						class="mobile-menu-btn mobile-only"
						onclick={toggleMobileMenu}
						aria-label={mobileMenuOpen ? 'Close menu' : 'Open menu'}
						aria-expanded={mobileMenuOpen}
					>
						<span class="hamburger" class:open={mobileMenuOpen}>
							<span></span>
							<span></span>
							<span></span>
						</span>
					</button>
				{:else if !$page.url.pathname.startsWith('/login') && !$page.url.pathname.startsWith('/auth')}
					<a href="/login" class="login-link">Login</a>
				{/if}
			</nav>
		</header>

		{#if $isAuthenticated && mobileMenuOpen}
			<div class="mobile-menu-overlay" onclick={closeMobileMenu} role="presentation"></div>
			<div class="mobile-menu">
				<div class="mobile-user">
					<span class="mobile-user-email">{$currentUser?.email}</span>
				</div>
				<nav class="mobile-nav">
					<a href="/recipes" onclick={closeMobileMenu}>Recipes</a>
					<a href="/browse" onclick={closeMobileMenu}>Browse</a>
					<a href="/shopping-lists" onclick={closeMobileMenu}>Shopping Lists</a>
					<a href="/ingredients" onclick={closeMobileMenu}>Ingredients</a>
					<a href="/tags" onclick={closeMobileMenu}>Tags</a>
					<a href="/settings" onclick={closeMobileMenu}>Settings</a>
					{#if $isAdmin}
						<a href="/admin" onclick={closeMobileMenu} class="admin-link">Admin</a>
					{/if}
				</nav>
				<button class="mobile-logout" onclick={handleLogout}>Logout</button>
			</div>
		{/if}

		<main>
			{@render children()}
		</main>

		<footer>
			<p>ControlCopyPasta - Self-hosted recipe management</p>
		</footer>
	</div>
{/if}

<style>
	@import '$lib/styles/styleguide.css';

	.loading {
		display: flex;
		justify-content: center;
		align-items: center;
		height: 100vh;
		font-size: var(--text-xl);
		color: var(--text-secondary);
	}

	.app {
		min-height: 100vh;
		display: flex;
		flex-direction: column;
	}

	header {
		background: var(--bg-header);
		color: var(--text-inverse);
		padding: var(--space-4);
		box-shadow: var(--shadow-md);
		width: 100%;
		box-sizing: border-box;
	}

	nav {
		max-width: var(--container-xl);
		margin: 0 auto;
		display: flex;
		align-items: center;
		gap: var(--space-8);
		width: 100%;
		box-sizing: border-box;
	}

	.brand {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		font-weight: var(--font-bold);
		color: var(--color-pasta-300);
		text-decoration: none;
	}

	.brand:hover {
		color: var(--color-pasta-200);
	}

	.nav-links {
		display: flex;
		gap: var(--space-4);
		flex: 1;
	}

	.nav-links a {
		color: var(--color-gray-200);
		text-decoration: none;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		padding: var(--space-2) var(--space-3);
		border-radius: var(--radius-md);
		transition: all var(--transition-fast);
	}

	.nav-links a:hover {
		color: var(--color-white);
		background-color: rgba(255, 255, 255, 0.1);
	}

	.nav-links .admin-link {
		color: var(--color-pasta-300);
	}

	.nav-links .admin-link:hover {
		color: var(--color-pasta-200);
	}

	.mobile-nav .admin-link {
		color: var(--color-pasta-300);
	}

	.mobile-nav .admin-link:hover {
		color: var(--color-pasta-200);
	}

	.user-menu {
		display: flex;
		align-items: center;
		gap: var(--space-4);
	}

	.user-menu span {
		color: var(--color-gray-300);
		font-size: var(--text-sm);
	}

	.user-menu button {
		background: transparent;
		border: var(--border-width-thin) solid var(--color-gray-300);
		color: var(--color-gray-200);
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all var(--transition-fast);
	}

	.user-menu button:hover {
		background: rgba(255, 255, 255, 0.1);
		color: var(--color-white);
		border-color: var(--color-white);
	}

	.login-link {
		color: var(--color-white);
		text-decoration: none;
		margin-left: auto;
		font-weight: var(--font-medium);
	}

	.login-link:hover {
		text-decoration: underline;
	}

	/* Mobile menu button */
	.mobile-menu-btn {
		display: none;
		background: transparent;
		border: none;
		padding: var(--space-2);
		margin-left: auto;
		cursor: pointer;
	}

	.hamburger {
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		width: 24px;
		height: 18px;
	}

	.hamburger span {
		display: block;
		height: 2px;
		width: 100%;
		background: var(--color-white);
		border-radius: 2px;
		transition: all var(--transition-fast);
		transform-origin: center;
	}

	.hamburger.open span:nth-child(1) {
		transform: translateY(8px) rotate(45deg);
	}

	.hamburger.open span:nth-child(2) {
		opacity: 0;
	}

	.hamburger.open span:nth-child(3) {
		transform: translateY(-8px) rotate(-45deg);
	}

	/* Mobile menu overlay */
	.mobile-menu-overlay {
		display: none;
		position: fixed;
		inset: 0;
		background: rgba(0, 0, 0, 0.5);
		z-index: var(--z-overlay);
	}

	/* Mobile menu drawer */
	.mobile-menu {
		display: none;
		position: fixed;
		top: 0;
		right: 0;
		width: min(300px, 85vw);
		height: 100vh;
		background: var(--bg-header);
		z-index: var(--z-modal);
		padding: var(--space-6);
		box-shadow: var(--shadow-xl);
		overflow-y: auto;
	}

	.mobile-user {
		padding-bottom: var(--space-4);
		border-bottom: 1px solid rgba(255, 255, 255, 0.1);
		margin-bottom: var(--space-4);
	}

	.mobile-user-email {
		color: var(--color-gray-300);
		font-size: var(--text-sm);
		word-break: break-all;
	}

	.mobile-nav {
		display: flex;
		flex-direction: column;
		gap: var(--space-1);
	}

	.mobile-nav a {
		color: var(--color-gray-200);
		text-decoration: none;
		padding: var(--space-3) var(--space-4);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.mobile-nav a:hover,
	.mobile-nav a:focus {
		background: rgba(255, 255, 255, 0.1);
		color: var(--color-white);
	}

	.mobile-logout {
		width: 100%;
		margin-top: var(--space-6);
		padding: var(--space-3) var(--space-4);
		background: transparent;
		border: 1px solid var(--color-gray-500);
		color: var(--color-gray-300);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.mobile-logout:hover {
		background: rgba(255, 255, 255, 0.1);
		border-color: var(--color-white);
		color: var(--color-white);
	}

	/* Responsive breakpoints */
	@media (max-width: 768px) {
		.desktop-only {
			display: none !important;
		}

		.mobile-only {
			display: flex !important;
		}

		.mobile-menu-btn {
			display: flex;
		}

		.mobile-menu-overlay {
			display: block;
		}

		.mobile-menu {
			display: flex;
			flex-direction: column;
		}

		header {
			padding: var(--space-3) var(--space-4);
		}

		nav {
			gap: var(--space-2);
			width: 100%;
		}

		.brand {
			font-size: var(--text-lg);
			flex-shrink: 1;
			min-width: 0;
			overflow: hidden;
			text-overflow: ellipsis;
			white-space: nowrap;
		}

		main {
			padding: var(--space-4) var(--space-3);
		}
	}

	@media (min-width: 769px) {
		.mobile-only {
			display: none !important;
		}
	}

	main {
		flex: 1;
		max-width: var(--container-xl);
		width: 100%;
		margin: 0 auto;
		padding: var(--space-8) var(--space-4);
		box-sizing: border-box;
	}

	footer {
		background: var(--bg-footer);
		color: var(--color-gray-400);
		text-align: center;
		padding: var(--space-4);
		font-size: var(--text-sm);
	}
</style>
