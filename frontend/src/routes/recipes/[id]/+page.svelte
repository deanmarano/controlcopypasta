<script lang="ts">
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { recipes, ingredients as ingredientsApi, shoppingLists, type Recipe, type Ingredient, type SimilarRecipe, type ScaledIngredient, type ShoppingList, type RecipeNutrition } from '$lib/api/client';
	import NutritionPanel from '$lib/components/NutritionPanel.svelte';
	import Modal from '$lib/components/Modal.svelte';
	import IngredientDiagnostics from '$lib/components/IngredientDiagnostics.svelte';
	import PrepList from '$lib/components/PrepList.svelte';

	let recipe = $state<Recipe | null>(null);
	let loading = $state(true);
	let error = $state('');
	let scale = $state(1);
	let similarRecipes = $state<SimilarRecipe[]>([]);
	let loadingSimilar = $state(false);
	let scalingResults = $state<Map<string, ScaledIngredient>>(new Map());
	let loadingScaling = $state(false);
	let showShoppingTips = $state(false);

	// Nutrition state
	let nutrition = $state<RecipeNutrition | null>(null);
	let loadingNutrition = $state(false);
	let nutritionError = $state('');
	let showNutrition = $state(false);

	// Shopping list modal state
	let showShoppingModal = $state(false);
	let availableLists = $state<ShoppingList[]>([]);
	let loadingLists = $state(false);
	let newListName = $state('');
	let addingToList = $state(false);

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
		showNutrition = false;

		try {
			const result = await recipes.get(token, recipeId);
			recipe = result.data;
			// Load similar recipes in the background
			loadSimilarRecipes();
		} catch {
			error = 'Recipe not found';
		} finally {
			loading = false;
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

	async function loadNutrition() {
		const token = authStore.getToken();
		if (!token || !recipe) return;

		// Don't reload if we already have nutrition data
		if (nutrition) return;

		loadingNutrition = true;
		nutritionError = '';
		try {
			const result = await recipes.nutrition(token, recipe.id);
			nutrition = result.data;
		} catch (e) {
			nutritionError = 'Could not load nutrition data';
		} finally {
			loadingNutrition = false;
		}
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
		// Convert to nice fractions for common values
		const fractions: Record<number, string> = {
			0.25: '1/4',
			0.33: '1/3',
			0.5: '1/2',
			0.67: '2/3',
			0.75: '3/4'
		};

		const whole = Math.floor(num);
		const frac = num - whole;

		// Check if the fractional part is close to a common fraction
		for (const [val, str] of Object.entries(fractions)) {
			if (Math.abs(frac - parseFloat(val)) < 0.05) {
				return whole > 0 ? `${whole} ${str}` : str;
			}
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

		<header>
			<div class="header-content">
				<h1>{recipe.title}</h1>
				{#if recipe.source_url}
					<a href={recipe.source_url} target="_blank" rel="noopener noreferrer" class="source-link">
						View original at {recipe.source_domain}
					</a>
				{/if}
			</div>
			<div class="actions no-print">
				<button onclick={openShoppingModal} class="btn btn-shopping">Add to List</button>
				<button onclick={handlePrint} class="btn">Print</button>
				<a href="/recipes/{recipe.id}/edit" class="btn">Edit</a>
				{#if recipe.archived_at}
					<button onclick={handleUnarchive} class="btn">Unarchive</button>
				{:else}
					<button onclick={handleArchive} class="btn">Archive</button>
				{/if}
				<button onclick={handleDelete} class="btn btn-danger">Delete</button>
			</div>
		</header>

		{#if recipe.image_url}
			<img src={recipe.image_url} alt={recipe.title} class="recipe-image" />
		{/if}

		{#if recipe.description}
			<p class="description">{recipe.description}</p>
		{/if}

		<div class="meta-grid">
			{#if recipe.prep_time_minutes}
				<div class="meta-item">
					<span class="label">Prep Time</span>
					<span class="value">{formatTime(recipe.prep_time_minutes)}</span>
				</div>
			{/if}
			{#if recipe.cook_time_minutes}
				<div class="meta-item">
					<span class="label">Cook Time</span>
					<span class="value">{formatTime(recipe.cook_time_minutes)}</span>
				</div>
			{/if}
			{#if recipe.total_time_minutes}
				<div class="meta-item">
					<span class="label">Total Time</span>
					<span class="value">{formatTime(recipe.total_time_minutes)}</span>
				</div>
			{/if}
			{#if recipe.servings}
				<div class="meta-item">
					<span class="label">Servings</span>
					<span class="value">{recipe.servings}</span>
				</div>
			{/if}
		</div>

		{#if recipe.tags.length > 0}
			<div class="tags no-print">
				{#each recipe.tags as tag}
					<span class="tag">{tag.name}</span>
				{/each}
			</div>
		{/if}

		<div class="recipe-sections">
			<section class="ingredients">
				<div class="section-header">
					<h2>Ingredients</h2>
					<div class="scale-controls no-print">
						<button onclick={() => setScale(scale - 0.25)} class="scale-btn" disabled={scale <= 0.25}>-</button>
						<span class="scale-value">{scale}x</span>
						<button onclick={() => setScale(scale + 0.25)} class="scale-btn" disabled={scale >= 4}>+</button>
					</div>
				</div>
				<ul>
					{#each recipe.ingredients as ingredient}
						<li>
							<span class="ingredient-text">{scaleIngredient(ingredient.text)}</span>
							{#if scale !== 1 && getPackageSuggestion(ingredient.text)}
								<span class="package-hint" title={getPackageSuggestion(ingredient.text)}>
									<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
								</span>
							{/if}
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
			</section>

			<section class="instructions">
				<h2>Instructions</h2>
				<ol>
					{#each recipe.instructions as instruction}
						<li>{instruction.text}</li>
					{/each}
				</ol>
			</section>
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
					/>
				</div>
			{/if}
		</section>

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
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
	}

	.archived-banner {
		background: var(--color-pasta-200);
		color: var(--color-pasta-800);
		padding: var(--space-3) var(--space-4);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-6);
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

	header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		gap: var(--space-4);
		margin-bottom: var(--space-6);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	h1 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-3xl);
		font-family: var(--font-serif);
		color: var(--color-marinara-800);
	}

	.source-link {
		color: var(--color-marinara-600);
		font-size: var(--text-sm);
	}

	.actions {
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
		justify-content: flex-end;
	}

	@media (max-width: 768px) {
		header {
			flex-direction: column;
		}

		h1 {
			font-size: var(--text-2xl);
		}

		.actions {
			width: 100%;
			display: grid;
			grid-template-columns: repeat(2, 1fr);
			gap: var(--space-2);
		}

		.actions .btn {
			text-align: center;
			padding: var(--space-3) var(--space-2);
		}

		.actions .btn-shopping {
			grid-column: span 2;
		}

		.recipe-detail {
			padding: var(--space-4);
		}
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

	.btn-danger {
		color: var(--color-marinara-600);
		border-color: var(--color-marinara-600);
	}

	.btn-danger:hover {
		background: var(--color-marinara-600);
		color: var(--color-white);
	}

	.recipe-image {
		width: 100%;
		max-height: 400px;
		object-fit: cover;
		border-radius: var(--radius-lg);
		margin-bottom: var(--space-6);
	}

	.description {
		font-size: var(--text-lg);
		color: var(--text-secondary);
		line-height: var(--leading-relaxed);
		margin-bottom: var(--space-6);
	}

	.meta-grid {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-8);
		margin-bottom: var(--space-6);
		padding: var(--space-4);
		background: var(--color-pasta-100);
		border-radius: var(--radius-lg);
	}

	.meta-item {
		display: flex;
		flex-direction: column;
	}

	.label {
		font-size: var(--text-xs);
		color: var(--text-muted);
		text-transform: uppercase;
		letter-spacing: var(--tracking-wider);
	}

	.value {
		font-size: var(--text-lg);
		font-weight: var(--font-medium);
		color: var(--text-primary);
	}

	.tags {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
		margin-bottom: var(--space-6);
	}

	.tag {
		background: var(--color-marinara-500);
		color: var(--color-white);
		padding: var(--space-1) var(--space-3);
		border-radius: var(--radius-full);
		font-size: var(--text-sm);
	}

	.recipe-sections {
		display: grid;
		grid-template-columns: 1fr 2fr;
		gap: var(--space-8);
		margin-bottom: var(--space-6);
	}

	@media (max-width: 768px) {
		.recipe-sections {
			grid-template-columns: 1fr;
		}

		.meta-grid {
			gap: var(--space-4);
		}

		.section-header {
			flex-direction: column;
			align-items: flex-start;
			gap: var(--space-3);
		}

		.scale-controls {
			width: 100%;
			justify-content: center;
			background: var(--color-pasta-100);
			padding: var(--space-2);
			border-radius: var(--radius-md);
		}

		.scale-btn {
			width: 44px;
			height: 44px;
			font-size: var(--text-lg);
		}

		.similar-grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}

	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-4);
	}

	.section-header h2 {
		margin: 0;
		padding-bottom: var(--space-2);
		border-bottom: var(--border-width-default) solid var(--color-marinara-500);
	}

	h2 {
		font-size: var(--text-xl);
		margin: 0 0 var(--space-4);
		padding-bottom: var(--space-2);
		border-bottom: var(--border-width-default) solid var(--color-marinara-500);
		color: var(--color-marinara-700);
	}

	.scale-controls {
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
	}

	.ingredients ul {
		list-style: disc;
		padding-left: var(--space-6);
	}

	.ingredients li {
		margin-bottom: var(--space-2);
		line-height: var(--leading-relaxed);
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

	.instructions ol {
		padding-left: var(--space-6);
	}

	.instructions li {
		margin-bottom: var(--space-4);
		line-height: var(--leading-relaxed);
	}

	.notes {
		background: var(--color-pasta-100);
		padding: var(--space-4);
		border-radius: var(--radius-lg);
		border-left: var(--border-width-thick) solid var(--color-pasta-500);
	}

	.notes h2 {
		border-bottom-color: var(--color-pasta-500);
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

	.similar-recipes h2 {
		border-bottom-color: var(--color-basil-500);
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
		background: var(--color-basil-500);
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

	/* Shopping list button */
	.btn-shopping {
		background: var(--color-basil-500);
		color: var(--color-white);
		border-color: var(--color-basil-500);
	}

	.btn-shopping:hover {
		background: var(--color-basil-600);
		border-color: var(--color-basil-600);
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
		background: var(--color-basil-500);
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
		padding-bottom: 0;
		border-bottom: none;
	}

	.toggle-icon {
		font-size: var(--text-sm);
		color: var(--color-marinara-600);
		width: 1em;
	}

	.nutrition-content {
		margin-top: var(--space-4);
	}

	/* Print styles */
	@media print {
		.no-print {
			display: none !important;
		}

		.recipe-detail {
			box-shadow: none;
			padding: 0;
		}

		header {
			border-bottom: 2px solid #000;
		}

		.recipe-image {
			max-height: 300px;
			page-break-inside: avoid;
		}

		.recipe-sections {
			grid-template-columns: 1fr 2fr;
		}

		.ingredients,
		.instructions,
		.notes {
			page-break-inside: avoid;
		}

		h2 {
			border-bottom-color: #000;
		}

		.notes {
			border-left-color: #000;
			background: #f5f5f5;
		}
	}
</style>
