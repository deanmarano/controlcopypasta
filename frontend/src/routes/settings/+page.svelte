<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import {
		avoidedIngredients,
		settings,
		ingredients,
		type AvoidedIngredient,
		type AvoidanceOptions,
		type UserPreferences,
		type CanonicalIngredient,
		type AvoidanceIngredientsResponse
	} from '$lib/api/client';

	let items = $state<AvoidedIngredient[]>([]);
	let options = $state<AvoidanceOptions | null>(null);
	let preferences = $state<UserPreferences | null>(null);
	let loading = $state(true);
	let error = $state('');

	// Text-based ingredient input (legacy)
	let newIngredient = $state('');
	let adding = $state(false);

	// Ingredient search
	let ingredientSearch = $state('');
	let searchResults = $state<CanonicalIngredient[]>([]);
	let searchLoading = $state(false);
	let showSearchResults = $state(false);

	// Category selection
	let selectedCategory = $state('');

	// Allergen selection
	let selectedAllergen = $state('');

	// Animal type grouped selection
	let animalToggles = $state<Record<string, boolean>>({});

	// Preference toggle
	let savingPreferences = $state(false);

	// Expanded category/allergen view
	let expandedAvoidanceId = $state<string | null>(null);
	let expandedIngredients = $state<AvoidanceIngredientsResponse | null>(null);
	let expandedLoading = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await Promise.all([loadItems(), loadOptions(), loadPreferences()]);
	});

	async function loadItems() {
		const token = authStore.getToken();
		if (!token) return;
		loading = true;
		error = '';
		try {
			const result = await avoidedIngredients.list(token);
			items = result.data;
		} catch {
			error = 'Failed to load dietary preferences';
		} finally {
			loading = false;
		}
	}

	async function loadOptions() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			options = await avoidedIngredients.options(token);
		} catch {
			// Options are optional, fail silently
		}
	}

	async function loadPreferences() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await settings.getPreferences(token);
			preferences = result.data;
		} catch {
			// Preferences are optional, fail silently
		}
	}

	// Text-based ingredient addition (legacy method)
	async function addIngredient(e: Event) {
		e.preventDefault();
		if (!newIngredient.trim()) return;
		const token = authStore.getToken();
		if (!token) return;

		adding = true;
		error = '';
		try {
			const result = await avoidedIngredients.create(token, newIngredient.trim());
			items = [...items, result.data].sort((a, b) => a.display_name.localeCompare(b.display_name));
			newIngredient = '';
		} catch {
			error = 'Failed to add ingredient (may already exist in your list)';
		} finally {
			adding = false;
		}
	}

	// Search for canonical ingredients
	async function searchIngredients() {
		if (ingredientSearch.length < 2) {
			searchResults = [];
			return;
		}
		const token = authStore.getToken();
		if (!token) return;

		searchLoading = true;
		try {
			const result = await ingredients.list(token, {
				search: ingredientSearch,
				order_by: 'popularity'
			});
			searchResults = result.data.slice(0, 10);
			showSearchResults = true;
		} catch {
			searchResults = [];
		} finally {
			searchLoading = false;
		}
	}

	// Add avoided ingredient by canonical ID
	async function addByIngredient(ingredient: CanonicalIngredient) {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		try {
			const result = await avoidedIngredients.createByIngredient(
				token,
				ingredient.id,
				ingredient.display_name
			);
			items = [...items, result.data].sort((a, b) => a.display_name.localeCompare(b.display_name));
			ingredientSearch = '';
			searchResults = [];
			showSearchResults = false;
		} catch {
			error = 'Failed to add ingredient (may already exist in your list)';
		}
	}

	// Add avoided category
	async function addCategory() {
		if (!selectedCategory) return;
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		try {
			const result = await avoidedIngredients.createByCategory(token, selectedCategory);
			items = [...items, result.data].sort((a, b) => a.display_name.localeCompare(b.display_name));
			selectedCategory = '';
		} catch {
			error = 'Failed to add category (may already exist in your list)';
		}
	}

	// Add avoided allergen group
	async function addAllergen() {
		if (!selectedAllergen) return;
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		try {
			const result = await avoidedIngredients.createByAllergen(token, selectedAllergen);
			items = [...items, result.data].sort((a, b) => a.display_name.localeCompare(b.display_name));
			selectedAllergen = '';
		} catch {
			error = 'Failed to add allergen group (may already exist in your list)';
		}
	}

	// Animal type grouping
	const landAnimals = ['beef', 'bison', 'chicken', 'duck', 'goat', 'lamb', 'pork', 'turkey'];
	const seaAnimals = [
		'anchovy',
		'clam',
		'cod',
		'crab',
		'fish',
		'halibut',
		'lobster',
		'mussel',
		'octopus',
		'salmon',
		'sardine',
		'scallop',
		'seafood',
		'shrimp',
		'snail',
		'tilapia',
		'trout',
		'tuna'
	];

	function getAvoidedAnimalTypes(): Set<string> {
		return new Set(
			items.filter((i) => i.avoidance_type === 'animal' && i.animal_type).map((i) => i.animal_type!)
		);
	}

	function isAllLandAvoided(): boolean {
		const avoided = getAvoidedAnimalTypes();
		const available = options?.animal_types ?? [];
		return landAnimals.filter((a) => available.includes(a)).every((a) => avoided.has(a));
	}

	function isAllSeaAvoided(): boolean {
		const avoided = getAvoidedAnimalTypes();
		const available = options?.animal_types ?? [];
		return seaAnimals.filter((a) => available.includes(a)).every((a) => avoided.has(a));
	}

	async function toggleAnimal(animalType: string) {
		const token = authStore.getToken();
		if (!token) return;
		error = '';

		const existing = items.find(
			(i) => i.avoidance_type === 'animal' && i.animal_type === animalType
		);

		try {
			if (existing) {
				await avoidedIngredients.delete(token, existing.id);
				items = items.filter((i) => i.id !== existing.id);
			} else {
				const result = await avoidedIngredients.createByAnimal(token, animalType);
				items = [...items, result.data].sort((a, b) =>
					a.display_name.localeCompare(b.display_name)
				);
			}
		} catch {
			error = 'Failed to update animal avoidance';
		}
	}

	async function toggleAllLand() {
		const token = authStore.getToken();
		if (!token) return;
		error = '';

		const avoided = getAvoidedAnimalTypes();
		const available = options?.animal_types ?? [];
		const allAvoided = isAllLandAvoided();

		try {
			if (allAvoided) {
				// Remove all land animals
				for (const animal of landAnimals.filter((a) => available.includes(a))) {
					const existing = items.find(
						(i) => i.avoidance_type === 'animal' && i.animal_type === animal
					);
					if (existing) {
						await avoidedIngredients.delete(token, existing.id);
						items = items.filter((i) => i.id !== existing.id);
					}
				}
			} else {
				// Add missing land animals
				for (const animal of landAnimals.filter((a) => available.includes(a))) {
					if (!avoided.has(animal)) {
						const result = await avoidedIngredients.createByAnimal(token, animal);
						items = [...items, result.data];
					}
				}
				items = items.sort((a, b) => a.display_name.localeCompare(b.display_name));
			}
		} catch {
			error = 'Failed to update animal avoidances';
		}
	}

	async function toggleAllSea() {
		const token = authStore.getToken();
		if (!token) return;
		error = '';

		const avoided = getAvoidedAnimalTypes();
		const available = options?.animal_types ?? [];
		const allAvoided = isAllSeaAvoided();

		try {
			if (allAvoided) {
				for (const animal of seaAnimals.filter((a) => available.includes(a))) {
					const existing = items.find(
						(i) => i.avoidance_type === 'animal' && i.animal_type === animal
					);
					if (existing) {
						await avoidedIngredients.delete(token, existing.id);
						items = items.filter((i) => i.id !== existing.id);
					}
				}
			} else {
				for (const animal of seaAnimals.filter((a) => available.includes(a))) {
					if (!avoided.has(animal)) {
						const result = await avoidedIngredients.createByAnimal(token, animal);
						items = [...items, result.data];
					}
				}
				items = items.sort((a, b) => a.display_name.localeCompare(b.display_name));
			}
		} catch {
			error = 'Failed to update animal avoidances';
		}
	}

	async function removeIngredient(id: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			await avoidedIngredients.delete(token, id);
			items = items.filter((i) => i.id !== id);
			if (expandedAvoidanceId === id) {
				expandedAvoidanceId = null;
				expandedIngredients = null;
			}
		} catch {
			error = 'Failed to remove item';
		}
	}

	async function toggleHideAvoided() {
		if (!preferences) return;
		const token = authStore.getToken();
		if (!token) return;

		savingPreferences = true;
		try {
			const result = await settings.updatePreferences(token, {
				hide_avoided_ingredients: !preferences.hide_avoided_ingredients
			});
			preferences = result.data;
		} catch {
			error = 'Failed to update preference';
		} finally {
			savingPreferences = false;
		}
	}

	// Expand/collapse category or allergen to show ingredients
	async function toggleExpand(item: AvoidedIngredient) {
		if (item.avoidance_type === 'ingredient') return;

		if (expandedAvoidanceId === item.id) {
			expandedAvoidanceId = null;
			expandedIngredients = null;
			return;
		}

		const token = authStore.getToken();
		if (!token) return;

		expandedAvoidanceId = item.id;
		expandedLoading = true;
		expandedIngredients = null;

		try {
			const result = await avoidedIngredients.getIngredients(token, item.id);
			expandedIngredients = result.data;
		} catch {
			error = 'Failed to load ingredients';
			expandedAvoidanceId = null;
		} finally {
			expandedLoading = false;
		}
	}

	// Toggle an exception for an ingredient in a category/allergen
	async function toggleException(ingredientId: string, isCurrentlyException: boolean) {
		if (!expandedAvoidanceId || !expandedIngredients) return;
		const token = authStore.getToken();
		if (!token) return;

		try {
			let result;
			if (isCurrentlyException) {
				// Remove exception (avoid this ingredient again)
				result = await avoidedIngredients.removeException(token, expandedAvoidanceId, ingredientId);
			} else {
				// Add exception (allow this ingredient)
				result = await avoidedIngredients.addException(token, expandedAvoidanceId, ingredientId);
			}

			// Update the item in the list
			items = items.map((item) => (item.id === expandedAvoidanceId ? result.data : item));

			// Update the expanded ingredients view
			if (expandedIngredients) {
				expandedIngredients = {
					...expandedIngredients,
					exception_count: isCurrentlyException
						? expandedIngredients.exception_count - 1
						: expandedIngredients.exception_count + 1,
					ingredients: expandedIngredients.ingredients.map((ing) =>
						ing.id === ingredientId ? { ...ing, is_exception: !isCurrentlyException } : ing
					)
				};
			}
		} catch {
			error = 'Failed to update exception';
		}
	}

	function formatLabel(value: string): string {
		return value
			.split('_')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}

	function getTypeLabel(item: AvoidedIngredient): string {
		switch (item.avoidance_type) {
			case 'category':
				return 'Category';
			case 'allergen':
				return 'Allergen';
			case 'animal':
				return 'Animal';
			default:
				return 'Ingredient';
		}
	}

	function getTypeClass(item: AvoidedIngredient): string {
		return `type-${item.avoidance_type}`;
	}

	function isExpandable(item: AvoidedIngredient): boolean {
		return item.avoidance_type === 'category' || item.avoidance_type === 'allergen' || item.avoidance_type === 'animal';
	}

	// Close search results when clicking outside
	function handleClickOutside(event: MouseEvent) {
		const target = event.target as HTMLElement;
		if (!target.closest('.ingredient-search')) {
			showSearchResults = false;
		}
	}
</script>

<svelte:document onclick={handleClickOutside} />

<div class="settings-page">
	<h1>Settings</h1>

	<section class="settings-section">
		<h2>Security</h2>
		<a href="/settings/passkeys" class="settings-link">
			<span class="link-title">Passkeys</span>
			<span class="link-description">Manage passkeys for quick, secure sign-in</span>
		</a>
	</section>

	<section class="avoided-section">
		<h2>Dietary Preferences</h2>

		{#if preferences}
			<div class="preference-toggle">
				<label class="toggle-label">
					<input
						type="checkbox"
						checked={preferences.hide_avoided_ingredients}
						onchange={toggleHideAvoided}
						disabled={savingPreferences}
					/>
					<span class="toggle-text">Hide recipes that conflict with my dietary preferences</span>
				</label>
			</div>
		{/if}

		{#if error}
			<p class="error">{error}</p>
		{/if}

		<div class="add-methods">
			<!-- Ingredient Search -->
			<div class="add-method ingredient-search">
				<h3>Search Ingredients</h3>
				<div class="search-wrapper">
					<input
						type="text"
						bind:value={ingredientSearch}
						oninput={searchIngredients}
						onfocus={() => ingredientSearch.length >= 2 && (showSearchResults = true)}
						placeholder="Search for an ingredient..."
					/>
					{#if searchLoading}
						<span class="search-spinner">...</span>
					{/if}
					{#if showSearchResults && searchResults.length > 0}
						<ul class="search-results">
							{#each searchResults as ingredient}
								<li>
									<button onclick={() => addByIngredient(ingredient)}>
										<span class="result-name">{ingredient.display_name}</span>
										{#if ingredient.category}
											<span class="result-category">{formatLabel(ingredient.category)}</span>
										{/if}
									</button>
								</li>
							{/each}
						</ul>
					{/if}
				</div>
			</div>

			<!-- Category Selection -->
			{#if options?.categories}
				<div class="add-method">
					<h3>Exclude Entire Category</h3>
					<div class="select-wrapper">
						<select bind:value={selectedCategory}>
							<option value="">Select a category...</option>
							{#each options.categories as category}
								<option value={category}>{formatLabel(category)}</option>
							{/each}
						</select>
						<button onclick={addCategory} disabled={!selectedCategory}>Add Category</button>
					</div>
				</div>
			{/if}

			<!-- Allergen Selection -->
			{#if options?.allergen_groups}
				<div class="add-method">
					<h3>Exclude Allergen Group</h3>
					<div class="select-wrapper">
						<select bind:value={selectedAllergen}>
							<option value="">Select an allergen...</option>
							{#each options.allergen_groups as allergen}
								<option value={allergen}>{formatLabel(allergen)}</option>
							{/each}
						</select>
						<button onclick={addAllergen} disabled={!selectedAllergen}>Add Allergen</button>
					</div>
				</div>
			{/if}

			<!-- Animal Type Selection -->
			{#if options?.animal_types}
				<div class="add-method">
					<h3>Exclude Animal Types</h3>

					<!-- Land Animals -->
					<div class="animal-group">
						<label class="group-toggle">
							<input
								type="checkbox"
								checked={isAllLandAvoided()}
								onchange={toggleAllLand}
							/>
							<strong>All Land Meat</strong>
						</label>
						<div class="animal-checkboxes">
							{#each landAnimals.filter((a) => options?.animal_types.includes(a)) as animal}
								<label class="animal-toggle">
									<input
										type="checkbox"
										checked={getAvoidedAnimalTypes().has(animal)}
										onchange={() => toggleAnimal(animal)}
									/>
									{formatLabel(animal)}
								</label>
							{/each}
						</div>
					</div>

					<!-- Seafood -->
					<div class="animal-group">
						<label class="group-toggle">
							<input
								type="checkbox"
								checked={isAllSeaAvoided()}
								onchange={toggleAllSea}
							/>
							<strong>All Seafood</strong>
						</label>
						<div class="animal-checkboxes">
							{#each seaAnimals.filter((a) => options?.animal_types.includes(a)) as animal}
								<label class="animal-toggle">
									<input
										type="checkbox"
										checked={getAvoidedAnimalTypes().has(animal)}
										onchange={() => toggleAnimal(animal)}
									/>
									{formatLabel(animal)}
								</label>
							{/each}
						</div>
					</div>
				</div>
			{/if}

			<!-- Text-based input (fallback) -->
			<div class="add-method">
				<h3>Add by Name</h3>
				<form onsubmit={addIngredient} class="add-form">
					<input
						type="text"
						bind:value={newIngredient}
						placeholder="e.g., chicken, beef, peanuts"
						disabled={adding}
					/>
					<button type="submit" disabled={adding || !newIngredient.trim()}>
						{adding ? 'Adding...' : 'Add'}
					</button>
				</form>
			</div>
		</div>

		{#if loading}
			<p class="loading">Loading...</p>
		{:else if items.length === 0}
			<p class="empty">No dietary preferences set. Add items above to get started.</p>
		{:else}
			{@const nonAnimalItems = items.filter((i) => i.avoidance_type !== 'animal')}
			{#if nonAnimalItems.length > 0}
			<h3 class="list-title">Your Exclusions ({nonAnimalItems.length})</h3>
			<ul class="ingredient-list">
				{#each nonAnimalItems as item}
					<li class={getTypeClass(item)}>
						<div class="item-row">
							<span class="type-badge">{getTypeLabel(item)}</span>
							<span class="name">{item.display_name}</span>
							{#if item.avoidance_type === 'ingredient' && item.canonical_name && item.canonical_name !== item.display_name.toLowerCase()}
								<span class="canonical">(matches: {item.canonical_name})</span>
							{/if}
							{#if item.category}
								<span class="detail">All {formatLabel(item.category)} products</span>
							{/if}
							{#if item.allergen_group}
								<span class="detail">All {formatLabel(item.allergen_group)} allergens</span>
							{/if}
							{#if item.animal_type}
								<span class="detail">All {formatLabel(item.animal_type)} products</span>
							{/if}
							{#if item.exception_count && item.exception_count > 0}
								<span class="exception-badge">{item.exception_count} allowed</span>
							{/if}
							<div class="item-actions">
								{#if isExpandable(item)}
									<button onclick={() => toggleExpand(item)} class="expand-btn">
										{expandedAvoidanceId === item.id ? 'Hide' : 'Edit'}
									</button>
								{/if}
								<button onclick={() => removeIngredient(item.id)} class="remove">Remove</button>
							</div>
						</div>

						{#if expandedAvoidanceId === item.id}
							<div class="expanded-content">
								{#if expandedLoading}
									<p class="expanded-loading">Loading ingredients...</p>
								{:else if expandedIngredients}
									<div class="expanded-header">
										<span class="expanded-title">
											{expandedIngredients.total_count} ingredients in this {item.avoidance_type}
										</span>
										{#if expandedIngredients.exception_count > 0}
											<span class="expanded-exceptions">
												{expandedIngredients.exception_count} allowed as exceptions
											</span>
										{/if}
									</div>
									<p class="expanded-help">
										Uncheck ingredients you're okay with eating despite excluding this {item.avoidance_type}.
									</p>
									<div class="ingredients-grid">
										{#each expandedIngredients.ingredients as ing}
											<label class="ingredient-toggle" class:is-exception={ing.is_exception}>
												<input
													type="checkbox"
													checked={!ing.is_exception}
													onchange={() => toggleException(ing.id, ing.is_exception)}
												/>
												<span class="ingredient-name">{ing.display_name}</span>
											</label>
										{/each}
									</div>
								{/if}
							</div>
						{/if}
					</li>
				{/each}
			</ul>
			{/if}
		{/if}
	</section>
</div>

<style>
	.settings-page {
		max-width: 700px;
	}

	h1 {
		margin: 0 0 var(--space-8);
		color: var(--color-marinara-800);
	}

	.settings-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
		margin-bottom: var(--space-6);
	}

	.settings-section h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
	}

	.settings-link {
		display: block;
		padding: var(--space-4);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		text-decoration: none;
		color: inherit;
		transition: all var(--transition-fast);
	}

	.settings-link:hover {
		background: var(--color-pasta-100);
	}

	.link-title {
		display: block;
		font-weight: var(--font-medium);
		color: var(--color-marinara-600);
		margin-bottom: var(--space-1);
	}

	.link-description {
		display: block;
		color: var(--text-secondary);
		font-size: var(--text-sm);
	}

	.avoided-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-6);
		box-shadow: var(--shadow-md);
	}

	h2 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-xl);
		color: var(--color-marinara-700);
	}

	.description {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-4);
	}

	.preference-toggle {
		background: var(--color-pasta-50);
		padding: var(--space-4);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-6);
	}

	.toggle-label {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		cursor: pointer;
	}

	.toggle-label input[type='checkbox'] {
		width: 18px;
		height: 18px;
		accent-color: var(--color-basil-500);
	}

	.toggle-text {
		font-size: var(--text-sm);
		color: var(--text-primary);
	}

	.add-methods {
		display: flex;
		flex-direction: column;
		gap: var(--space-4);
		margin-bottom: var(--space-6);
	}

	.add-method {
		background: var(--bg-surface);
		padding: var(--space-4);
		border-radius: var(--radius-md);
	}

	.add-method h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.animal-group {
		margin-bottom: var(--space-4);
	}

	.animal-group:last-child {
		margin-bottom: 0;
	}

	.group-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		cursor: pointer;
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--border-light);
		margin-bottom: var(--space-2);
	}

	.group-toggle input[type='checkbox'] {
		width: 18px;
		height: 18px;
		accent-color: var(--color-marinara-600);
	}

	.animal-checkboxes {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
		gap: var(--space-1) var(--space-3);
		padding-left: var(--space-2);
	}

	.animal-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		cursor: pointer;
		padding: var(--space-1) 0;
		font-size: var(--text-sm);
	}

	.animal-toggle input[type='checkbox'] {
		width: 16px;
		height: 16px;
		accent-color: var(--color-basil-500);
	}

	.search-wrapper {
		position: relative;
	}

	.search-wrapper input {
		width: 100%;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.search-wrapper input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.search-spinner {
		position: absolute;
		right: var(--space-3);
		top: 50%;
		transform: translateY(-50%);
		color: var(--text-muted);
	}

	.search-results {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		background: var(--bg-card);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		box-shadow: var(--shadow-lg);
		list-style: none;
		padding: 0;
		margin: var(--space-1) 0 0;
		z-index: 10;
		max-height: 300px;
		overflow-y: auto;
	}

	.search-results li button {
		display: flex;
		justify-content: space-between;
		align-items: center;
		width: 100%;
		padding: var(--space-3);
		border: none;
		background: none;
		cursor: pointer;
		text-align: left;
		font-size: var(--text-base);
	}

	.search-results li button:hover {
		background: var(--color-pasta-100);
	}

	.result-name {
		font-weight: var(--font-medium);
	}

	.result-category {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.select-wrapper {
		display: flex;
		gap: var(--space-2);
	}

	.select-wrapper select {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		background: var(--bg-card);
	}

	.select-wrapper select:focus {
		outline: none;
		border-color: var(--border-focus);
	}

	.select-wrapper button,
	.add-form button {
		padding: var(--space-3) var(--space-4);
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		white-space: nowrap;
	}

	.select-wrapper button:hover:not(:disabled),
	.add-form button:hover:not(:disabled) {
		background: var(--color-marinara-700);
	}

	.select-wrapper button:disabled,
	.add-form button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.add-form {
		display: flex;
		gap: var(--space-2);
	}

	.add-form input {
		flex: 1;
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
	}

	.add-form input:focus {
		outline: none;
		border-color: var(--border-focus);
		box-shadow: 0 0 0 3px rgba(27, 58, 45, 0.15);
	}

	.error {
		color: var(--color-error);
		font-size: var(--text-sm);
		margin: 0 0 var(--space-4);
		padding: var(--space-3);
		background: rgba(27, 58, 45, 0.1);
		border-radius: var(--radius-md);
	}

	.loading,
	.empty {
		color: var(--text-muted);
		font-style: italic;
		text-align: center;
		padding: var(--space-6);
	}

	.list-title {
		margin: 0 0 var(--space-3);
		font-size: var(--text-base);
		color: var(--text-secondary);
	}

	.ingredient-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.ingredient-list > li {
		background: var(--bg-surface);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.ingredient-list > li:first-child {
		border-radius: var(--radius-md) var(--radius-md) 0 0;
	}

	.ingredient-list > li:last-child {
		border-bottom: none;
		border-radius: 0 0 var(--radius-md) var(--radius-md);
	}

	.ingredient-list > li:only-child {
		border-radius: var(--radius-md);
	}

	.item-row {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-3);
		flex-wrap: wrap;
	}

	.type-badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-weight: var(--font-medium);
		text-transform: uppercase;
		letter-spacing: 0.5px;
	}

	.type-ingredient .type-badge {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.type-category .type-badge {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.type-allergen .type-badge {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.type-animal .type-badge {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
	}

	.name {
		font-weight: var(--font-medium);
	}

	.canonical,
	.detail {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	.exception-badge {
		font-size: var(--text-xs);
		padding: var(--space-1) var(--space-2);
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		border-radius: var(--radius-sm);
	}

	.item-actions {
		margin-left: auto;
		display: flex;
		gap: var(--space-2);
	}

	.expand-btn {
		background: var(--color-pasta-100);
		border: none;
		color: var(--color-pasta-700);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: var(--space-1) var(--space-3);
		border-radius: var(--radius-sm);
		font-weight: var(--font-medium);
	}

	.expand-btn:hover {
		background: var(--color-pasta-200);
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

	/* Expanded content */
	.expanded-content {
		padding: var(--space-4);
		background: var(--bg-card);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.expanded-loading {
		color: var(--text-muted);
		font-style: italic;
		margin: 0;
	}

	.expanded-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-2);
		flex-wrap: wrap;
		gap: var(--space-2);
	}

	.expanded-title {
		font-weight: var(--font-medium);
		color: var(--text-primary);
	}

	.expanded-exceptions {
		font-size: var(--text-sm);
		color: var(--color-basil-600);
	}

	.expanded-help {
		font-size: var(--text-sm);
		color: var(--text-muted);
		margin: 0 0 var(--space-4);
	}

	.ingredients-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
		gap: var(--space-2);
		max-height: 300px;
		overflow-y: auto;
		padding: var(--space-2);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.ingredient-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-2);
		border-radius: var(--radius-sm);
		cursor: pointer;
		transition: background var(--transition-fast);
	}

	.ingredient-toggle:hover {
		background: var(--color-pasta-50);
	}

	.ingredient-toggle.is-exception {
		opacity: 0.6;
	}

	.ingredient-toggle.is-exception .ingredient-name {
		text-decoration: line-through;
		color: var(--text-muted);
	}

	.ingredient-toggle input[type='checkbox'] {
		width: 16px;
		height: 16px;
		accent-color: var(--color-marinara-500);
	}

	.ingredient-name {
		font-size: var(--text-sm);
	}
</style>
