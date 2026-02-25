<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, isLoading } from '$lib/stores/auth';
	import { connectedAccounts, ApiError } from '$lib/api/client';

	let provider = $derived($page.url.searchParams.get('provider') || '');
	let username = $derived($page.url.searchParams.get('username') || '');
	let linkToken = $derived($page.url.searchParams.get('token') || '');

	let linking = $state(false);
	let error = $state('');
	let success = $state(false);

	let missingParams = $derived(!provider || !username || !linkToken);

	// Redirect to login if not authenticated (preserving return URL)
	$effect(() => {
		if (!$isLoading && !$isAuthenticated && !missingParams) {
			const returnUrl = $page.url.pathname + $page.url.search;
			goto(`/login?return=${encodeURIComponent(returnUrl)}`);
		}
	});

	async function handleLink() {
		const token = authStore.getToken();
		if (!token) return;

		linking = true;
		error = '';

		try {
			await connectedAccounts.link(token, provider, username, linkToken);
			success = true;
		} catch (err) {
			if (err instanceof ApiError) {
				const data = err.data as { error?: string };
				if (err.status === 409) {
					error = 'This account is already linked to a controlcopypasta account.';
				} else if (err.status === 401) {
					error = data.error || 'Invalid or expired linking token. Please request a new link.';
				} else {
					error = data.error || 'Something went wrong. Please try again.';
				}
			} else {
				error = 'Something went wrong. Please try again.';
			}
		} finally {
			linking = false;
		}
	}

	function providerLabel(p: string): string {
		switch (p) {
			case 'instagram': return 'Instagram';
			case 'tiktok': return 'TikTok';
			default: return p;
		}
	}
</script>

<div class="link-page">
	<div class="link-card">
		{#if missingParams}
			<h1>Invalid Link</h1>
			<p class="message error-message">This linking URL is missing required parameters. Please use the link sent to you via DM.</p>
		{:else if $isLoading}
			<h1>Loading...</h1>
			<p class="message">Checking your authentication status...</p>
		{:else if success}
			<h1>Account Linked</h1>
			<p class="message success-message">
				Your {providerLabel(provider)} account <strong>@{username}</strong> has been linked to your controlcopypasta account.
			</p>
			<div class="actions">
				<a href="/settings" class="button">View in Settings</a>
				<a href="/home" class="button secondary">Go to Home</a>
			</div>
		{:else if $isAuthenticated}
			<h1>Link Your Account</h1>
			<p class="message">
				Link your {providerLabel(provider)} account <strong>@{username}</strong> to your controlcopypasta account?
			</p>

			{#if error}
				<div class="error">{error}</div>
			{/if}

			<div class="actions">
				<button onclick={handleLink} disabled={linking} class="button">
					{linking ? 'Linking...' : `Link @${username}`}
				</button>
				<a href="/home" class="button secondary">Cancel</a>
			</div>
		{/if}
	</div>
</div>

<style>
	.link-page {
		display: flex;
		justify-content: center;
		align-items: center;
		min-height: 60vh;
	}

	.link-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
		width: 100%;
		max-width: 450px;
		text-align: center;
	}

	h1 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-2xl);
		color: var(--color-marinara-800);
	}

	.message {
		color: var(--text-secondary);
		margin-bottom: var(--space-6);
		line-height: 1.5;
	}

	.success-message {
		color: var(--color-basil-700);
	}

	.error-message {
		color: var(--color-error);
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
		text-align: left;
	}

	.actions {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
	}

	.button {
		display: block;
		padding: var(--space-3);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		cursor: pointer;
		text-decoration: none;
		text-align: center;
		transition: all var(--transition-fast);
	}

	.button:hover:not(:disabled) {
		background: var(--color-marinara-600);
		box-shadow: var(--shadow-marinara);
	}

	.button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.button.secondary {
		background: var(--bg-surface);
		color: var(--text-primary);
		border: var(--border-width-default) solid var(--border-default);
	}

	.button.secondary:hover {
		background: var(--color-pasta-100);
		box-shadow: none;
	}
</style>
