<script lang="ts">
	import { onMount } from 'svelte';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { messages, type DirectMessage } from '$lib/api/client';

	let message = $state<DirectMessage | null>(null);
	let loading = $state(true);
	let error = $state<string | null>(null);
	let savingUrlId = $state<string | null>(null);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await loadMessage();
	});

	async function loadMessage() {
		const token = authStore.getToken();
		if (!token) return;

		const id = $page.params.id;

		try {
			loading = true;
			error = null;
			const result = await messages.get(token, id);
			message = result.data;
		} catch (e) {
			error = 'Failed to load message';
			console.error(e);
		} finally {
			loading = false;
		}
	}

	function formatTimestamp(ts: string | null): string {
		if (!ts) return '';
		const date = new Date(ts);
		return date.toLocaleString(undefined, {
			year: 'numeric',
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

	async function handleSaveRecipe(urlId: string) {
		const token = authStore.getToken();
		if (!token || !message) return;

		try {
			savingUrlId = urlId;
			const result = await messages.saveRecipe(token, message.id, urlId);
			goto(`/recipes/${result.data.recipe_id}`);
		} catch (e) {
			console.error('Failed to save recipe:', e);
			savingUrlId = null;
		}
	}
</script>

<svelte:head>
	<title>Message from @{message?.sender_username ?? '...'} - ControlCopyPasta</title>
</svelte:head>

<div class="message-detail">
	<a href="/messages" class="back-link">Back to Messages</a>

	{#if loading}
		<div class="loading">Loading message...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if message}
		<div class="message-card">
			<div class="message-header">
				<h1>@{message.sender_username}</h1>
				<span class="type-badge">{messageTypeLabel(message.message_type)}</span>
				<span class="timestamp">{formatTimestamp(message.platform_timestamp || message.inserted_at)}</span>
			</div>

			{#if message.message_text}
				<div class="message-body">
					<p>{message.message_text}</p>
				</div>
			{/if}

			{#if message.shared_content}
				<div class="shared-content-card">
					<div class="shared-content-header">
						{#if message.shared_content.original_author}
							<span class="author">@{message.shared_content.original_author}</span>
						{/if}
						{#if message.shared_content.url}
							<a href={message.shared_content.url} target="_blank" rel="noopener" class="view-on-ig">View on Instagram</a>
						{/if}
					</div>

					{#if message.shared_content.caption}
						<div class="caption-block">
							<p class="caption-text">{message.shared_content.caption}</p>
						</div>
					{/if}

					{#if message.shared_content.comments?.length > 0}
						<div class="comments-section">
							<h3>Comments ({message.shared_content.comments.length}{#if message.shared_content.comment_count && message.shared_content.comment_count > message.shared_content.comments.length} of {message.shared_content.comment_count}{/if})</h3>
							{#each message.shared_content.comments as comment}
								<div class="comment">
									<span class="comment-author">@{comment.username}</span>
									<p class="comment-text">{comment.text}</p>
								</div>
							{/each}
						</div>
					{:else if !message.shared_content.caption}
						{#if message.shared_content.url}
							<a href={message.shared_content.url} target="_blank" rel="noopener" class="external-link">{message.shared_content.url}</a>
						{/if}
					{/if}
				</div>
			{/if}

			{#if message.forwarded_content}
				<div class="content-block">
					<h3>Forwarded Message</h3>
					{#if message.forwarded_content.original_sender}
						<p class="meta">Originally from: @{message.forwarded_content.original_sender}</p>
					{/if}
					{#if message.forwarded_content.original_text}
						<p class="caption-text">{message.forwarded_content.original_text}</p>
					{/if}
					{#if message.forwarded_content.original_url}
						<a href={message.forwarded_content.original_url} target="_blank" rel="noopener" class="external-link">{message.forwarded_content.original_url}</a>
					{/if}
				</div>
			{/if}

			{#if message.extracted_urls.length > 0}
				<div class="urls-section">
					<h3>Extracted URLs</h3>
					{#each message.extracted_urls as eu}
						<div class="url-card">
							<div class="url-header">
								<span class="parse-status {eu.parse_status}">
									{#if eu.parse_status === 'success'}Parsed{:else if eu.parse_status === 'failed'}Failed{:else}Parsing...{/if}
								</span>
								<span class="url-source">from {eu.source.replace('_', ' ')}</span>
							</div>

							<a href={eu.url} target="_blank" rel="noopener" class="url-link">{eu.url}</a>

							{#if eu.recipe_title}
								<p class="recipe-title">{eu.recipe_title}</p>
							{/if}

							{#if eu.parse_error}
								<p class="parse-error">{eu.parse_error}</p>
							{/if}

							<div class="url-actions">
								{#if eu.recipe_id}
									<a href="/recipes/{eu.recipe_id}" class="btn btn-secondary">View Saved Recipe</a>
								{:else if eu.parse_status === 'success'}
									<button
										class="btn btn-primary"
										onclick={() => handleSaveRecipe(eu.id)}
										disabled={savingUrlId === eu.id}
									>
										{savingUrlId === eu.id ? 'Saving...' : 'Save Recipe'}
									</button>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{/if}

			{#if message.processed_at}
				<p class="processed-at">Processed {formatTimestamp(message.processed_at)}</p>
			{/if}
		</div>
	{/if}
</div>

<style>
	.message-detail {
		max-width: 800px;
		margin: 0 auto;
	}

	.back-link {
		display: inline-block;
		margin-bottom: var(--space-4);
		color: var(--color-primary);
		text-decoration: none;
		font-size: var(--text-sm);
	}

	.back-link:hover {
		text-decoration: underline;
	}

	.loading, .error {
		text-align: center;
		padding: var(--space-8);
		color: var(--text-secondary);
	}

	.error {
		color: var(--color-red-600);
	}

	.message-card {
		background: var(--bg-card);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
	}

	.message-header {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		margin-bottom: var(--space-4);
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		margin: 0;
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

	.message-body {
		margin-bottom: var(--space-4);
		line-height: var(--leading-relaxed);
	}

	.shared-content-card {
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-md);
		overflow: hidden;
		margin-bottom: var(--space-4);
	}

	.shared-content-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: var(--space-3) var(--space-4);
		background: var(--bg-muted);
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.author {
		font-weight: var(--font-semibold);
		font-size: var(--text-sm);
	}

	.view-on-ig {
		font-size: var(--text-xs);
		color: var(--color-primary);
		text-decoration: none;
	}

	.view-on-ig:hover {
		text-decoration: underline;
	}

	.caption-block {
		padding: var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.caption-text {
		font-size: var(--text-sm);
		line-height: var(--leading-relaxed);
		white-space: pre-wrap;
	}

	.comments-section {
		padding: var(--space-4);
	}

	.comments-section h3 {
		font-size: var(--text-sm);
		font-weight: var(--font-semibold);
		color: var(--text-tertiary);
		margin-bottom: var(--space-3);
	}

	.comment {
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--border-default);
	}

	.comment:last-child {
		border-bottom: none;
	}

	.comment-author {
		font-weight: var(--font-semibold);
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.comment-text {
		font-size: var(--text-sm);
		line-height: var(--leading-relaxed);
		margin-top: var(--space-1);
		white-space: pre-wrap;
	}

	.content-block {
		background: var(--bg-muted);
		border-radius: var(--radius-md);
		padding: var(--space-4);
		margin-bottom: var(--space-4);
	}

	.content-block h3 {
		font-size: var(--text-sm);
		font-weight: var(--font-semibold);
		text-transform: uppercase;
		letter-spacing: 0.05em;
		color: var(--text-tertiary);
		margin-bottom: var(--space-2);
	}

	.meta {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		margin-bottom: var(--space-1);
	}

	.external-link {
		font-size: var(--text-sm);
		color: var(--color-primary);
		word-break: break-all;
	}

	.urls-section {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-default);
	}

	.urls-section h3 {
		font-size: var(--text-lg);
		margin-bottom: var(--space-3);
	}

	.url-card {
		background: var(--bg-muted);
		border-radius: var(--radius-md);
		padding: var(--space-4);
		margin-bottom: var(--space-3);
	}

	.url-header {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		margin-bottom: var(--space-2);
	}

	.parse-status {
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
	}

	.parse-status.success {
		background: var(--color-green-100);
		color: var(--color-green-700);
	}

	.parse-status.failed {
		background: var(--color-red-100);
		color: var(--color-red-700);
	}

	.parse-status.pending {
		background: var(--color-yellow-100);
		color: var(--color-yellow-700);
	}

	.url-source {
		font-size: var(--text-xs);
		color: var(--text-tertiary);
	}

	.url-link {
		display: block;
		font-size: var(--text-sm);
		color: var(--color-primary);
		word-break: break-all;
		margin-bottom: var(--space-2);
	}

	.recipe-title {
		font-weight: var(--font-semibold);
		font-size: var(--text-lg);
		margin-bottom: var(--space-2);
	}

	.parse-error {
		font-size: var(--text-sm);
		color: var(--color-red-600);
		margin-bottom: var(--space-2);
	}

	.url-actions {
		margin-top: var(--space-2);
	}

	.btn {
		display: inline-block;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		text-decoration: none;
		cursor: pointer;
		border: none;
	}

	.btn-primary {
		background: var(--color-primary);
		color: var(--color-white);
	}

	.btn-primary:hover:not(:disabled) {
		opacity: 0.9;
	}

	.btn-primary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.btn-secondary {
		background: transparent;
		border: var(--border-width-thin) solid var(--color-primary);
		color: var(--color-primary);
	}

	.btn-secondary:hover {
		background: var(--color-primary);
		color: var(--color-white);
	}

	.processed-at {
		margin-top: var(--space-4);
		font-size: var(--text-xs);
		color: var(--text-tertiary);
		text-align: right;
	}
</style>
