<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, ingredients as ingredientsApi, shoppingLists, type Recipe, type Ingredient, type SimilarRecipe, type ScaledIngredient, type ShoppingList, type RecipeNutrition, type IngredientDecision, type NutritionSource } from '$lib/api/client';
	let savingCopy = $state(false);
	import NutritionPanel from '$lib/components/NutritionPanel.svelte';
	import Modal from '$lib/components/Modal.svelte';
	import IngredientDiagnostics from '$lib/components/IngredientDiagnostics.svelte';
	import PrepList from '$lib/components/PrepList.svelte';
	import IngredientDecisionComponent from '$lib/components/IngredientDecision.svelte';

	let recipe = $state<Recipe | null>(null);
	let loading = $state(true);
	let error = $state('');
	let scale = $state(1);
	let similarRecipes = $state<SimilarRecipe[]>([]);
	let loadingSimilar = $state(false);
	let scalingResults = $state<Map<string, ScaledIngredient>>(new Map());
	let loadingScaling = $state(false);
	let showShoppingTips = $state(false);
	let ingredientView = $state<'unified' | 'split'>('unified');

	// Nutrition state
	let nutrition = $state<RecipeNutrition | null>(null);
	let loadingNutrition = $state(false);
	let nutritionError = $state('');
	let showNutrition = $state(true);
	let nutritionSource = $state<NutritionSource>('composite');

	// Shopping list modal state
	let showShoppingModal = $state(false);
	let availableLists = $state<ShoppingList[]>([]);
	let loadingLists = $state(false);
	let newListName = $state('');
	let addingToList = $state(false);

	// Ingredient decisions state
	let decisions = $state<Map<number, IngredientDecision>>(new Map());
	let showDecisions = $state(true);

	// Check if recipe has any ingredients with alternatives
	const hasAlternatives = $derived(
		recipe?.ingredients.some((i) => i.is_alternative && i.alternatives && i.alternatives.length > 0) ?? false
	);

	// Get ingredients that have alternatives (for the decisions section)
	const ingredientsWithAlternatives = $derived(
		recipe?.ingredients
			.map((ing, index) => ({ ingredient: ing, index }))
			.filter(({ ingredient }) => ingredient.is_alternative && ingredient.alternatives && ingredient.alternatives.length > 0) ?? []
	);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	// Reactively load recipe when the ID changes (handles client-side navigation)
	$effect(() => {
		const recipeId = $page.params.id;
		if (recipeId) {
			loadRecipe(recipeId);
		}
	});

	async function loadRecipe(recipeId: string) {
		const token = authStore.getToken();
		if (!token) return;

		// Reset state for new recipe
		loading = true;
		error = '';
		recipe = null;
		similarRecipes = [];
		scale = 1;
		scalingResults = new Map();
		showShoppingTips = false;
		nutrition = null;
		nutritionError = '';
		showNutrition = true;
		nutritionSource = 'composite';
		decisions = new Map();

		try {
			const result = await recipes.get(token, recipeId);
			recipe = result.data;
			// Load similar recipes, decisions, and nutrition in the background
			loadSimilarRecipes();
			loadDecisions(recipeId);
			loadNutrition();
		} catch {
			error = 'Recipe not found';
		} finally {
			loading = false;
		}
	}

	async function loadDecisions(recipeId: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await recipes.listDecisions(token, recipeId);
			const newDecisions = new Map<number, IngredientDecision>();
			for (const d of result.data) {
				newDecisions.set(d.ingredient_index, d);
			}
			decisions = newDecisions;
		} catch {
			// Silently fail - decisions are optional
		}
	}

	async function handleDecision(detail: { ingredientIndex: number; selectedId: string; selectedName: string }) {
		if (!recipe) return;
		const token = authStore.getToken();
		if (!token) return;

		const { ingredientIndex, selectedId, selectedName } = detail;

		// Optimistic update
		const newDecisions = new Map(decisions);
		newDecisions.set(ingredientIndex, {
			id: '',
			recipe_id: recipe.id,
			ingredient_index: ingredientIndex,
			selected_canonical_id: selectedId,
			selected_name: selectedName,
			inserted_at: new Date().toISOString(),
			updated_at: new Date().toISOString()
		});
		decisions = newDecisions;

		// Persist to backend
		try {
			const result = await recipes.saveDecision(token, recipe.id, ingredientIndex, selectedId, selectedName);
			// Update with real data from server
			newDecisions.set(ingredientIndex, result.data);
			decisions = newDecisions;

			// Refresh nutrition if it's being shown
			if (showNutrition && nutrition) {
				loadNutrition(true);
			}
		} catch {
			// Revert on error
			loadDecisions(recipe.id);
		}
	}

	async function loadSimilarRecipes() {
		const token = authStore.getToken();
		if (!token || !recipe) return;

		loadingSimilar = true;
		try {
			const result = await recipes.similar(token, recipe.id, 5);
			similarRecipes = result.data;
		} catch {
			// Silently fail - similar recipes are optional
			similarRecipes = [];
		} finally {
			loadingSimilar = false;
		}
	}

	async function loadNutrition(forceReload = false) {
		const token = authStore.getToken();
		if (!token || !recipe) return;

		// Don't reload if we already have nutrition data (unless forced)
		if (nutrition && !forceReload) return;

		loadingNutrition = true;
		nutritionError = '';
		try {
			const result = await recipes.nutrition(token, recipe.id, { source: nutritionSource });
			nutrition = result.data;
		} catch (e) {
			nutritionError = 'Could not load nutrition data';
		} finally {
			loadingNutrition = false;
		}
	}

	function handleSourceChange(event: CustomEvent<NutritionSource>) {
		nutritionSource = event.detail;
		loadNutrition(true);
	}

	function toggleNutrition() {
		showNutrition = !showNutrition;
		if (showNutrition && !nutrition && !loadingNutrition) {
			loadNutrition();
		}
	}

	async function handleDelete() {
		if (!recipe || !confirm('Are you sure you want to delete this recipe?')) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			await recipes.delete(token, recipe.id);
			goto('/recipes');
		} catch {
			alert('Failed to delete recipe');
		}
	}

	async function handleArchive() {
		if (!recipe) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await recipes.archive(token, recipe.id);
			recipe = result.data;
		} catch {
			alert('Failed to archive recipe');
		}
	}

	async function handleUnarchive() {
		if (!recipe) return;

		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await recipes.unarchive(token, recipe.id);
			recipe = result.data;
		} catch {
			alert('Failed to unarchive recipe');
		}
	}

	async function handleSaveToMyRecipes() {
		if (!recipe) return;
		const token = authStore.getToken();
		if (!token) return;

		savingCopy = true;
		try {
			const result = await recipes.copy(token, recipe.id);
			goto(`/recipes/${result.data.id}`);
		} catch {
			alert('Failed to save recipe');
		} finally {
			savingCopy = false;
		}
	}

	function formatTime(minutes: number | null): string {
		if (!minutes) return 'N/A';
		if (minutes < 60) return `${minutes} min`;
		const hours = Math.floor(minutes / 60);
		const mins = minutes % 60;
		return mins ? `${hours} hr ${mins} min` : `${hours} hr`;
	}

	function handlePrint() {
		window.print();
	}

	// Unicode fractions mapping
	const unicodeFractions: Record<string, number> = {
		'½': 0.5,
		'⅓': 0.333,
		'⅔': 0.667,
		'¼': 0.25,
		'¾': 0.75,
		'⅕': 0.2,
		'⅖': 0.4,
		'⅗': 0.6,
		'⅘': 0.8,
		'⅙': 0.167,
		'⅚': 0.833,
		'⅛': 0.125,
		'⅜': 0.375,
		'⅝': 0.625,
		'⅞': 0.875
	};

	// Scale ingredient quantities (both primary and parenthetical)
	function scaleIngredient(text: string): string {
		if (scale === 1) return text;

		let result = text;

		// First, handle ranges at the start: "7/8 cup to 1 cup" or "1-2 cups"
		// Matches: "NUMBER UNIT to NUMBER UNIT" or "NUMBER to NUMBER UNIT"
		const rangePattern = /^([\d\s\/\.½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+)\s*(cups?|tablespoons?|tbsps?|teaspoons?|tsps?|ounces?|oz|pounds?|lbs?|grams?|g|kg|ml|l)?\s*(?:to|-)\s*([\d\s\/\.½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+)\s*(cups?|tablespoons?|tbsps?|teaspoons?|tsps?|ounces?|oz|pounds?|lbs?|grams?|g|kg|ml|l)?(\s+)/i;
		const rangeMatch = result.match(rangePattern);

		if (rangeMatch) {
			const [fullMatch, qty1, unit1, qty2, unit2, trailing] = rangeMatch;
			const scaled1 = parseQuantity(qty1) * scale;
			const scaled2 = parseQuantity(qty2) * scale;
			const displayUnit1 = unit1 || '';
			const displayUnit2 = unit2 || '';
			result = result.replace(fullMatch, `${formatQuantity(scaled1)} ${displayUnit1} to ${formatQuantity(scaled2)} ${displayUnit2}${trailing}`);
		} else {
			// Handle single quantity at the start
			// Matches: "2", "1/2", "1 1/2", "2.5", "3 ⅓", etc. followed by a space
			result = result.replace(
				/^([\d\s\/\.½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+)(\s+)/,
				(match, qty, space) => {
					const scaled = parseQuantity(qty) * scale;
					return formatQuantity(scaled) + ' ';
				}
			);
		}

		// Then scale any parenthetical measurements with ranges
		// Matches: "(198g to 227g)" or "(about 4 to 5 cups)"
		result = result.replace(
			/\(\s*(about\s+|approximately\s+|roughly\s+|around\s+|~\s*)?([\d\.\/]+)\s*(g|grams?|kg|kilograms?|ml|milliliters?|l|liters?|cups?|tbsps?|tablespoons?|tsps?|teaspoons?|oz|ounces?|lbs?|pounds?|sticks?)?\s*(?:to|-)\s*([\d\.\/]+)\s*(g|grams?|kg|kilograms?|ml|milliliters?|l|liters?|cups?|tbsps?|tablespoons?|tsps?|teaspoons?|oz|ounces?|lbs?|pounds?|sticks?)\s*\)/gi,
			(match, prefix, num1, unit1, num2, unit2) => {
				const scaled1 = parseQuantity(num1) * scale;
				const scaled2 = parseQuantity(num2) * scale;
				const prefixStr = prefix || '';
				const displayUnit1 = unit1 || '';
				return `(${prefixStr}${formatQuantity(scaled1)}${displayUnit1} to ${formatQuantity(scaled2)} ${unit2})`;
			}
		);

		// Scale single parenthetical measurements
		// Matches: "(120g)", "(120 g)", "(120 grams)", "(30 ml)", "(about 4 cups)"
		result = result.replace(
			/\(\s*(about\s+|approximately\s+|roughly\s+|around\s+|~\s*)?([\d\.\/]+)\s*(g|grams?|kg|kilograms?|ml|milliliters?|l|liters?|cups?|tbsps?|tablespoons?|tsps?|teaspoons?|oz|ounces?|lbs?|pounds?|sticks?)\s*\)/gi,
			(match, prefix, num, unit) => {
				const scaled = parseQuantity(num) * scale;
				const formattedQty = formatQuantity(scaled);
				const prefixStr = prefix || '';
				return `(${prefixStr}${formattedQty} ${unit})`;
			}
		);

		return result;
	}

	function parseQuantity(str: string): number {
		str = str.trim();

		// First, replace any unicode fractions with their decimal values
		let hasUnicodeFraction = false;
		let unicodeValue = 0;
		for (const [char, val] of Object.entries(unicodeFractions)) {
			if (str.includes(char)) {
				hasUnicodeFraction = true;
				unicodeValue = val;
				str = str.replace(char, '').trim();
				break;
			}
		}

		// Handle mixed numbers with unicode fraction like "3 ⅓" -> "3" + 0.333
		if (hasUnicodeFraction) {
			const whole = parseInt(str);
			return (isNaN(whole) ? 0 : whole) + unicodeValue;
		}

		// Handle mixed numbers like "1 1/2"
		const mixedMatch = str.match(/^(\d+)\s+(\d+)\/(\d+)$/);
		if (mixedMatch) {
			const whole = parseInt(mixedMatch[1]);
			const num = parseInt(mixedMatch[2]);
			const den = parseInt(mixedMatch[3]);
			return whole + num / den;
		}

		// Handle fractions like "1/2"
		const fractionMatch = str.match(/^(\d+)\/(\d+)$/);
		if (fractionMatch) {
			return parseInt(fractionMatch[1]) / parseInt(fractionMatch[2]);
		}

		// Handle decimals and integers
		const num = parseFloat(str);
		return isNaN(num) ? 0 : num;
	}

	function formatQuantity(num: number): string {
		// Convert to nice Unicode fractions for common values
		const fractions: [number, string][] = [
			[0.125, '⅛'],
			[0.2, '⅕'],
			[0.25, '¼'],
			[0.333, '⅓'],
			[0.375, '⅜'],
			[0.4, '⅖'],
			[0.5, '½'],
			[0.6, '⅗'],
			[0.625, '⅝'],
			[0.667, '⅔'],
			[0.75, '¾'],
			[0.8, '⅘'],
			[0.833, '⅚'],
			[0.875, '⅞']
		];

		const whole = Math.floor(num);
		const frac = num - whole;

		// Check if the fractional part is close to a common fraction
		for (const [val, str] of fractions) {
			if (Math.abs(frac - val) < 0.03) {
				return whole > 0 ? `${whole}${str}` : str;
			}
		}

		// Check for very small fractional part (essentially whole number)
		if (frac < 0.03) {
			return whole.toString();
		}

		// Otherwise, round to 2 decimal places
		const rounded = Math.round(num * 100) / 100;
		return rounded % 1 === 0 ? rounded.toString() : rounded.toFixed(2).replace(/\.?0+$/, '');
	}

	function setScale(newScale: number) {
		scale = Math.max(0.25, Math.min(4, newScale));
		// Fetch scaling suggestions when scale changes (debounced)
		if (scale !== 1) {
			fetchScalingSuggestions();
		} else {
			scalingResults = new Map();
		}
	}

	async function fetchScalingSuggestions() {
		const token = authStore.getToken();
		if (!token || !recipe) return;

		loadingScaling = true;
		try {
			// Parse ingredients to extract name, quantity, unit
			const parsedIngredients = recipe.ingredients.map(ing => parseIngredientForScaling(ing.text));

			const result = await ingredientsApi.scaleBulk(token, scale, parsedIngredients);

			// Build map of original name -> scaling result
			const newResults = new Map<string, ScaledIngredient>();
			result.data.ingredients.forEach((scaled, index) => {
				const originalText = recipe!.ingredients[index].text;
				newResults.set(originalText, scaled);
			});
			scalingResults = newResults;
		} catch {
			// Silently fail - scaling suggestions are optional
			scalingResults = new Map();
		} finally {
			loadingScaling = false;
		}
	}

	function parseIngredientForScaling(text: string): { name: string; quantity: number; unit: string } {
		// Extract quantity from start of text
		const qtyMatch = text.match(/^([\d\s\/\.]+)\s*/);
		const quantity = qtyMatch ? parseQuantity(qtyMatch[1]) : 1;

		// Extract unit (common cooking units)
		const unitPattern = /^[\d\s\/\.]*\s*(cups?|tablespoons?|tbsps?|teaspoons?|tsps?|ounces?|oz|pounds?|lbs?|grams?|g|kilograms?|kg|milliliters?|ml|liters?|l|cans?|bottles?|packages?|pkgs?|pieces?|pcs?|slices?|cloves?|sticks?|heads?|bunches?|sprigs?|pinch(?:es)?|dash(?:es)?)\s+/i;
		const unitMatch = text.match(unitPattern);
		const unit = unitMatch ? unitMatch[1].toLowerCase() : '';

		// Get ingredient name (everything after quantity and unit)
		let name = text;
		if (qtyMatch) {
			name = name.substring(qtyMatch[0].length);
		}
		if (unitMatch) {
			name = name.substring(unitMatch[1].length).trim();
		}

		// Remove preparation words and clean up
		name = name
			.replace(/,.*$/, '') // Remove everything after comma
			.replace(/\s*\(.*?\)\s*/g, '') // Remove parenthetical content
			.replace(/\b(diced|chopped|minced|sliced|crushed|fresh|dried|frozen|canned|melted|softened|room temperature|cold|hot|warm)\b/gi, '')
			.trim();

		return { name, quantity, unit };
	}

	function getPackageSuggestion(ingredientText: string): string | null {
		const scaled = scalingResults.get(ingredientText);
		return scaled?.package_suggestion || null;
	}

	function getShoppingTips(): Array<{ ingredient: string; suggestion: string; brand?: string }> {
		const tips: Array<{ ingredient: string; suggestion: string; brand?: string }> = [];

		scalingResults.forEach((scaled, ingredientText) => {
			if (scaled.package_suggestion) {
				tips.push({
					ingredient: scaled.original_name || ingredientText,
					suggestion: scaled.package_suggestion,
					brand: scaled.package_size
				});
			}
		});

		return tips;
	}

	async function openShoppingModal() {
		showShoppingModal = true;
		loadingLists = true;

		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await shoppingLists.list(token);
			availableLists = result.data;
		} catch {
			availableLists = [];
		} finally {
			loadingLists = false;
		}
	}

	function closeShoppingModal() {
		showShoppingModal = false;
		newListName = '';
	}

	async function addToList(listId: string) {
		if (!recipe) return;
		const token = authStore.getToken();
		if (!token) return;

		addingToList = true;
		try {
			await shoppingLists.addRecipe(token, listId, recipe.id, scale);
			closeShoppingModal();
			alert('Ingredients added to shopping list!');
		} catch {
			alert('Failed to add to shopping list');
		} finally {
			addingToList = false;
		}
	}

	async function createAndAddToList() {
		if (!recipe || !newListName.trim()) return;
		const token = authStore.getToken();
		if (!token) return;

		addingToList = true;
		try {
			const result = await shoppingLists.create(token, { name: newListName.trim() });
			await shoppingLists.addRecipe(token, result.data.id, recipe.id, scale);
			closeShoppingModal();
			alert('Created shopping list and added ingredients!');
		} catch {
			alert('Failed to create list and add ingredients');
		} finally {
			addingToList = false;
		}
	}
</script>

{#if loading}
	<div class="loading">Loading recipe...</div>
{:else if error}
	<div class="error">
		<p>{error}</p>
		<a href="/recipes">Back to recipes</a>
	</div>
{:else if recipe}
	<article class="recipe-detail">
		{#if recipe.archived_at}
			<div class="archived-banner">
				This recipe is archived.
				<button onclick={handleUnarchive} class="unarchive-link">Restore it</button>
			</div>
		{/if}

		<!-- Hero image with overlay -->
		<div class="recipe-hero" class:no-image={!recipe.image_url}>
			{#if recipe.image_url}
				<img src={recipe.image_url} alt={recipe.title} class="recipe-hero-img" />
			{/if}
			<div class="recipe-hero-overlay" class:static-overlay={!recipe.image_url}>
				{#if recipe.tags.length > 0}
					<div class="hero-tags no-print">
						{#each recipe.tags as tag}
							<span class="hero-tag">{tag.name}</span>
						{/each}
					</div>
				{/if}
				<h1>{recipe.title}</h1>
				{#if recipe.source_url}
					<a href={recipe.source_url} target="_blank" rel="noopener noreferrer" class="hero-source">
						{recipe.source_domain}
					</a>
				{/if}
			</div>
		</div>

		<div class="recipe-content">
			<!-- Meta bar -->
			<div class="meta-bar">
				{#if recipe.prep_time_minutes}
					<div class="meta-item">
						<span class="meta-label">Prep</span>
						<span class="meta-value">{formatTime(recipe.prep_time_minutes)}</span>
					</div>
				{/if}
				{#if recipe.cook_time_minutes}
					<div class="meta-item">
						<span class="meta-label">Cook</span>
						<span class="meta-value">{formatTime(recipe.cook_time_minutes)}</span>
					</div>
				{/if}
				{#if recipe.total_time_minutes}
					<div class="meta-item">
						<span class="meta-label">Total</span>
						<span class="meta-value">{formatTime(recipe.total_time_minutes)}</span>
					</div>
				{/if}
				{#if recipe.servings}
					<div class="meta-item">
						<span class="meta-label">Serves</span>
						<span class="meta-value">{recipe.servings}</span>
					</div>
				{/if}
			</div>

			{#if recipe.description}
				<p class="description">{recipe.description}</p>
			{/if}

			<!-- Action bar -->
			<div class="action-bar no-print">
				{#if recipe.is_owned === false}
					<button onclick={handleSaveToMyRecipes} class="btn btn-primary" disabled={savingCopy}>
						{savingCopy ? 'Saving...' : 'Save to My Recipes'}
					</button>
					<button onclick={handlePrint} class="btn btn-outline">Print</button>
				{:else}
					<button onclick={openShoppingModal} class="btn btn-primary">Add to List</button>
					<button onclick={handlePrint} class="btn btn-outline">Print</button>
					<a href="/recipes/{recipe.id}/edit" class="btn btn-outline">Edit</a>
					{#if recipe.archived_at}
						<button onclick={handleUnarchive} class="btn btn-outline">Unarchive</button>
					{:else}
						<button onclick={handleArchive} class="btn btn-outline">Archive</button>
					{/if}
					<button onclick={handleDelete} class="btn btn-danger">Delete</button>
				{/if}
				<div class="scale-controls">
					<button onclick={() => setScale(scale - 0.25)} class="scale-btn" disabled={scale <= 0.25}>-</button>
					<span class="scale-value">{scale}x</span>
					<button onclick={() => setScale(scale + 0.25)} class="scale-btn" disabled={scale >= 4}>+</button>
				</div>
			</div>

			<!-- Ingredients & Instructions two-column layout -->
			<div class="recipe-body">
				<aside class="ingredients">
					<div class="section-header">
						<h2>Ingredients</h2>
						<div class="view-toggle no-print">
							<button
								class="view-btn"
								class:active={ingredientView === 'unified'}
								onclick={() => ingredientView = 'unified'}
							>
								Unified
							</button>
							<button
								class="view-btn"
								class:active={ingredientView === 'split'}
								onclick={() => ingredientView = 'split'}
							>
								Split
							</button>
						</div>
					</div>

					{#if ingredientView === 'unified'}
						<ul class="ingredient-list">
							{#each recipe.ingredients as ingredient, i}
								<li>
									<div class="ingredient-line">
										<span class="ingredient-text">{scaleIngredient(ingredient.text)}</span>
										{#if scale !== 1 && getPackageSuggestion(ingredient.text)}
											<span class="package-hint" title={getPackageSuggestion(ingredient.text)}>
												<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
											</span>
										{/if}
									</div>
								</li>
							{/each}
						</ul>

						{#if scale !== 1 && getShoppingTips().length > 0}
							<div class="shopping-tips no-print">
								<button class="tips-toggle" onclick={() => showShoppingTips = !showShoppingTips}>
									<span class="tips-icon">🛒</span>
									<span>Shopping Tips ({getShoppingTips().length})</span>
									<span class="toggle-arrow">{showShoppingTips ? '▲' : '▼'}</span>
								</button>
								{#if showShoppingTips}
									<ul class="tips-list">
										{#each getShoppingTips() as tip}
											<li>
												<strong>{tip.ingredient}</strong>: {tip.suggestion}
												{#if tip.brand}
													<span class="brand-info">({tip.brand})</span>
												{/if}
											</li>
										{/each}
									</ul>
								{/if}
							</div>
						{/if}

						<PrepList ingredients={recipe.ingredients} />
					{:else}
						<div class="split-view">
							<div class="parsed-ingredients">
								<h3>Shopping List</h3>
								<table class="ingredient-table">
									<thead>
										<tr>
											<th>Amount</th>
											<th>Ingredient</th>
										</tr>
									</thead>
									<tbody>
										{#each recipe.ingredients as ingredient, i}
											{@const qtyObj = ingredient.quantity}
											{@const rawQty = typeof qtyObj === 'object' && qtyObj !== null ? qtyObj.value : qtyObj}
											{@const qty = rawQty ? (rawQty * scale) : null}
											{@const unit = typeof qtyObj === 'object' && qtyObj !== null ? qtyObj.unit : ingredient.unit}
											{@const displayName = ingredient.canonical_name || ingredient.text.replace(/^[\d\s\/\.\-½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+\s*(cup|cups|tbsp|tsp|tablespoon|tablespoons|teaspoon|teaspoons|oz|ounce|ounces|lb|lbs|pound|pounds|g|gram|grams|kg|ml|l|liter|liters|clove|cloves|head|heads|bunch|bunches|sprig|sprigs|can|cans|package|packages|stick|sticks|slice|slices|piece|pieces)s?\s*/i, '').trim()}
											<tr>
												<td class="amount-cell">
													{#if qty}
														<span class="quantity">{formatQuantity(qty)}</span>
														{#if unit}
															<span class="unit">{unit}</span>
														{/if}
													{:else}
														<span class="quantity-na">—</span>
													{/if}
												</td>
												<td class="ingredient-cell">
													<span class="ingredient-name">{displayName}</span>
													{#if ingredient.canonical_name && ingredient.canonical_name !== displayName}
														<span class="canonical-hint">({ingredient.canonical_name})</span>
													{/if}
												</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>

							<div class="prep-section">
								<h3>Prep Steps</h3>
								<PrepList ingredients={recipe.ingredients} expanded={true} />
							</div>
						</div>
					{/if}
				</aside>

				<div class="instructions">
					<h2>Instructions</h2>
					<ol class="step-list">
						{#each recipe.instructions as instruction, i}
							<li>
								<span class="step-circle">{i + 1}</span>
								<p>{instruction.text}</p>
							</li>
						{/each}
					</ol>
				</div>
			</div>

			{#if recipe.notes}
				<section class="notes">
					<h2>Notes</h2>
					<p>{recipe.notes}</p>
				</section>
			{/if}

			<section class="nutrition-section no-print">
				<button class="nutrition-toggle" onclick={toggleNutrition}>
					<span class="toggle-icon">{showNutrition ? '▼' : '▶'}</span>
					<h2>Nutrition Information</h2>
				</button>
				{#if showNutrition}
					<div class="nutrition-content">
						<NutritionPanel
							nutrition={nutrition}
							loading={loadingNutrition}
							error={nutritionError}
							selectedSource={nutritionSource}
							on:sourceChange={handleSourceChange}
						/>
					</div>
				{/if}
			</section>

			{#if hasAlternatives}
				<section class="decisions-section no-print">
					<button class="section-toggle" onclick={() => showDecisions = !showDecisions}>
						<span class="toggle-icon">{showDecisions ? '▼' : '▶'}</span>
						<h2>Ingredient Choices ({ingredientsWithAlternatives.length})</h2>
					</button>
					{#if showDecisions}
						<div class="decisions-content">
							<p class="decisions-hint">Some ingredients have multiple possible matches. Choose the correct one for accurate nutrition calculations.</p>
							{#each ingredientsWithAlternatives as { ingredient, index }}
								<div class="decision-item">
									<div class="decision-ingredient-text">{ingredient.text}</div>
									<IngredientDecisionComponent
										{ingredient}
										{index}
										currentDecision={decisions.get(index)}
										ondecide={handleDecision}
									/>
								</div>
							{/each}
						</div>
					{/if}
				</section>
			{/if}

			{#if recipe.ingredients.some(i => i._diagnostics)}
				<section class="diagnostics-section no-print">
					<IngredientDiagnostics ingredients={recipe.ingredients} />
				</section>
			{/if}

			<section class="similar-recipes no-print">
				<h2>Similar Recipes</h2>
				{#if loadingSimilar}
					<p class="loading-similar">Finding similar recipes...</p>
				{:else if similarRecipes.length === 0}
					<p class="no-similar">No similar recipes found.</p>
				{:else}
					<div class="similar-grid">
						{#each similarRecipes as similar}
							<div class="similar-card">
								<a href="/recipes/{similar.recipe.id}" class="similar-card-link">
									{#if similar.recipe.image_url}
										<img src={similar.recipe.image_url} alt={similar.recipe.title} class="similar-image" />
									{:else}
										<div class="similar-image placeholder">No image</div>
									{/if}
									<div class="similar-content">
										<h3>{similar.recipe.title}</h3>
										<div class="similarity-score">
											<span class="score">{Math.round(similar.score * 100)}% similar</span>
										</div>
										{#if similar.shared_ingredients.length > 0}
											<div class="shared-ingredients">
												<span class="shared-label">Shared:</span>
												{similar.shared_ingredients.slice(0, 3).join(', ')}
												{#if similar.shared_ingredients.length > 3}
													<span class="more">+{similar.shared_ingredients.length - 3} more</span>
												{/if}
											</div>
										{/if}
									</div>
								</a>
								<a href="/recipes/compare?id1={recipe.id}&id2={similar.recipe.id}" class="compare-link">
									Compare side by side
								</a>
							</div>
						{/each}
					</div>
				{/if}
			</section>
		</div>
	</article>

	<Modal bind:open={showShoppingModal} title="Add to Shopping List" onclose={closeShoppingModal}>
		{#if scale !== 1}
			<p class="scale-note">Adding ingredients at {scale}x scale</p>
		{/if}

		{#if loadingLists}
			<p>Loading lists...</p>
		{:else if availableLists.length > 0}
			<div class="list-options">
				{#each availableLists as list}
					<button
						class="list-option"
						onclick={() => addToList(list.id)}
						disabled={addingToList}
					>
						{list.name}
					</button>
				{/each}
			</div>
		{/if}

		<div class="create-new">
			<p class="create-label">Or create a new list:</p>
			<form onsubmit={(e) => { e.preventDefault(); createAndAddToList(); }}>
				<input
					type="text"
					bind:value={newListName}
					placeholder="New list name..."
					disabled={addingToList}
				/>
				<button type="submit" disabled={addingToList || !newListName.trim()}>
					{addingToList ? 'Adding...' : 'Create & Add'}
				</button>
			</form>
		</div>
	</Modal>
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

	.recipe-detail {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-lg);
	}

	.archived-banner {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		padding: var(--space-3) var(--space-4);
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.unarchive-link {
		background: none;
		border: none;
		color: var(--color-pasta-800);
		text-decoration: underline;
		cursor: pointer;
		font-size: inherit;
		padding: 0;
	}

	.unarchive-link:hover {
		color: var(--color-pasta-900);
	}

	/* Hero image with overlay */
	.recipe-hero {
		position: relative;
		min-height: 300px;
		max-height: 60vh;
		overflow: hidden;
	}

	.recipe-hero.no-image {
		min-height: auto;
		max-height: none;
		background: var(--color-marinara-800);
	}

	.recipe-hero-img {
		width: 100%;
		height: 100%;
		min-height: 300px;
		max-height: 60vh;
		object-fit: cover;
		display: block;
	}

	.recipe-hero-overlay {
		position: absolute;
		bottom: 0;
		left: 0;
		right: 0;
		padding: var(--space-12) var(--space-8) var(--space-8);
		background: linear-gradient(transparent, rgba(0, 0, 0, 0.7));
		color: white;
	}

	.recipe-hero-overlay.static-overlay {
		position: relative;
		background: var(--color-marinara-800);
		padding: var(--space-10) var(--space-8);
	}

	.hero-tags {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
		margin-bottom: var(--space-3);
	}

	.hero-tag {
		padding: var(--space-1) var(--space-3);
		background: rgba(255, 255, 255, 0.2);
		backdrop-filter: blur(4px);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		text-transform: uppercase;
		letter-spacing: 0.08em;
		font-weight: var(--font-medium);
	}

	h1 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-4xl);
		font-family: var(--font-serif);
		color: white;
		line-height: var(--leading-tight);
	}

	.hero-source {
		font-size: var(--text-sm);
		color: rgba(255, 255, 255, 0.7);
		text-decoration: none;
	}

	.hero-source:hover {
		color: white;
		text-decoration: underline;
	}

	/* Recipe content area */
	.recipe-content {
		max-width: 960px;
		margin: 0 auto;
		padding: var(--space-8);
	}

	/* Meta bar */
	.meta-bar {
		display: flex;
		gap: var(--space-8);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		margin-bottom: var(--space-6);
	}

	.meta-item {
		text-align: center;
	}

	.meta-label {
		display: block;
		font-size: var(--text-xs);
		text-transform: uppercase;
		letter-spacing: 0.12em;
		color: var(--color-marinara-500);
		margin-bottom: var(--space-1);
	}

	.meta-value {
		font-size: var(--text-lg);
		color: var(--text-primary);
		font-weight: var(--font-medium);
	}

	.description {
		font-size: var(--text-lg);
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
		margin: 0 0 var(--space-6);
	}

	/* Action bar */
	.action-bar {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		margin-bottom: var(--space-8);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		flex-wrap: wrap;
	}

	.btn {
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		text-decoration: none;
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		transition: all var(--transition-fast);
		white-space: nowrap;
	}

	.btn-primary {
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
	}

	.btn-primary:hover:not(:disabled) {
		background: var(--color-marinara-700);
	}

	.btn-primary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.btn-outline {
		background: none;
		color: var(--text-secondary);
		border: var(--border-width-thin) solid var(--border-default);
	}

	.btn-outline:hover {
		border-color: var(--color-marinara-600);
		color: var(--color-marinara-700);
	}

	.btn-danger {
		background: none;
		color: #c53030;
		border: var(--border-width-thin) solid #c53030;
	}

	.btn-danger:hover {
		background: #c53030;
		color: var(--color-white);
	}

	.scale-controls {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.scale-btn {
		width: 28px;
		height: 28px;
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-size: var(--text-base);
		line-height: 1;
		transition: all var(--transition-fast);
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.scale-btn:hover:not(:disabled) {
		background: var(--bg-surface);
		border-color: var(--color-marinara-500);
	}

	.scale-btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.scale-value {
		min-width: 40px;
		text-align: center;
		font-weight: var(--font-medium);
		font-size: var(--text-sm);
	}

	/* Two-column body layout */
	.recipe-body {
		display: grid;
		grid-template-columns: 300px 1fr;
		gap: var(--space-8);
		margin-bottom: var(--space-6);
	}

	/* Section header */
	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-4);
	}

	.section-header h2 {
		margin: 0;
		padding-bottom: 0;
		border-bottom: none;
	}

	h2 {
		font-family: var(--font-serif);
		font-size: var(--text-xl);
		margin: 0 0 var(--space-4);
		color: var(--color-marinara-700);
	}

	.view-toggle {
		display: flex;
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: 2px;
		border: var(--border-width-thin) solid var(--border-default);
	}

	.view-btn {
		padding: var(--space-1) var(--space-3);
		border: none;
		background: transparent;
		border-radius: var(--radius-sm);
		cursor: pointer;
		font-size: var(--text-sm);
		color: var(--text-secondary);
		transition: all var(--transition-fast);
	}

	.view-btn:hover {
		color: var(--text-primary);
	}

	.view-btn.active {
		background: var(--bg-card);
		color: var(--text-primary);
		font-weight: var(--font-medium);
		box-shadow: var(--shadow-sm);
	}

	/* Ingredient list */
	.ingredient-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.ingredient-list li {
		padding: var(--space-2) 0;
		border-bottom: var(--border-width-thin) solid var(--border-subtle);
		line-height: var(--leading-relaxed);
	}

	.ingredient-list li:last-child {
		border-bottom: none;
	}

	.ingredient-line {
		display: flex;
		align-items: flex-start;
		gap: var(--space-2);
	}

	.ingredient-text {
		flex: 1;
	}

	.package-hint {
		color: var(--color-marinara-500);
		cursor: help;
		flex-shrink: 0;
		display: inline-flex;
		align-items: center;
	}

	.package-hint:hover {
		color: var(--color-marinara-600);
	}

	/* Shopping tips */
	.shopping-tips {
		margin-top: var(--space-6);
		border: var(--border-width-thin) solid var(--color-basil-200);
		border-radius: var(--radius-lg);
		background: var(--color-basil-50);
	}

	.tips-toggle {
		width: 100%;
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-3) var(--space-4);
		background: none;
		border: none;
		cursor: pointer;
		font-size: var(--text-sm);
		color: var(--color-basil-600);
		font-weight: var(--font-medium);
	}

	.tips-toggle:hover {
		background: var(--color-basil-100);
	}

	.tips-icon {
		font-size: var(--text-lg);
	}

	.toggle-arrow {
		margin-left: auto;
		font-size: var(--text-xs);
	}

	.tips-list {
		list-style: none;
		padding: 0 var(--space-4) var(--space-4);
		margin: 0;
	}

	.tips-list li {
		padding: var(--space-2) 0;
		border-top: var(--border-width-thin) solid var(--color-basil-200);
		font-size: var(--text-sm);
		display: block;
	}

	.tips-list li:first-child {
		border-top: none;
	}

	.tips-list strong {
		color: var(--color-marinara-800);
	}

	.brand-info {
		color: var(--text-muted);
		font-size: var(--text-sm);
	}

	/* Split view styles */
	.split-view {
		display: flex;
		flex-direction: column;
		gap: var(--space-6);
	}

	.split-view h3 {
		font-size: var(--text-lg);
		margin: 0 0 var(--space-3);
		color: var(--text-primary);
	}

	.ingredient-table {
		width: 100%;
		border-collapse: collapse;
	}

	.ingredient-table th {
		text-align: left;
		padding: var(--space-2) var(--space-3);
		border-bottom: var(--border-width-default) solid var(--border-default);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
		font-size: var(--text-sm);
	}

	.ingredient-table td {
		padding: var(--space-2) var(--space-3);
		border-bottom: var(--border-width-thin) solid var(--border-subtle);
		vertical-align: top;
	}

	.ingredient-table tr:last-child td {
		border-bottom: none;
	}

	.amount-cell {
		white-space: nowrap;
		width: 100px;
	}

	.quantity {
		font-weight: var(--font-medium);
	}

	.unit {
		color: var(--text-secondary);
		margin-left: var(--space-1);
	}

	.quantity-na {
		color: var(--text-tertiary);
	}

	.ingredient-cell {
		display: flex;
		flex-direction: column;
		align-items: flex-start;
		gap: var(--space-1);
	}

	.ingredient-name {
		font-weight: var(--font-medium);
	}

	.canonical-hint {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.prep-section {
		background: var(--bg-surface);
		padding: var(--space-4);
		border-radius: var(--radius-md);
	}

	/* Instructions with step circles */
	.instructions h2 {
		margin-bottom: var(--space-6);
	}

	.step-list {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.step-list li {
		display: flex;
		gap: var(--space-4);
		margin-bottom: var(--space-6);
		align-items: flex-start;
	}

	.step-circle {
		flex-shrink: 0;
		width: 32px;
		height: 32px;
		border-radius: 50%;
		border: var(--border-width-thin) solid var(--border-default);
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: var(--text-sm);
		color: var(--color-marinara-500);
		font-weight: var(--font-medium);
		margin-top: 2px;
	}

	.step-list p {
		margin: 0;
		line-height: var(--leading-relaxed);
		color: var(--text-secondary);
	}

	/* Notes */
	.notes {
		background: var(--color-pasta-100);
		padding: var(--space-4);
		border-radius: var(--radius-lg);
		border-left: var(--border-width-thick) solid var(--color-pasta-500);
		margin-bottom: var(--space-6);
	}

	.notes p {
		margin: 0;
		line-height: var(--leading-relaxed);
	}

	/* Similar recipes section */
	.similar-recipes {
		margin-top: var(--space-8);
		padding-top: var(--space-6);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.loading-similar,
	.no-similar {
		color: var(--text-muted);
		font-style: italic;
	}

	.similar-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
		gap: var(--space-4);
	}

	.similar-card {
		display: flex;
		flex-direction: column;
		background: var(--bg-surface);
		border-radius: var(--radius-lg);
		overflow: hidden;
		transition: all var(--transition-normal);
	}

	.similar-card:hover {
		transform: translateY(-2px);
		box-shadow: var(--shadow-lg);
	}

	.similar-card-link {
		display: block;
		text-decoration: none;
		color: inherit;
	}

	.similar-image {
		width: 100%;
		height: 120px;
		object-fit: cover;
	}

	.similar-image.placeholder {
		background: var(--color-gray-200);
		display: flex;
		align-items: center;
		justify-content: center;
		color: var(--text-muted);
		font-size: var(--text-sm);
		min-height: 120px;
	}

	.similar-content {
		padding: var(--space-3);
	}

	.similar-content h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-base);
		line-height: var(--leading-snug);
	}

	.similarity-score {
		margin-bottom: var(--space-2);
	}

	.score {
		display: inline-block;
		background: var(--color-marinara-600);
		color: var(--color-white);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-full);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.shared-ingredients {
		font-size: var(--text-xs);
		color: var(--text-secondary);
		line-height: var(--leading-normal);
	}

	.shared-label {
		color: var(--text-muted);
	}

	.more {
		color: var(--color-marinara-600);
	}

	.compare-link {
		display: block;
		padding: var(--space-2) var(--space-3);
		font-size: var(--text-xs);
		color: var(--color-marinara-600);
		text-decoration: none;
		text-align: center;
		border-top: var(--border-width-thin) solid var(--border-light);
		background: var(--bg-surface);
	}

	.compare-link:hover {
		background: var(--color-marinara-50);
		text-decoration: underline;
	}

	/* Modal content styles */
	.scale-note {
		background: var(--color-basil-100);
		padding: var(--space-2);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		color: var(--color-basil-700);
		margin: 0 0 var(--space-4);
	}

	.list-options {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		margin-bottom: var(--space-4);
	}

	.list-option {
		width: 100%;
		padding: var(--space-3) var(--space-4);
		background: var(--bg-surface);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-md);
		cursor: pointer;
		text-align: left;
		font-size: var(--text-base);
		transition: all var(--transition-fast);
	}

	.list-option:hover:not(:disabled) {
		background: var(--color-pasta-100);
		border-color: var(--color-marinara-500);
	}

	.list-option:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.create-new {
		border-top: var(--border-width-thin) solid var(--border-light);
		padding-top: var(--space-4);
	}

	.create-label {
		margin: 0 0 var(--space-2);
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.create-new form {
		display: flex;
		gap: var(--space-2);
	}

	.create-new input {
		flex: 1;
		padding: var(--space-2);
		border: var(--border-width-thin) solid var(--border-default);
		border-radius: var(--radius-md);
	}

	.create-new button {
		padding: var(--space-2) var(--space-4);
		background: var(--color-marinara-600);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		cursor: pointer;
		white-space: nowrap;
	}

	.create-new button:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	/* Nutrition section */
	.nutrition-section {
		margin-top: var(--space-8);
		padding-top: var(--space-6);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.nutrition-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
		width: 100%;
		text-align: left;
	}

	.nutrition-toggle:hover {
		opacity: 0.8;
	}

	.nutrition-toggle h2 {
		margin: 0;
	}

	.toggle-icon {
		font-size: var(--text-sm);
		color: var(--color-marinara-600);
		width: 1em;
	}

	.nutrition-content {
		margin-top: var(--space-4);
	}

	/* Decisions section */
	.decisions-section {
		margin-top: var(--space-8);
		padding-top: var(--space-6);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.section-toggle {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		background: none;
		border: none;
		cursor: pointer;
		padding: 0;
		width: 100%;
		text-align: left;
	}

	.section-toggle:hover {
		opacity: 0.8;
	}

	.section-toggle h2 {
		margin: 0;
	}

	.decisions-content {
		margin-top: var(--space-4);
	}

	.decisions-hint {
		font-size: var(--text-sm);
		color: var(--text-muted);
		margin-bottom: var(--space-4);
	}

	.decision-item {
		margin-bottom: var(--space-4);
		padding: var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.decision-ingredient-text {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		margin-bottom: var(--space-2);
	}

	/* Responsive */
	@media (max-width: 768px) {
		.recipe-hero {
			min-height: 200px;
		}

		.recipe-hero-img {
			min-height: 200px;
		}

		h1 {
			font-size: var(--text-2xl);
		}

		.recipe-content {
			padding: var(--space-4);
		}

		.meta-bar {
			gap: var(--space-4);
			flex-wrap: wrap;
		}

		.action-bar {
			gap: var(--space-2);
		}

		.scale-controls {
			margin-left: 0;
			width: 100%;
			justify-content: center;
			margin-top: var(--space-2);
		}

		.recipe-body {
			grid-template-columns: 1fr;
		}

		.section-header {
			flex-direction: column;
			align-items: flex-start;
			gap: var(--space-3);
		}

		.similar-grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}

	/* Print styles */
	@media print {
		.no-print {
			display: none !important;
		}

		.recipe-detail {
			box-shadow: none;
		}

		.recipe-hero {
			max-height: 300px;
		}

		.recipe-hero-img {
			max-height: 300px;
		}

		.recipe-content {
			padding: var(--space-4) 0;
		}

		.recipe-body {
			grid-template-columns: 300px 1fr;
		}

		.ingredients,
		.instructions,
		.notes {
			page-break-inside: avoid;
		}
	}
</style>
