<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, tags as tagsApi, type Recipe, type Tag, type Ingredient, type Instruction } from '$lib/api/client';

	let recipe = $state<Recipe | null>(null);
	let allTags = $state<Tag[]>([]);
	let loading = $state(true);
	let saving = $state(false);
	let error = $state('');

	// Form state
	let title = $state('');
	let description = $state('');
	let sourceUrl = $state('');
	let imageUrl = $state('');
	let prepTime = $state<number | null>(null);
	let cookTime = $state<number | null>(null);
	let totalTime = $state<number | null>(null);
	let servings = $state('');
	let notes = $state('');
	let ingredients = $state<string[]>([]);
	let instructions = $state<string[]>([]);
	let selectedTagIds = $state<string[]>([]);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		const token = authStore.getToken();
		const recipeId = $page.params.id;
		if (!token || !recipeId) return;

		try {
			const [recipeResult, tagsResult] = await Promise.all([
				recipes.get(token, recipeId),
				tagsApi.list(token)
			]);

			recipe = recipeResult.data;
			allTags = tagsResult.data;

			// Populate form
			title = recipe.title;
			description = recipe.description || '';
			sourceUrl = recipe.source_url || '';
			imageUrl = recipe.image_url || '';
			prepTime = recipe.prep_time_minutes;
			cookTime = recipe.cook_time_minutes;
			totalTime = recipe.total_time_minutes;
			servings = recipe.servings || '';
			notes = recipe.notes || '';
			ingredients = recipe.ingredients.map((i) => i.text);
			instructions = recipe.instructions.map((i) => i.text);
			selectedTagIds = recipe.tags.map((t) => t.id);
		} catch {
			error = 'Recipe not found';
		} finally {
			loading = false;
		}
	});

	async function handleSubmit(e: Event) {
		e.preventDefault();
		if (!recipe) return;

		const token = authStore.getToken();
		if (!token) return;

		saving = true;
		error = '';

		try {
			await recipes.update(token, recipe.id, {
				title,
				description: description || undefined,
				source_url: sourceUrl || undefined,
				image_url: imageUrl || undefined,
				prep_time_minutes: prepTime || undefined,
				cook_time_minutes: cookTime || undefined,
				total_time_minutes: totalTime || undefined,
				servings: servings || undefined,
				notes: notes || undefined,
				ingredients: ingredients.filter((i) => i.trim()).map((text) => ({ text, group: null })),
				instructions: instructions.filter((i) => i.trim()).map((text, idx) => ({ step: idx + 1, text })),
				tag_ids: selectedTagIds
			});

			goto(`/recipes/${recipe.id}`);
		} catch (e) {
			error = 'Failed to save recipe';
		} finally {
			saving = false;
		}
	}

	function addIngredient() {
		ingredients = [...ingredients, ''];
	}

	function removeIngredient(index: number) {
		ingredients = ingredients.filter((_, i) => i !== index);
	}

	function addInstruction() {
		instructions = [...instructions, ''];
	}

	function removeInstruction(index: number) {
		instructions = instructions.filter((_, i) => i !== index);
	}

	function toggleTag(tagId: string) {
		if (selectedTagIds.includes(tagId)) {
			selectedTagIds = selectedTagIds.filter((id) => id !== tagId);
		} else {
			selectedTagIds = [...selectedTagIds, tagId];
		}
	}
</script>

{#if loading}
	<div class="loading">Loading recipe...</div>
{:else if error && !recipe}
	<div class="error">
		<p>{error}</p>
		<a href="/recipes">Back to recipes</a>
	</div>
{:else if recipe}
	<div class="edit-recipe">
		<header>
			<h1>Edit Recipe</h1>
			<a href="/recipes/{recipe.id}" class="btn">Cancel</a>
		</header>

		{#if error}
			<div class="error-message">{error}</div>
		{/if}

		<form onsubmit={handleSubmit}>
			<div class="form-group">
				<label for="title">Title *</label>
				<input type="text" id="title" bind:value={title} required />
			</div>

			<div class="form-group">
				<label for="description">Description</label>
				<textarea id="description" bind:value={description} rows="3"></textarea>
			</div>

			<div class="form-row">
				<div class="form-group">
					<label for="sourceUrl">Source URL</label>
					<input type="url" id="sourceUrl" bind:value={sourceUrl} />
				</div>

				<div class="form-group">
					<label for="imageUrl">Image URL</label>
					<input type="url" id="imageUrl" bind:value={imageUrl} />
				</div>
			</div>

			<div class="form-row times">
				<div class="form-group">
					<label for="prepTime">Prep Time (min)</label>
					<input type="number" id="prepTime" bind:value={prepTime} min="0" />
				</div>

				<div class="form-group">
					<label for="cookTime">Cook Time (min)</label>
					<input type="number" id="cookTime" bind:value={cookTime} min="0" />
				</div>

				<div class="form-group">
					<label for="totalTime">Total Time (min)</label>
					<input type="number" id="totalTime" bind:value={totalTime} min="0" />
				</div>

				<div class="form-group">
					<label for="servings">Servings</label>
					<input type="text" id="servings" bind:value={servings} />
				</div>
			</div>

			<div class="form-group">
				<span class="form-label">Tags</span>
				<div class="tags-list">
					{#each allTags as tag}
						<button
							type="button"
							class="tag-btn"
							class:selected={selectedTagIds.includes(tag.id)}
							onclick={() => toggleTag(tag.id)}
						>
							{tag.name}
						</button>
					{/each}
				</div>
			</div>

			<div class="form-group">
				<div class="section-header">
					<span class="form-label">Ingredients</span>
					<button type="button" class="btn btn-sm" onclick={addIngredient}>+ Add</button>
				</div>
				<div class="list-items">
					{#each ingredients as ingredient, index}
						<div class="list-item">
							<input
								type="text"
								bind:value={ingredients[index]}
								placeholder="e.g., 1 cup flour"
							/>
							<button type="button" class="btn-remove" onclick={() => removeIngredient(index)}>×</button>
						</div>
					{/each}
				</div>
			</div>

			<div class="form-group">
				<div class="section-header">
					<span class="form-label">Instructions</span>
					<button type="button" class="btn btn-sm" onclick={addInstruction}>+ Add</button>
				</div>
				<div class="list-items">
					{#each instructions as instruction, index}
						<div class="list-item instruction-item">
							<span class="step-number">{index + 1}.</span>
							<textarea
								bind:value={instructions[index]}
								placeholder="Describe this step..."
								rows="2"
							></textarea>
							<button type="button" class="btn-remove" onclick={() => removeInstruction(index)}>×</button>
						</div>
					{/each}
				</div>
			</div>

			<div class="form-group">
				<label for="notes">Notes</label>
				<textarea id="notes" bind:value={notes} rows="3"></textarea>
			</div>

			<div class="form-actions">
				<a href="/recipes/{recipe.id}" class="btn">Cancel</a>
				<button type="submit" class="btn btn-primary" disabled={saving}>
					{saving ? 'Saving...' : 'Save Changes'}
				</button>
			</div>
		</form>
	</div>
{/if}

<style>
	.loading,
	.error {
		text-align: center;
		padding: var(--space-12);
	}

	.error a {
		color: var(--color-marinara-600);
	}

	.edit-recipe {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
		max-width: 800px;
		margin: 0 auto;
	}

	header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-8);
		padding-bottom: var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	h1 {
		margin: 0;
		font-size: var(--text-2xl);
		color: var(--color-marinara-800);
	}

	.error-message {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-4);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
	}

	.form-group {
		margin-bottom: var(--space-6);
	}

	label,
	.form-label {
		display: block;
		font-weight: var(--font-medium);
		margin-bottom: var(--space-2);
		color: var(--text-primary);
	}

	input[type='text'],
	input[type='url'],
	input[type='number'],
	textarea {
		width: 100%;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-family: inherit;
		transition: all var(--transition-fast);
	}

	input:focus,
	textarea:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.form-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-4);
	}

	.form-row.times {
		grid-template-columns: repeat(4, 1fr);
	}

	@media (max-width: 600px) {
		.form-row,
		.form-row.times {
			grid-template-columns: 1fr;
		}
	}

	.tags-list {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
	}

	.tag-btn {
		padding: var(--space-2) var(--space-4);
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-full);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all var(--transition-normal);
	}

	.tag-btn:hover {
		border-color: var(--color-marinara-500);
	}

	.tag-btn.selected {
		background: var(--color-marinara-500);
		color: var(--color-white);
		border-color: var(--color-marinara-500);
	}

	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-2);
	}

	.section-header .form-label {
		margin-bottom: 0;
	}

	.list-items {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.list-item {
		display: flex;
		gap: var(--space-2);
		align-items: flex-start;
	}

	.list-item input,
	.list-item textarea {
		flex: 1;
	}

	.instruction-item {
		align-items: flex-start;
	}

	.step-number {
		padding-top: var(--space-3);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
		min-width: 2rem;
	}

	.btn-remove {
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-thin) solid var(--color-marinara-600);
		background: var(--bg-card);
		color: var(--color-marinara-600);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-xl);
		line-height: 1;
		transition: all var(--transition-fast);
	}

	.btn-remove:hover {
		background: var(--color-marinara-600);
		color: var(--color-white);
	}

	.btn {
		padding: var(--space-2) var(--space-4);
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		text-decoration: none;
		color: var(--text-primary);
		cursor: pointer;
		font-size: var(--text-sm);
		transition: all var(--transition-fast);
	}

	.btn:hover {
		background: var(--bg-surface);
	}

	.btn-sm {
		padding: var(--space-1) var(--space-3);
		font-size: var(--text-sm);
	}

	.btn-primary {
		background: var(--color-marinara-500);
		color: var(--color-white);
		border-color: var(--color-marinara-500);
	}

	.btn-primary:hover {
		background: var(--color-marinara-600);
	}

	.btn-primary:disabled {
		background: var(--color-gray-400);
		border-color: var(--color-gray-400);
		cursor: not-allowed;
	}

	.form-actions {
		display: flex;
		justify-content: flex-end;
		gap: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}
</style>
