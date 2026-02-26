<script lang="ts">
	import { onMount } from 'svelte';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { messages, type DirectMessage } from '$lib/api/client';

	let messageList = $state<DirectMessage[]>([]);
	let loading = $state(true);
	let error = $state<string | null>(null);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await loadMessages();
	});

	async function loadMessages() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			loading = true;
			error = null;
			const result = await messages.list(token);
			messageList = result.data;
		} catch (e) {
			error = 'Failed to load messages';
			console.error(e);
		} finally {
			loading = false;
		}
	}

	function formatTimestamp(ts: string | null): string {
		if (!ts) return '';
		const date = new Date(ts);
		return date.toLocaleDateString(undefined, {
			month: 'short',
			day: 'numeric',
			hour: 'numeric',
			minute: '2-digit'
		});
	}

	function messageTypeLabel(type: string): string {
		switch (type) {
			case 'shared_post': return 'Shared Post';
			case 'shared_reel': return 'Shared Reel';
			case 'forwarded': return 'Forwarded';
			default: return 'Text';
		}
	}

	function parseStatusClass(status: string): string {
		switch (status) {
			case 'success': return 'status-success';
			case 'failed': return 'status-failed';
			default: return 'status-pending';
		}
	}

	async function handleSaveRecipe(messageId: string, urlId: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await messages.saveRecipe(token, messageId, urlId);
			goto(`/recipes/${result.data.recipe_id}`);
		} catch (e) {
			console.error('Failed to save recipe:', e);
		}
	}
</script>

<svelte:head>
	<title>Messages - ControlCopyPasta</title>
</svelte:head>

<div class="messages-page">
	<h1>Messages</h1>
	<p class="subtitle">Recipes shared with you via Instagram DMs</p>

	{#if loading}
		<div class="loading">Loading messages...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if messageList.length === 0}
		<div class="empty-state">
			<h2>No messages yet</h2>
			<p>When someone sends a recipe link to your connected Instagram account, it will appear here.</p>
			<a href="/settings" class="link-btn">Connect an account</a>
		</div>
	{:else}
		<div class="message-list">
			{#each messageList as message}
				<a href="/messages/{message.id}" class="message-card">
					<div class="message-header">
						<span class="sender">@{message.sender_username}</span>
						<span class="type-badge">{messageTypeLabel(message.message_type)}</span>
						<span class="timestamp">{formatTimestamp(message.platform_timestamp || message.inserted_at)}</span>
					</div>

					{#if message.message_text}
						<p class="message-text">{message.message_text}</p>
					{/if}

					{#if message.shared_content?.caption}
						<p class="shared-caption">{message.shared_content.caption}</p>
					{/if}

					{#if message.extracted_urls.length > 0}
						<div class="urls-section">
							{#each message.extracted_urls as eu}
								<div class="extracted-url">
									<span class="parse-status {parseStatusClass(eu.parse_status)}">
										{#if eu.parse_status === 'success'}Parsed{:else if eu.parse_status === 'failed'}Failed{:else}Parsing...{/if}
									</span>
									{#if eu.recipe_title}
										<span class="recipe-title">{eu.recipe_title}</span>
									{:else}
										<span class="url-text">{eu.url}</span>
									{/if}
									{#if eu.recipe_id}
										<a href="/recipes/{eu.recipe_id}" class="saved-link" onclick={(e) => e.stopPropagation()}>View Recipe</a>
									{:else if eu.parse_status === 'success'}
										<button
											class="save-btn"
											onclick={(e) => { e.preventDefault(); e.stopPropagation(); handleSaveRecipe(message.id, eu.id); }}
										>Save Recipe</button>
									{/if}
								</div>
							{/each}
						</div>
					{/if}
				</a>
			{/each}
		</div>
	{/if}
</div>

<style>
	.messages-page {
		max-width: 800px;
		margin: 0 auto;
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-3xl);
		margin-bottom: var(--space-1);
	}

	.subtitle {
		color: var(--text-secondary);
		margin-bottom: var(--space-6);
	}

	.loading, .error {
		text-align: center;
		padding: var(--space-8);
		color: var(--text-secondary);
	}

	.error {
		color: var(--color-red-600);
	}

	.empty-state {
		text-align: center;
		padding: var(--space-12) var(--space-4);
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		border: var(--border-width-thin) solid var(--border-default);
	}

	.empty-state h2 {
		font-size: var(--text-xl);
		margin-bottom: var(--space-2);
	}

	.empty-state p {
		color: var(--text-secondary);
		margin-bottom: var(--space-4);
	}

	.link-btn {
		display: inline-block;
		padding: var(--space-2) var(--space-4);
		background: var(--color-primary);
		color: var(--color-white);
		border-radius: var(--radius-md);
		text-decoration: none;
		font-weight: var(--font-medium);
	}

	.message-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
	}

	.message-card {
		display: block;
		background: var(--bg-card);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		text-decoration: none;
		color: inherit;
		transition: border-color var(--transition-fast);
	}

	.message-card:hover {
		border-color: var(--color-primary);
	}

	.message-header {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		margin-bottom: var(--space-2);
	}

	.sender {
		font-weight: var(--font-semibold);
		color: var(--text-primary);
	}

	.type-badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		background: var(--bg-muted);
		border-radius: var(--radius-full);
		color: var(--text-secondary);
	}

	.timestamp {
		margin-left: auto;
		font-size: var(--text-sm);
		color: var(--text-tertiary);
	}

	.message-text {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin-bottom: var(--space-2);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.shared-caption {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		font-style: italic;
		margin-bottom: var(--space-2);
	}

	.urls-section {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		margin-top: var(--space-2);
		padding-top: var(--space-2);
		border-top: var(--border-width-thin) solid var(--border-default);
	}

	.extracted-url {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		font-size: var(--text-sm);
	}

	.parse-status {
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		white-space: nowrap;
	}

	.status-success {
		background: var(--color-green-100);
		color: var(--color-green-700);
	}

	.status-failed {
		background: var(--color-red-100);
		color: var(--color-red-700);
	}

	.status-pending {
		background: var(--color-yellow-100);
		color: var(--color-yellow-700);
	}

	.recipe-title {
		font-weight: var(--font-medium);
		color: var(--text-primary);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		flex: 1;
	}

	.url-text {
		color: var(--text-tertiary);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		flex: 1;
	}

	.save-btn {
		padding: var(--space-1) var(--space-3);
		background: var(--color-primary);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		cursor: pointer;
		white-space: nowrap;
	}

	.save-btn:hover {
		opacity: 0.9;
	}

	.saved-link {
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		color: var(--color-primary);
		white-space: nowrap;
	}
</style>
