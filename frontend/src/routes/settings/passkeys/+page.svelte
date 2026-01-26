<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { passkeys, type Passkey } from '$lib/api/client';

	// Check for WebAuthn support natively
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

	let items = $state<Passkey[]>([]);
	let loading = $state(true);
	let error = $state('');
	let adding = $state(false);
	let newPasskeyName = $state('');
	let showNameInput = $state(false);
	let supportsPasskey = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	$effect(() => {
		supportsPasskey = browserSupportsWebAuthn();
	});

	onMount(loadItems);

	async function loadItems() {
		const token = authStore.getToken();
		if (!token) return;
		loading = true;
		error = '';
		try {
			const result = await passkeys.list(token);
			items = result.data;
		} catch {
			error = 'Failed to load passkeys';
		} finally {
			loading = false;
		}
	}

	async function addPasskey() {
		adding = true;
		error = '';
		try {
			const passkey = await authStore.registerPasskey(newPasskeyName.trim() || undefined);
			items = [...items, passkey];
			newPasskeyName = '';
			showNameInput = false;
		} catch (err: unknown) {
			if (err instanceof Error) {
				if (err.name === 'NotAllowedError') {
					error = 'Passkey registration was cancelled.';
				} else if (err.name === 'InvalidStateError') {
					error = 'This passkey is already registered.';
				} else {
					error = `Failed to add passkey: ${err.message}`;
				}
			} else {
				error = 'Failed to add passkey';
			}
		} finally {
			adding = false;
		}
	}

	async function removePasskey(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await passkeys.delete(token, id);
			items = items.filter((i) => i.id !== id);
		} catch {
			error = 'Failed to remove passkey';
		}
	}

	function formatDate(dateString: string): string {
		return new Date(dateString).toLocaleDateString(undefined, {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}
</script>

<div class="passkeys-page">
	<a href="/settings" class="back-link">&larr; Back to Settings</a>

	<h1>Passkeys</h1>

	<section class="passkeys-section">
		<p class="description">
			Passkeys let you sign in quickly and securely using your fingerprint, face, or screen lock.
			They work across your devices and are more secure than passwords or magic links.
		</p>

		{#if !supportsPasskey}
			<div class="warning">
				Passkeys are not available. This requires a secure context (HTTPS or localhost).
				If you're accessing via an IP address, try using localhost or HTTPS instead.
			</div>
		{:else}
			{#if showNameInput}
				<div class="add-form">
					<input
						type="text"
						bind:value={newPasskeyName}
						placeholder="Passkey name (optional)"
						disabled={adding}
					/>
					<button onclick={addPasskey} disabled={adding}>
						{adding ? 'Adding...' : 'Continue'}
					</button>
					<button class="cancel" onclick={() => (showNameInput = false)} disabled={adding}>
						Cancel
					</button>
				</div>
			{:else}
				<button class="add-button" onclick={() => (showNameInput = true)} disabled={adding}>
					Add Passkey
				</button>
			{/if}
		{/if}

		{#if error}
			<p class="error">{error}</p>
		{/if}

		{#if loading}
			<p class="loading">Loading...</p>
		{:else if items.length === 0}
			<p class="empty">
				No passkeys registered yet. Add a passkey to sign in faster without magic links.
			</p>
		{:else}
			<ul class="passkey-list">
				{#each items as item}
					<li>
						<div class="passkey-info">
							<span class="name">{item.name}</span>
							<span class="date">Added {formatDate(item.inserted_at)}</span>
							{#if item.transports && item.transports.length > 0}
								<span class="transports">{item.transports.join(', ')}</span>
							{/if}
						</div>
						<button onclick={() => removePasskey(item.id)} class="remove">Remove</button>
					</li>
				{/each}
			</ul>
		{/if}
	</section>
</div>

<style>
	.passkeys-page {
		max-width: 600px;
	}

	.back-link {
		display: inline-block;
		color: var(--color-marinara-600);
		text-decoration: none;
		margin-bottom: var(--space-4);
	}

	.back-link:hover {
		text-decoration: underline;
	}

	h1 {
		margin: 0 0 var(--space-8);
		color: var(--color-marinara-800);
	}

	.passkeys-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
	}

	.description {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-6);
		line-height: var(--leading-relaxed);
	}

	.warning {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		padding: var(--space-4);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	.add-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
		flex-wrap: wrap;
	}

	.add-form input {
		flex: 1;
		min-width: 200px;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.add-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.add-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.add-form button:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.add-form button.cancel {
		background: var(--color-gray-500);
	}

	.add-form button.cancel:hover:not(:disabled) {
		background: var(--color-gray-600);
	}

	.add-form button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.add-button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		margin-bottom: var(--space-4);
		transition: all var(--transition-fast);
	}

	.add-button:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.add-button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.error {
		color: var(--color-error);
		font-size: var(--text-sm);
		margin: var(--space-4) 0;
	}

	.loading,
	.empty {
		color: var(--text-muted);
		font-style: italic;
	}

	.passkey-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.passkey-list li {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-3);
		padding: var(--space-4) 0;
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.passkey-list li:last-child {
		border-bottom: none;
	}

	.passkey-info {
		display: flex;
		flex-direction: column;
		gap: var(--space-1);
	}

	.name {
		font-weight: var(--font-medium);
	}

	.date {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.transports {
		color: var(--text-muted);
		font-size: var(--text-xs);
	}

	.remove {
		background: none;
		border: none;
		color: var(--color-marinara-600);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: var(--space-1) var(--space-2);
	}

	.remove:hover {
		text-decoration: underline;
	}
</style>
