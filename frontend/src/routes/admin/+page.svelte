<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated, isAdmin } from '$lib/stores/auth';

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else if (!$isAdmin) {
			goto('/');
		}
	});
</script>

<div class="admin-page">
	<h1>Admin</h1>

	<div class="admin-sections">
		<a href="/admin/ingredients" class="admin-card">
			<h2>Ingredients</h2>
			<p>Set animal types, categories, and allergen groups for canonical ingredients.</p>
		</a>

		<a href="/admin/preparations" class="admin-card">
			<h2>Preparations</h2>
			<p>Manage preparation words used by the recipe parser (dice, chop, mince, etc.)</p>
		</a>

		<a href="/admin/tools" class="admin-card">
			<h2>Kitchen Tools</h2>
			<p>Manage kitchen tools and equipment referenced by preparations (knife, grater, whisk, etc.)</p>
		</a>

		<a href="/admin/pending-ingredients" class="admin-card">
			<h2>Pending Ingredients</h2>
			<p>Review and approve new ingredients discovered from recipes.</p>
		</a>

		<a href="/setup" class="admin-card">
			<h2>Setup Wizard</h2>
			<p>Preview the new user onboarding flow for dietary preferences.</p>
		</a>
	</div>
</div>

<style>
	.admin-page {
		max-width: 800px;
	}

	h1 {
		margin: 0 0 var(--space-8);
		color: var(--color-marinara-800);
	}

	.admin-sections {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: var(--space-6);
	}

	.admin-card {
		display: block;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-fast);
		border: 2px solid transparent;
	}

	.admin-card:hover {
		border-color: var(--color-pasta-300);
		box-shadow: var(--shadow-lg);
		transform: translateY(-2px);
	}

	.admin-card h2 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
	}

	.admin-card p {
		margin: 0;
		color: var(--text-secondary);
		font-size: var(--text-sm);
		line-height: 1.5;
	}
</style>
