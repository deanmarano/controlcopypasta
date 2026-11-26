<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';

	// Browsed recipes used to have their own page here. They now use the same
	// page as saved recipes; this route only forwards old links and bookmarks.
	onMount(() => {
		const { domain, id } = $page.params;
		goto(`/recipes/${id}?from=${encodeURIComponent(domain ?? '')}`, { replaceState: true });
	});
</script>

<div class="loading">Loading recipe...</div>

<style>
	.loading {
		text-align: center;
		padding: var(--space-12);
		color: var(--text-secondary);
	}
</style>
