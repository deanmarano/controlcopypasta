<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore } from '$lib/stores/auth';

	let status = $state<'loading' | 'success' | 'error'>('loading');
	let error = $state('');

	onMount(async () => {
		const token = $page.url.searchParams.get('token');

		if (!token) {
			status = 'error';
			error = 'No verification token provided.';
			return;
		}

		try {
			const result = await authStore.verifyMagicLink(token);
			status = 'success';
			// Check for return URL in query params (e.g. from /link-account flow)
			const returnUrl = $page.url.searchParams.get('return');
			// Redirect to setup wizard for new users, return URL, or home
			const destination = result.user.onboarding_completed === false ? '/setup' : (returnUrl || '/home');
			setTimeout(() => goto(destination), 1500);
		} catch (err: unknown) {
			status = 'error';
			if (err && typeof err === 'object' && 'data' in err) {
				const apiErr = err as { data: { error?: string } };
				error = apiErr.data?.error || 'Failed to verify magic link.';
			} else {
				error = 'Failed to verify magic link.';
			}
		}
	});
</script>

<div class="verify-page">
	<div class="verify-card">
		{#if status === 'loading'}
			<div class="status loading">
				<div class="spinner"></div>
				<p>Verifying your magic link...</p>
			</div>
		{:else if status === 'success'}
			<div class="status success">
				<div class="icon">&#10004;</div>
				<h1>Successfully signed in!</h1>
				<p>Redirecting you to your recipes...</p>
			</div>
		{:else}
			<div class="status error">
				<div class="icon">&#10006;</div>
				<h1>Verification failed</h1>
				<p>{error}</p>
				<a href="/login">Try again</a>
			</div>
		{/if}
	</div>
</div>

<style>
	.verify-page {
		display: flex;
		justify-content: center;
		align-items: center;
		min-height: 60vh;
	}

	.verify-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-12);
		box-shadow: var(--shadow-lg);
		text-align: center;
		min-width: 300px;
	}

	.status {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: var(--space-4);
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 3px solid var(--border-light);
		border-top-color: var(--color-marinara-500);
		border-radius: var(--radius-full);
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	.icon {
		font-size: var(--text-5xl);
	}

	.success .icon {
		color: var(--color-basil-500);
	}

	.error .icon {
		color: var(--color-marinara-600);
	}

	h1 {
		margin: 0;
		font-size: var(--text-2xl);
		color: var(--text-primary);
	}

	p {
		color: var(--text-secondary);
		margin: 0;
	}

	a {
		display: inline-block;
		margin-top: var(--space-4);
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-500);
		color: var(--color-white);
		text-decoration: none;
		border-radius: var(--radius-md);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	a:hover {
		background: var(--color-marinara-600);
		box-shadow: var(--shadow-marinara);
	}
</style>
