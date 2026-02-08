<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { browse, recipes, type Recipe, type RecipeNutrition, type NutritionSource } from '$lib/api/client';
	import NutritionPanel from '$lib/components/NutritionPanel.svelte';
	import IngredientDiagnostics from '$lib/components/IngredientDiagnostics.svelte';
	import PrepList from '$lib/components/PrepList.svelte';

	let recipe = $state<Recipe | null>(null);
	let loading = $state(true);
	let error = $state('');
	let scale = $state(1);
	let adding = $state(false);
	let added = $state(false);

	// Nutrition state
	let nutrition = $state<RecipeNutrition | null>(null);
	let loadingNutrition = $state(false);
	let nutritionError = $state('');
	let showNutrition = $state(false);
	let nutritionSource = $state<NutritionSource>('composite');

	const domain = $derived($page.params.domain);
	const recipeId = $derived($page.params.id);

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	onMount(async () => {
		const token = authStore.getToken();
		if (!token || !domain || !recipeId) return;

		try {
			const result = await browse.getRecipe(token, domain, recipeId);
			recipe = result.data;
		} catch {
			error = 'Recipe not found';
		} finally {
			loading = false;
		}
	});

	async function addToMyRecipes() {
		if (!recipe) return;

		const token = authStore.getToken();
		if (!token) return;

		adding = true;

		try {
			await recipes.create(token, {
				title: recipe.title,
				description: recipe.description || undefined,
				source_url: recipe.source_url || undefined,
				image_url: recipe.image_url || undefined,
				ingredients: recipe.ingredients,
				instructions: recipe.instructions,
				prep_time_minutes: recipe.prep_time_minutes || undefined,
				cook_time_minutes: recipe.cook_time_minutes || undefined,
				total_time_minutes: recipe.total_time_minutes || undefined,
				servings: recipe.servings || undefined,
				notes: recipe.notes || undefined
			});
			added = true;
		} catch {
			alert('Failed to add recipe. It may already be in your collection.');
		} finally {
			adding = false;
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

	function scaleIngredient(text: string): string {
		if (scale === 1) return text;

		// First, scale the primary quantity at the start
		// Include unicode fractions in the character class
		let result = text.replace(/^([\d\s\/\.½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]+)(\s*)/, (match, qty, space) => {
			const scaled = parseQuantity(qty) * scale;
			// Always ensure a space after the quantity
			return formatQuantity(scaled) + ' ';
		});

		// Then scale any parenthetical measurements
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

		const mixedMatch = str.match(/^(\d+)\s+(\d+)\/(\d+)$/);
		if (mixedMatch) {
			const whole = parseInt(mixedMatch[1]);
			const num = parseInt(mixedMatch[2]);
			const den = parseInt(mixedMatch[3]);
			return whole + num / den;
		}

		const fractionMatch = str.match(/^(\d+)\/(\d+)$/);
		if (fractionMatch) {
			return parseInt(fractionMatch[1]) / parseInt(fractionMatch[2]);
		}

		const num = parseFloat(str);
		return isNaN(num) ? 0 : num;
	}

	function formatQuantity(num: number): string {
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

		for (const [val, str] of fractions) {
			if (Math.abs(frac - val) < 0.03) {
				return whole > 0 ? `${whole}${str}` : str;
			}
		}

		if (frac < 0.03) {
			return whole.toString();
		}

		const rounded = Math.round(num * 100) / 100;
		return rounded % 1 === 0 ? rounded.toString() : rounded.toFixed(2).replace(/\.?0+$/, '');
	}

	function setScale(newScale: number) {
		scale = Math.max(0.25, Math.min(4, newScale));
	}

	async function loadNutrition(forceReload = false) {
		const token = authStore.getToken();
		if (!token || !domain || !recipeId) return;

		// Don't reload if we already have nutrition data (unless forced)
		if (nutrition && !forceReload) return;

		loadingNutrition = true;
		nutritionError = '';
		try {
			const result = await browse.nutrition(token, domain, recipeId, { source: nutritionSource });
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
</script>

{#if loading}
	<div class="loading">Loading recipe...</div>
{:else if error}
	<div class="error">
		<p>{error}</p>
		<a href="/browse/{domain}">Back to {domain}</a>
	</div>
{:else if recipe}
	<article class="recipe-detail">
		<header>
			<div class="header-content">
				<a href="/browse/{domain}" class="back-link">← Back to {domain}</a>
				<h1>{recipe.title}</h1>
				{#if recipe.source_url}
					<a href={recipe.source_url} target="_blank" rel="noopener noreferrer" class="source-link">
						View original at {recipe.source_domain}
					</a>
				{/if}
			</div>
			<div class="actions no-print">
				<button onclick={handlePrint} class="btn">Print</button>
				{#if added}
					<span class="added-badge">Added to your recipes!</span>
				{:else}
					<button onclick={addToMyRecipes} disabled={adding} class="btn btn-primary">
						{adding ? 'Adding...' : 'Add to My Recipes'}
					</button>
				{/if}
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
						<li>{scaleIngredient(ingredient.text)}</li>
					{/each}
				</ul>

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
						selectedSource={nutritionSource}
						on:sourceChange={handleSourceChange}
					/>
				</div>
			{/if}
		</section>

		{#if recipe.ingredients.some(i => i._diagnostics)}
			<section class="diagnostics-section no-print">
				<IngredientDiagnostics ingredients={recipe.ingredients} />
			</section>
		{/if}
	</article>
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

	header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: var(--space-6);
		padding-bottom: var(--space-6);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.back-link {
		color: var(--color-marinara-600);
		text-decoration: none;
		font-size: var(--text-sm);
		display: inline-block;
		margin-bottom: var(--space-2);
	}

	.back-link:hover {
		text-decoration: underline;
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
		align-items: center;
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

	.btn:hover:not(:disabled) {
		background: var(--bg-surface);
	}

	.btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.btn-primary {
		background: var(--color-basil-500);
		color: var(--color-white);
		border-color: var(--color-basil-500);
	}

	.btn-primary:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.added-badge {
		background: var(--color-success-bg);
		color: var(--color-basil-800);
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
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

		header {
			flex-direction: column;
			gap: var(--space-4);
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
