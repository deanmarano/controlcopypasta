<script lang="ts">
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';

	// Check for WebAuthn support natively (requires secure context)
	function browserSupportsWebAuthn(): boolean {
		const supported = (
			typeof window !== 'undefined' &&
			typeof window.PublicKeyCredential !== 'undefined' &&
			typeof navigator.credentials !== 'undefined'
		);
		// WebAuthn requires secure context (HTTPS or localhost)
		const isSecure = typeof window !== 'undefined' && window.isSecureContext;
		return supported && isSecure;
	}

	let email = $state('');
	let loading = $state(false);
	let passkeyLoading = $state(false);
	let message = $state('');
	let error = $state('');
	let supportsPasskey = $state(false);

	// Check WebAuthn support on mount
	$effect(() => {
		supportsPasskey = browserSupportsWebAuthn();
	});

	// Redirect if already authenticated
	$effect(() => {
		if ($isAuthenticated) {
			goto('/recipes');
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		error = '';
		message = '';
		loading = true;

		try {
			await authStore.requestMagicLink(email);
			message = 'Check your email for a magic link to sign in.';
			email = '';
		} catch (err) {
			error = 'Failed to send magic link. Please try again.';
		} finally {
			loading = false;
		}
	}

	async function handlePasskeyLogin() {
		if (!email.trim()) {
			error = 'Please enter your email first';
			return;
		}

		error = '';
		message = '';
		passkeyLoading = true;

		try {
			await authStore.authenticateWithPasskey(email.trim());
			goto('/recipes');
		} catch (err: unknown) {
			if (err instanceof Error) {
				if (err.message.includes('No passkeys registered')) {
					error = 'No passkeys registered for this email. Use the magic link instead.';
				} else if (err.name === 'NotAllowedError') {
					error = 'Passkey authentication was cancelled.';
				} else {
					error = 'Passkey authentication failed. Please try again or use the magic link.';
				}
			} else {
				error = 'Passkey authentication failed.';
			}
		} finally {
			passkeyLoading = false;
		}
	}
</script>

<div class="login-page">
	<div class="login-card">
		<h1>Sign in to ControlCopyPasta</h1>
		<p class="subtitle">Enter your email to sign in</p>

		<form onsubmit={handleSubmit}>
			<div class="form-group">
				<label for="email">Email address</label>
				<input
					type="email"
					id="email"
					bind:value={email}
					placeholder="you@example.com"
					required
					disabled={loading || passkeyLoading}
				/>
			</div>

			{#if error}
				<div class="error">{error}</div>
			{/if}

			{#if message}
				<div class="success">{message}</div>
			{/if}

			<div class="button-group">
				<button type="submit" disabled={loading || passkeyLoading || !email}>
					{loading ? 'Sending...' : 'Send Magic Link'}
				</button>

				{#if supportsPasskey}
					<div class="divider">
						<span>or</span>
					</div>
					<button
						type="button"
						class="passkey-button"
						disabled={loading || passkeyLoading || !email}
						onclick={handlePasskeyLogin}
					>
						{passkeyLoading ? 'Authenticating...' : 'Sign in with Passkey'}
					</button>
				{/if}
			</div>
		</form>
	</div>
</div>

<style>
	.login-page {
		display: flex;
		justify-content: center;
		align-items: center;
		min-height: 60vh;
	}

	.login-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
		width: 100%;
		max-width: 400px;
	}

	h1 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-2xl);
		text-align: center;
		color: var(--color-marinara-800);
	}

	.subtitle {
		color: var(--text-secondary);
		text-align: center;
		margin-bottom: var(--space-8);
	}

	.form-group {
		margin-bottom: var(--space-4);
	}

	label {
		display: block;
		margin-bottom: var(--space-2);
		font-weight: var(--font-medium);
		color: var(--text-primary);
	}

	input {
		width: 100%;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		box-sizing: border-box;
		transition: all var(--transition-fast);
	}

	input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.button-group {
		margin-top: var(--space-4);
	}

	button {
		width: 100%;
		padding: var(--space-3);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	button:hover:not(:disabled) {
		background: var(--color-marinara-600);
		box-shadow: var(--shadow-marinara);
	}

	button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.divider {
		display: flex;
		align-items: center;
		margin: var(--space-4) 0;
		color: var(--text-muted);
	}

	.divider::before,
	.divider::after {
		content: '';
		flex: 1;
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.divider span {
		padding: 0 var(--space-3);
		font-size: var(--text-sm);
	}

	.passkey-button {
		background: var(--color-marinara-600);
	}

	.passkey-button:hover:not(:disabled) {
		background: var(--color-marinara-700);
		box-shadow: var(--shadow-basil);
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-top: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
	}

	.success {
		background: var(--color-success-bg);
		color: var(--color-basil-800);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-top: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-success);
	}
</style>
