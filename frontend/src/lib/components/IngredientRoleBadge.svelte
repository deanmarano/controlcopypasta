<script lang="ts">
	import type { Ingredient } from '$lib/api/client';

	let { ingredient }: { ingredient: Ingredient } = $props();

	// The backend omits the defaults, so an absent role is the ordinary case and
	// there is nothing to show. Optionality is independent of role: a line can be
	// both ("sherry (for serving; optional)"), so both badges can appear.
	const ROLE_LABELS: Record<string, string> = {
		serving: 'to serve',
		garnish: 'garnish',
		to_taste: 'to taste',
		cooking_medium: 'for cooking'
	};

	let roleLabel = $derived(ingredient.role ? ROLE_LABELS[ingredient.role] : null);

	// The matched words, shown on hover. Without this the badge is an assertion
	// the reader has no way to check.
	let title = $derived(
		ingredient.role_markers?.length ? `Matched: ${ingredient.role_markers.join(', ')}` : undefined
	);
</script>

{#if ingredient.optional}
	<span class="role-badge optional" {title}>optional</span>
{/if}
{#if roleLabel}
	<span class="role-badge" {title}>{roleLabel}</span>
{/if}

<style>
	.role-badge {
		display: inline-block;
		margin-left: 0.5rem;
		padding: 0.05rem 0.4rem;
		border: 1px solid var(--color-border, #d4d4d8);
		border-radius: 999px;
		font-size: 0.7rem;
		line-height: 1.5;
		text-transform: lowercase;
		white-space: nowrap;
		color: var(--color-text-muted, #71717a);
		vertical-align: middle;
	}

	.role-badge.optional {
		font-style: italic;
	}

	/* The badge annotates the ingredient; on paper the text itself is enough and
	   the recipe should not carry parser vocabulary. */
	@media print {
		.role-badge {
			display: none;
		}
	}
</style>
