<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, tags as tagsApi, type RecipeInput, type Tag } from '$lib/api/client';

	let title = $state('');
	let description = $state('');
	let sourceUrl = $state('');
	let imageUrl = $state('');
	let ingredientsText = $state('');
	let instructionsText = $state('');
	let prepTime = $state<number | undefined>();
	let cookTime = $state<number | undefined>();
	let totalTime = $state<number | undefined>();
	let servings = $state('');
	let notes = $state('');
	let selectedTags = $state<string[]>([]);

	let availableTags = $state<Tag[]>([]);
	let loading = $state(false);
	let parsing = $state(false);
	let error = $state('');
	let parseUrl = $state('');

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		} else {
			loadTags();
		}
	});

	async function loadTags() {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await tagsApi.list(token);
			availableTags = result.data;
		} catch {
			// Ignore tag loading errors
		}
	}

	async function handleParse() {
		if (!parseUrl) return;

		const token = authStore.getToken();
		if (!token) return;

		parsing = true;
		error = '';

		try {
			const result = await recipes.parse(token, parseUrl);
			const data = result.data;

			title = data.title || '';
			description = data.description || '';
			sourceUrl = data.source_url || parseUrl;
			imageUrl = data.image_url || '';
			ingredientsText = (data.ingredients || []).map((i) => i.text).join('\n');
			instructionsText = (data.instructions || []).map((i) => i.text).join('\n\n');
			prepTime = data.prep_time_minutes || undefined;
			cookTime = data.cook_time_minutes || undefined;
			totalTime = data.total_time_minutes || undefined;
			servings = data.servings || '';
		} catch (err: unknown) {
			if (err && typeof err === 'object' && 'data' in err) {
				const apiErr = err as { data: { error?: { message?: string } } };
				error = apiErr.data?.error?.message || 'Failed to parse recipe from URL';
			} else {
				error = 'Failed to parse recipe from URL';
			}
		} finally {
			parsing = false;
		}
	}

	async function handleSubmit(e: Event) {
		e.preventDefault();

		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';

		try {
			const recipe: RecipeInput = {
				title,
				description: description || undefined,
				source_url: sourceUrl || undefined,
				image_url: imageUrl || undefined,
				ingredients: ingredientsText
					.split('\n')
					.filter((l) => l.trim())
					.map((text) => ({ text: text.trim(), group: null })),
				instructions: instructionsText
					.split('\n\n')
					.filter((l) => l.trim())
					.map((text, i) => ({ step: i + 1, text: text.trim() })),
				prep_time_minutes: prepTime,
				cook_time_minutes: cookTime,
				total_time_minutes: totalTime,
				servings: servings || undefined,
				notes: notes || undefined,
				tag_ids: selectedTags.length > 0 ? selectedTags : undefined
			};

			const result = await recipes.create(token, recipe);
			goto(`/recipes/${result.data.id}`);
		} catch (err: unknown) {
			if (err && typeof err === 'object' && 'data' in err) {
				const apiErr = err as { data: { errors?: Record<string, string[]> } };
				error = Object.values(apiErr.data?.errors || {})
					.flat()
					.join(', ') || 'Failed to create recipe';
			} else {
				error = 'Failed to create recipe';
			}
		} finally {
			loading = false;
		}
	}
</script>

<div class="new-recipe-page">
	<h1>Add New Recipe</h1>

	<section class="parse-section">
		<h2>Import from URL</h2>
		<div class="parse-form">
			<input
				type="url"
				bind:value={parseUrl}
				placeholder="Paste a recipe URL to import..."
				disabled={parsing}
			/>
			<button onclick={handleParse} disabled={parsing || !parseUrl}>
				{parsing ? 'Parsing...' : 'Import'}
			</button>
		</div>
	</section>

	{#if error}
		<div class="error">{error}</div>
	{/if}

	<form onsubmit={handleSubmit}>
		<div class="form-group">
			<label for="title">Title *</label>
			<input type="text" id="title" bind:value={title} required disabled={loading} />
		</div>

		<div class="form-group">
			<label for="description">Description</label>
			<textarea id="description" bind:value={description} rows="2" disabled={loading}></textarea>
		</div>

		<div class="form-row">
			<div class="form-group">
				<label for="sourceUrl">Source URL</label>
				<input type="url" id="sourceUrl" bind:value={sourceUrl} disabled={loading} />
			</div>
			<div class="form-group">
				<label for="imageUrl">Image URL</label>
				<input type="url" id="imageUrl" bind:value={imageUrl} disabled={loading} />
			</div>
		</div>

		<div class="form-row time-row">
			<div class="form-group">
				<label for="prepTime">Prep Time (min)</label>
				<input type="number" id="prepTime" bind:value={prepTime} min="0" disabled={loading} />
			</div>
			<div class="form-group">
				<label for="cookTime">Cook Time (min)</label>
				<input type="number" id="cookTime" bind:value={cookTime} min="0" disabled={loading} />
			</div>
			<div class="form-group">
				<label for="totalTime">Total Time (min)</label>
				<input type="number" id="totalTime" bind:value={totalTime} min="0" disabled={loading} />
			</div>
			<div class="form-group">
				<label for="servings">Servings</label>
				<input type="text" id="servings" bind:value={servings} disabled={loading} />
			</div>
		</div>

		<div class="form-group">
			<label for="ingredients">Ingredients (one per line)</label>
			<textarea
				id="ingredients"
				bind:value={ingredientsText}
				rows="8"
				placeholder="1 cup flour&#10;2 eggs&#10;1 tsp salt"
				disabled={loading}
			></textarea>
		</div>

		<div class="form-group">
			<label for="instructions">Instructions (separate steps with blank line)</label>
			<textarea
				id="instructions"
				bind:value={instructionsText}
				rows="10"
				placeholder="Preheat oven to 350F.&#10;&#10;Mix dry ingredients in a bowl.&#10;&#10;Add wet ingredients and stir."
				disabled={loading}
			></textarea>
		</div>

		{#if availableTags.length > 0}
			<div class="form-group">
				<label>Tags</label>
				<div class="tag-selector">
					{#each availableTags as tag}
						<label class="tag-option">
							<input
								type="checkbox"
								value={tag.id}
								checked={selectedTags.includes(tag.id)}
								onchange={(e) => {
									const target = e.target as HTMLInputElement;
									if (target.checked) {
										selectedTags = [...selectedTags, tag.id];
									} else {
										selectedTags = selectedTags.filter((id) => id !== tag.id);
									}
								}}
								disabled={loading}
							/>
							{tag.name}
						</label>
					{/each}
				</div>
			</div>
		{/if}

		<div class="form-group">
			<label for="notes">Notes</label>
			<textarea id="notes" bind:value={notes} rows="3" disabled={loading}></textarea>
		</div>

		<div class="form-actions">
			<a href="/recipes" class="btn-cancel">Cancel</a>
			<button type="submit" disabled={loading || !title}>
				{loading ? 'Saving...' : 'Save Recipe'}
			</button>
		</div>
	</form>
</div>

<style>
	.new-recipe-page {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
	}

	h1 {
		margin: 0 0 var(--space-6);
		color: var(--color-marinara-800);
	}

	.parse-section {
		background: var(--color-pasta-100);
		padding: var(--space-6);
		border-radius: var(--radius-lg);
		margin-bottom: var(--space-8);
	}

	.parse-section h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-lg);
		color: var(--color-marinara-700);
	}

	.parse-form {
		display: flex;
		gap: var(--space-2);
	}

	.parse-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
	}

	.parse-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	.parse-form button {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.parse-form button:hover:not(:disabled) {
		background: var(--color-marinara-600);
	}

	.parse-form button:disabled {
		background: var(--color-gray-400);
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-4);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-6);
		border-left: var(--border-width-thick) solid var(--color-error);
	}

	.form-group {
		margin-bottom: var(--space-6);
	}

	.form-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-4);
	}

	.time-row {
		grid-template-columns: repeat(4, 1fr);
	}

	@media (max-width: 768px) {
		.form-row,
		.time-row {
			grid-template-columns: 1fr;
		}
	}

	label {
		display: block;
		margin-bottom: var(--space-2);
		font-weight: var(--font-medium);
		color: var(--text-primary);
	}

	input,
	textarea {
		width: 100%;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-family: inherit;
		box-sizing: border-box;
		transition: all var(--transition-fast);
	}

	input:focus,
	textarea:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(220, 74, 61, 0.15);
	}

	textarea {
		resize: vertical;
	}

	.tag-selector {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-4);
	}

	.tag-option {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		font-weight: var(--font-normal);
	}

	.form-actions {
		display: flex;
		justify-content: flex-end;
		gap: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.btn-cancel {
		padding: var(--space-3) var(--space-6);
		color: var(--text-secondary);
		text-decoration: none;
	}

	.btn-cancel:hover {
		color: var(--text-primary);
	}

	.form-actions button {
		padding: var(--space-3) var(--space-8);
		background: var(--color-basil-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
	}

	.form-actions button:hover:not(:disabled) {
		background: var(--color-basil-600);
		box-shadow: var(--shadow-basil);
	}

	.form-actions button:disabled {
		background: var(--color-gray-400);
	}
</style>
