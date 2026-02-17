<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { tags as tagsApi, type Tag } from '$lib/api/client';

	let tagList = $state<Tag[]>([]);
	let newTagName = $state('');
	let loading = $state(true);
	let creating = $state(false);
	let error = $state('');

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		await loadTags();
	});

	async function loadTags() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const result = await tagsApi.list(token);
			tagList = result.data;
		} catch {
			error = 'Failed to load tags';
		} finally {
			loading = false;
		}
	}

	async function createTag(e: Event) {
		e.preventDefault();
		if (!newTagName.trim()) return;

		const token = authStore.getToken();
		if (!token) return;

		creating = true;
		error = '';

		try {
			const result = await tagsApi.create(token, newTagName.trim());
			tagList = [...tagList, result.data].sort((a, b) => a.name.localeCompare(b.name));
			newTagName = '';
		} catch (err: unknown) {
			if (err && typeof err === 'object' && 'data' in err) {
				const apiErr = err as { data: { errors?: { name?: string[] } } };
				error = apiErr.data?.errors?.name?.[0] || 'Failed to create tag';
			} else {
				error = 'Failed to create tag';
			}
		} finally {
			creating = false;
		}
	}

	async function deleteTag(id: string) {
		if (!confirm('Are you sure you want to delete this tag?')) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			await tagsApi.delete(token, id);
			tagList = tagList.filter((t) => t.id !== id);
		} catch {
			alert('Failed to delete tag');
		}
	}
</script>

<div class="tags-page">
	<h1>Manage Tags</h1>

	<form class="new-tag-form" onsubmit={createTag}>
		<input
			type="text"
			bind:value={newTagName}
			placeholder="New tag name..."
			disabled={creating}
		/>
		<button type="submit" disabled={creating || !newTagName.trim()}>
			{creating ? 'Adding...' : 'Add Tag'}
		</button>
	</form>

	{#if error}
		<div class="error">{error}</div>
	{/if}

	{#if loading}
		<div class="loading">Loading tags...</div>
	{:else if tagList.length === 0}
		<div class="empty">
			<p>No tags yet. Create your first tag above!</p>
		</div>
	{:else}
		<ul class="tag-list">
			{#each tagList as tag}
				<li>
					<span class="tag-name">{tag.name}</span>
					<button onclick={() => deleteTag(tag.id)} class="delete-btn" title="Delete tag">
						&times;
					</button>
				</li>
			{/each}
		</ul>
	{/if}
</div>

<style>
	.tags-page {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
		max-width: 600px;
	}

	h1 {
		margin: 0 0 var(--space-6);
		color: var(--color-marinara-800);
	}

	.new-tag-form {
		display: flex;
		gap: var(--space-2);
		margin-bottom: var(--space-6);
	}

	.new-tag-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.new-tag-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.new-tag-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.new-tag-form button:hover:not(:disabled) {
		background: var(--color-marinara-700);
	}

	.new-tag-form button:disabled {
		background: var(--color-gray-400);
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
	}

	.loading,
	.empty {
		text-align: center;
		padding: var(--space-8);
		color: var(--text-secondary);
	}

	.tag-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.tag-list li {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.tag-list li:last-child {
		border-bottom: none;
	}

	.tag-name {
		font-size: var(--text-base);
	}

	.delete-btn {
		background: none;
		border: none;
		color: var(--text-muted);
		font-size: var(--text-2xl);
		cursor: pointer;
		padding: 0;
		line-height: 1;
		transition: all var(--transition-fast);
	}

	.delete-btn:hover {
		color: #c53030;
	}
</style>
