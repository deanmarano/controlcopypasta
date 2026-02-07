<script lang="ts">
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import {
		admin,
		type AdminIngredient,
		type AdminIngredientOptions,
		type IngredientEnrichmentStats,
		type NutritionQualityStats,
		type ParsingStats,
		type TestScorerResult,
		type MatchingRules
	} from '$lib/api/client';

	let ingredients = $state<AdminIngredient[]>([]);
	let options = $state<AdminIngredientOptions | null>(null);
	let enrichmentStats = $state<IngredientEnrichmentStats | null>(null);
	let qualityStats = $state<NutritionQualityStats | null>(null);
	let parsingStats = $state<ParsingStats | null>(null);
	let loading = $state(true);
	let error = $state('');
	let message = $state('');
	let accessDenied = $state(false);
	let showQualityIssues = $state(false);
	let showAdvanced = $state(false);
	let refetchingIds = $state<Set<string>>(new Set());
	let skippingIds = $state<Set<string>>(new Set());

	// Filters
	let categoryFilter = $state('protein');
	let animalTypeFilter = $state('');
	let showMissingOnly = $state(true);
	let searchQuery = $state('');

	// Editing animal_type
	let editingId = $state<string | null>(null);
	let editingValue = $state<string | null>(null);
	let saving = $state(false);

	// Editing similarity_name
	let editingSimilarityId = $state<string | null>(null);
	let editingSimilarityValue = $state<string | null>(null);
	let savingSimilarity = $state(false);

	// Test Scorer
	let scorerInput = $state('');
	let scorerResult = $state<TestScorerResult | null>(null);
	let scorerLoading = $state(false);
	let scorerError = $state('');

	// Matching Rules Modal
	let rulesModalIngredient = $state<AdminIngredient | null>(null);
	let rulesEditJson = $state('');
	let rulesJsonError = $state('');
	let rulesSaving = $state(false);

	$effect(() => {
		if (!$isAuthenticated) goto('/login');
	});

	onMount(async () => {
		await Promise.all([loadOptions(), loadIngredients(), loadEnrichmentStats(), loadQualityStats(), loadParsingStats()]);
	});

	async function loadOptions() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			options = await admin.ingredients.options(token);
		} catch {
			// Options are optional
		}
	}

	async function loadIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		loading = true;
		error = '';
		try {
			const params: {
				category?: string;
				animal_type?: string;
				missing_animal_type?: boolean;
				search?: string;
			} = {};

			if (categoryFilter) params.category = categoryFilter;
			if (animalTypeFilter) params.animal_type = animalTypeFilter;
			if (showMissingOnly) params.missing_animal_type = true;
			if (searchQuery) params.search = searchQuery;

			const result = await admin.ingredients.list(token, params);
			ingredients = result.data;
		} catch (e) {
			if (e instanceof Error && 'status' in e && (e as { status: number }).status === 403) {
				accessDenied = true;
			} else {
				error = 'Failed to load ingredients';
			}
		} finally {
			loading = false;
		}
	}

	function startEdit(ingredient: AdminIngredient) {
		editingId = ingredient.id;
		editingValue = ingredient.animal_type;
	}

	function cancelEdit() {
		editingId = null;
		editingValue = null;
	}

	async function saveEdit(ingredient: AdminIngredient) {
		const token = authStore.getToken();
		if (!token || editingId !== ingredient.id) return;

		saving = true;
		try {
			const result = await admin.ingredients.update(token, ingredient.id, {
				animal_type: editingValue || null
			});
			// Update the ingredient in the list
			ingredients = ingredients.map((i) => (i.id === ingredient.id ? result.data : i));
			editingId = null;
			editingValue = null;
		} catch {
			error = 'Failed to save changes';
		} finally {
			saving = false;
		}
	}

	async function quickSetAnimalType(ingredient: AdminIngredient, animalType: string) {
		const token = authStore.getToken();
		if (!token) return;

		try {
			const result = await admin.ingredients.update(token, ingredient.id, {
				animal_type: animalType
			});
			ingredients = ingredients.map((i) => (i.id === ingredient.id ? result.data : i));
		} catch {
			error = 'Failed to save changes';
		}
	}

	function startEditSimilarity(ingredient: AdminIngredient) {
		editingSimilarityId = ingredient.id;
		editingSimilarityValue = ingredient.similarity_name;
	}

	function cancelEditSimilarity() {
		editingSimilarityId = null;
		editingSimilarityValue = null;
	}

	async function saveEditSimilarity(ingredient: AdminIngredient) {
		const token = authStore.getToken();
		if (!token || editingSimilarityId !== ingredient.id) return;

		savingSimilarity = true;
		try {
			const result = await admin.ingredients.update(token, ingredient.id, {
				similarity_name: editingSimilarityValue || null
			});
			ingredients = ingredients.map((i) => (i.id === ingredient.id ? result.data : i));
			editingSimilarityId = null;
			editingSimilarityValue = null;
		} catch {
			error = 'Failed to save similarity name';
		} finally {
			savingSimilarity = false;
		}
	}

	function formatLabel(value: string): string {
		return value
			.split('_')
			.map((word) => word.charAt(0).toUpperCase() + word.slice(1))
			.join(' ');
	}

	function formatNumber(n: number): string {
		return n.toLocaleString();
	}

	// Parse datetime string from server (assumes UTC) and format to local time
	function formatLocalTime(dateStr: string): string {
		// If no timezone indicator, assume UTC
		const normalized = dateStr.endsWith('Z') || dateStr.includes('+') ? dateStr : dateStr + 'Z';
		return new Date(normalized).toLocaleTimeString();
	}

	function formatLocalDateTime(dateStr: string): string {
		const normalized = dateStr.endsWith('Z') || dateStr.includes('+') ? dateStr : dateStr + 'Z';
		return new Date(normalized).toLocaleString();
	}

	async function loadEnrichmentStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.ingredientEnrichment(token);
			enrichmentStats = result.data;
		} catch {
			enrichmentStats = null;
		}
	}

	async function loadQualityStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.nutritionQuality(token);
			qualityStats = result.data;
		} catch {
			qualityStats = null;
		}
	}

	async function loadParsingStats() {
		const token = authStore.getToken();
		if (!token) return;
		try {
			const result = await admin.scraper.parsingStats(token);
			parsingStats = result.data;
		} catch {
			parsingStats = null;
		}
	}

	async function parseAllIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			await admin.scraper.parseIngredients(token);
			message = 'Started parsing ingredients for all unparsed recipes';
		} catch {
			error = 'Failed to start ingredient parsing';
		}
	}

	async function reparseAllIngredients() {
		const token = authStore.getToken();
		if (!token) return;

		if (!confirm('This will reprocess ALL recipes to regenerate pre_steps, alternatives, and recipe references. Continue?')) {
			return;
		}

		error = '';
		message = '';

		try {
			await admin.scraper.parseIngredients(token, { force: true });
			message = 'Started reparsing ALL recipes (this may take a while)';
		} catch {
			error = 'Failed to start ingredient reparsing';
		}
	}

	async function enqueueNutrition() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.enqueueNutrition(token);
			message = `Enqueued ${result.data.enqueued} ingredients for nutrition enrichment`;
			await Promise.all([loadEnrichmentStats(), loadQualityStats()]);
		} catch {
			error = 'Failed to enqueue nutrition enrichment';
		}
	}

	async function enqueueDensity() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.enqueueDensity(token);
			message = `Enqueued ${result.data.enqueued} ingredients for density enrichment`;
			await loadEnrichmentStats();
		} catch {
			error = 'Failed to enqueue density enrichment';
		}
	}

	async function fixPrimaryNutrition() {
		const token = authStore.getToken();
		if (!token) return;

		error = '';
		message = '';

		try {
			const result = await admin.scraper.fixPrimaryNutrition(token);
			message = `Fixed ${result.data.fixed} ingredients missing primary nutrition source`;
			await loadQualityStats();
		} catch {
			error = 'Failed to fix primary nutrition sources';
		}
	}

	async function refetchNutrition() {
		const token = authStore.getToken();
		if (!token) return;

		if (!confirm('This will delete ALL existing nutrition data and refetch from all sources. This is useful after improving the matching algorithm. Continue?')) {
			return;
		}

		error = '';
		message = '';

		try {
			const result = await admin.scraper.refetchNutrition(token);
			message = `Started refetching nutrition for ${result.data.enqueued} ingredients`;
			await Promise.all([loadEnrichmentStats(), loadQualityStats()]);
		} catch {
			error = 'Failed to start nutrition refetch';
		}
	}

	async function refetchIngredient(ingredientId: string, ingredientName: string) {
		const token = authStore.getToken();
		if (!token) return;

		refetchingIds = new Set([...refetchingIds, ingredientId]);

		try {
			await admin.scraper.refetchIngredientNutrition(token, ingredientId);
			message = `Queued refetch for "${ingredientName}"`;
		} catch {
			error = `Failed to queue refetch for "${ingredientName}"`;
		} finally {
			// Keep showing as "queued" for a bit, then remove
			setTimeout(() => {
				refetchingIds = new Set([...refetchingIds].filter(id => id !== ingredientId));
			}, 3000);
		}
	}

	async function markSkipNutrition(ingredientId: string, ingredientName: string) {
		const token = authStore.getToken();
		if (!token) return;

		skippingIds = new Set([...skippingIds, ingredientId]);

		try {
			await admin.ingredients.setSkipNutrition(token, ingredientId, true);
			message = `Marked "${ingredientName}" as no nutrition needed`;
			// Refresh quality stats to remove it from the list
			await loadQualityStats();
		} catch {
			error = `Failed to update "${ingredientName}"`;
		} finally {
			skippingIds = new Set([...skippingIds].filter(id => id !== ingredientId));
		}
	}

	// Debounced search
	let searchTimeout: ReturnType<typeof setTimeout>;
	function handleSearchInput() {
		clearTimeout(searchTimeout);
		searchTimeout = setTimeout(() => {
			loadIngredients();
		}, 300);
	}

	// Test Scorer
	async function runTestScorer() {
		const token = authStore.getToken();
		if (!token || !scorerInput.trim()) return;

		scorerLoading = true;
		scorerError = '';
		scorerResult = null;

		try {
			const result = await admin.ingredients.testScorer(token, scorerInput.trim());
			scorerResult = result.data;
		} catch {
			scorerError = 'Failed to test scorer';
		} finally {
			scorerLoading = false;
		}
	}

	// Matching Rules Modal
	function openRulesModal(ingredient: AdminIngredient) {
		rulesModalIngredient = ingredient;
		rulesEditJson = ingredient.matching_rules
			? JSON.stringify(ingredient.matching_rules, null, 2)
			: JSON.stringify({
				boost_words: [],
				anti_patterns: [],
				required_words: [],
				exclude_patterns: [],
				boost_amount: 0.05,
				anti_penalty: 0.15
			}, null, 2);
		rulesJsonError = '';
	}

	function closeRulesModal() {
		rulesModalIngredient = null;
		rulesEditJson = '';
		rulesJsonError = '';
	}

	async function saveMatchingRules() {
		const token = authStore.getToken();
		if (!token || !rulesModalIngredient) return;

		// Validate JSON
		let parsedRules: MatchingRules | null = null;
		try {
			const trimmed = rulesEditJson.trim();
			if (trimmed === '' || trimmed === '{}' || trimmed === 'null') {
				parsedRules = null;
			} else {
				parsedRules = JSON.parse(trimmed);
			}
		} catch {
			rulesJsonError = 'Invalid JSON';
			return;
		}

		rulesSaving = true;
		rulesJsonError = '';

		try {
			const result = await admin.ingredients.update(token, rulesModalIngredient.id, {
				matching_rules: parsedRules
			});
			// Update in list
			ingredients = ingredients.map(i =>
				i.id === rulesModalIngredient!.id ? result.data : i
			);
			message = `Updated matching rules for ${rulesModalIngredient.display_name}`;
			closeRulesModal();
		} catch {
			rulesJsonError = 'Failed to save matching rules';
		} finally {
			rulesSaving = false;
		}
	}

	function formatScore(score: number): string {
		return (score * 100).toFixed(1) + '%';
	}
</script>

<div class="admin-page">
	<h1>Admin: Ingredients</h1>

	{#if accessDenied}
		<div class="access-denied">
			<h2>Access Denied</h2>
			<p>You do not have permission to view this page. Admin access is required.</p>
			<a href="/settings">Back to Settings</a>
		</div>
	{:else}

	{#if message}
		<p class="message">{message}</p>
	{/if}

	<!-- Test Scorer Section -->
	<section class="scorer-section">
		<h2>Test Ingredient Scorer</h2>
		<div class="scorer-form">
			<input
				type="text"
				bind:value={scorerInput}
				placeholder="Enter ingredient text (e.g., '2 boneless skinless chicken breasts')..."
				onkeydown={(e) => e.key === 'Enter' && runTestScorer()}
			/>
			<button onclick={runTestScorer} disabled={scorerLoading || !scorerInput.trim()} class="btn-primary">
				{scorerLoading ? 'Testing...' : 'Test'}
			</button>
		</div>
		{#if scorerError}
			<p class="error">{scorerError}</p>
		{/if}
		{#if scorerResult}
			<div class="scorer-results">
				<div class="scorer-match">
					<h3>Best Match</h3>
					{#if scorerResult.match.canonical_name}
						<div class="match-card">
							<span class="match-name">{scorerResult.match.canonical_name}</span>
							<span class="match-score" class:high={scorerResult.match.confidence >= 0.9} class:medium={scorerResult.match.confidence >= 0.7 && scorerResult.match.confidence < 0.9} class:low={scorerResult.match.confidence < 0.7}>
								{formatScore(scorerResult.match.confidence)}
							</span>
						</div>
						{#if scorerResult.match.scoring_details}
							<div class="scoring-details">
								{#if scorerResult.match.scoring_details.boost_count}
									<span class="detail boost">+{scorerResult.match.scoring_details.boost_count} boost</span>
								{/if}
								{#if scorerResult.match.scoring_details.anti_count}
									<span class="detail anti">-{scorerResult.match.scoring_details.anti_count} anti</span>
								{/if}
								{#if scorerResult.match.scoring_details.base_score !== undefined}
									<span class="detail base">base: {formatScore(scorerResult.match.scoring_details.base_score)}</span>
								{/if}
							</div>
						{/if}
					{:else}
						<p class="no-match">No match found</p>
					{/if}
				</div>
				{#if scorerResult.alternatives.length > 0}
					<div class="scorer-alternatives">
						<h3>Alternatives</h3>
						<ul>
							{#each scorerResult.alternatives as alt}
								<li class="alt-item">
									<span class="alt-name">{alt.canonical_name}</span>
									<span class="alt-score" class:high={alt.score >= 0.9} class:medium={alt.score >= 0.7 && alt.score < 0.9} class:low={alt.score < 0.7}>
										{formatScore(alt.score)}
									</span>
									{#if alt.has_rules}
										<span class="has-rules" title="Has matching rules">R</span>
									{/if}
								</li>
							{/each}
						</ul>
					</div>
				{/if}
			</div>
		{/if}
	</section>

	<!-- Ingredient Parsing Status -->
	{#if parsingStats}
		<section class="parsing-section">
			<h2>Ingredient Parsing</h2>
			<div class="parsing-overview">
				<div class="parsing-progress">
					<div class="progress-bar">
						<div class="progress-fill" style="width: {parsingStats.percent_complete}%"></div>
					</div>
					<span class="progress-text">{parsingStats.percent_complete}% complete</span>
				</div>
				<div class="parsing-counts">
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.parsed_recipes)}</span>
						<span class="parsing-stat-label">Parsed</span>
					</div>
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.unparsed_recipes)}</span>
						<span class="parsing-stat-label">Unparsed</span>
					</div>
					<div class="parsing-stat">
						<span class="parsing-stat-value">{formatNumber(parsingStats.total_recipes)}</span>
						<span class="parsing-stat-label">Total</span>
					</div>
				</div>
				<div class="parsing-actions">
					<button onclick={parseAllIngredients} class="btn-secondary">Parse Unparsed</button>
					<button onclick={reparseAllIngredients} class="btn-primary">Reparse All Recipes</button>
				</div>
			</div>

			{#if parsingStats.active_jobs.length > 0}
				<div class="parsing-jobs">
					<h3>Active Parsing Jobs ({parsingStats.active_jobs.length})</h3>
					<div class="jobs-list">
						{#each parsingStats.active_jobs as job}
							<div class="job-item">
								<span class="job-id">#{job.id}</span>
								<span class="job-state" class:executing={job.state === 'executing'} class:available={job.state === 'available'} class:scheduled={job.state === 'scheduled'}>{job.state}</span>
								<span class="job-offset">Offset: {job.offset}</span>
								{#if job.force}
									<span class="job-force">Force</span>
								{/if}
								<span class="job-time">{formatLocalTime(job.inserted_at)}</span>
							</div>
						{/each}
					</div>
				</div>
			{/if}

			{#if parsingStats.last_completed}
				<div class="parsing-last">
					<span>Last completed batch: offset {parsingStats.last_completed.offset} at {formatLocalDateTime(parsingStats.last_completed.completed_at)}</span>
				</div>
			{/if}
		</section>
	{/if}

	<!-- Data Quality Section -->
	{#if qualityStats}
		<section class="quality-section">
			<h2>Data Quality</h2>
			<div class="quality-grid">
				<div class="quality-card">
					<div class="quality-header">
						<h3>Nutrition Coverage</h3>
						<span class="quality-percent">{qualityStats.coverage.coverage_percent}%</span>
					</div>
					<div class="quality-stats">
						<div class="quality-stat">
							<span class="stat-value">{formatNumber(qualityStats.coverage.with_nutrition)}</span>
							<span class="stat-label">With Data</span>
						</div>
						<div class="quality-stat">
							<span class="stat-value">{formatNumber(qualityStats.coverage.without_nutrition)}</span>
							<span class="stat-label">Missing</span>
						</div>
						<div class="quality-stat">
							<span class="stat-value">{formatNumber(qualityStats.coverage.total_ingredients)}</span>
							<span class="stat-label">Total</span>
						</div>
					</div>
					<div class="quality-progress">
						<div class="progress-bar">
							<div class="progress-fill" style="width: {qualityStats.coverage.coverage_percent}%"></div>
						</div>
					</div>
				</div>

				<div class="quality-card">
					<div class="quality-header">
						<h3>Primary Sources</h3>
						{#if qualityStats.quality.without_primary === 0}
							<span class="quality-badge success">All Set</span>
						{:else}
							<span class="quality-badge warning">{qualityStats.quality.without_primary} Missing</span>
						{/if}
					</div>
					<div class="quality-stats">
						<div class="quality-stat">
							<span class="stat-value">{formatNumber(qualityStats.quality.with_primary_set)}</span>
							<span class="stat-label">Primary Set</span>
						</div>
						<div class="quality-stat">
							<span class="stat-value">{parseFloat(qualityStats.quality.avg_confidence).toFixed(2)}</span>
							<span class="stat-label">Avg Confidence</span>
						</div>
					</div>
					{#if Object.keys(qualityStats.quality.primary_by_source).length > 0}
						<div class="source-breakdown">
							{#each Object.entries(qualityStats.quality.primary_by_source) as [source, count]}
								<span class="source-badge">{source}: {formatNumber(count as number)}</span>
							{/each}
						</div>
					{/if}
					{#if qualityStats.quality.without_primary > 0}
						<button onclick={fixPrimaryNutrition} class="btn-small">Fix Missing Primary</button>
					{/if}
				</div>

				<div class="quality-card">
					<div class="quality-header">
						<h3>Issues</h3>
						{#if (qualityStats.issues.missing_calories?.length || 0) === 0 && (qualityStats.issues.missing_nutrition?.length || 0) === 0}
							<span class="quality-badge success">None</span>
						{:else}
							<span class="quality-badge warning">{(qualityStats.issues.missing_calories?.length || 0) + (qualityStats.issues.missing_nutrition?.length || 0)}</span>
						{/if}
					</div>
					<div class="issue-summary">
						<p>No nutrition data: {qualityStats.issues.missing_nutrition?.length || 0}</p>
						<p>Missing calories: {qualityStats.issues.missing_calories?.length || 0}</p>
						<p>Low confidence: {qualityStats.issues.low_confidence_count || 0}</p>
					</div>
					{#if (qualityStats.issues.missing_calories?.length || 0) > 0 || (qualityStats.issues.missing_nutrition?.length || 0) > 0 || (qualityStats.suspicious_matches?.length || 0) > 0}
						<button onclick={() => showQualityIssues = !showQualityIssues} class="btn-small btn-secondary">
							{showQualityIssues ? 'Hide' : 'View'} Details
						</button>
					{/if}
				</div>
			</div>

			{#if showQualityIssues}
				<div class="quality-issues-detail">
					{#if (qualityStats.issues.missing_nutrition?.length || 0) > 0}
						<div class="issue-list">
							<h4>No Nutrition Data ({qualityStats.issues.missing_nutrition?.length || 0})</h4>
							<p class="issue-help">These ingredients don't have nutrition data. Refetch to try again, or mark as "No nutrition needed" for items like water, salt, etc.</p>
							<table class="mini-table">
								<thead>
									<tr><th>Ingredient</th><th>Actions</th></tr>
								</thead>
								<tbody>
									{#each qualityStats.issues.missing_nutrition || [] as item}
										<tr>
											<td>{item.name}</td>
											<td class="action-cell">
												<button
													class="btn-tiny"
													onclick={() => refetchIngredient(item.id, item.name)}
													disabled={refetchingIds.has(item.id)}
												>
													{refetchingIds.has(item.id) ? 'Queued' : 'Refetch'}
												</button>
												<button
													class="btn-tiny btn-muted"
													onclick={() => markSkipNutrition(item.id, item.name)}
													disabled={skippingIds.has(item.id)}
												>
													{skippingIds.has(item.id) ? 'Saving...' : 'No Nutrition Needed'}
												</button>
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{/if}
					{#if (qualityStats.issues.missing_calories?.length || 0) > 0}
						<div class="issue-list">
							<h4>Missing Calories ({qualityStats.issues.missing_calories?.length || 0})</h4>
							<p class="issue-help">These have nutrition data but no calorie value. This may indicate a bad match.</p>
							<table class="mini-table">
								<thead>
									<tr><th>Ingredient</th><th>Actions</th></tr>
								</thead>
								<tbody>
									{#each qualityStats.issues.missing_calories || [] as item}
										<tr>
											<td>{item.name}</td>
											<td class="action-cell">
												<button
													class="btn-tiny"
													onclick={() => refetchIngredient(item.id, item.name)}
													disabled={refetchingIds.has(item.id)}
												>
													{refetchingIds.has(item.id) ? 'Queued' : 'Refetch'}
												</button>
												<button
													class="btn-tiny btn-muted"
													onclick={() => markSkipNutrition(item.id, item.name)}
													disabled={skippingIds.has(item.id)}
												>
													{skippingIds.has(item.id) ? 'Saving...' : 'No Nutrition Needed'}
												</button>
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{/if}
					{#if (qualityStats.suspicious_matches?.length || 0) > 0}
						<div class="issue-list">
							<h4>Suspicious Matches (Low Confidence)</h4>
							<p class="issue-help">These matches have low confidence scores and may be incorrect.</p>
							<table class="mini-table">
								<thead>
									<tr><th>Ingredient</th><th>Matched To</th><th>Source</th><th>Conf</th><th>Actions</th></tr>
								</thead>
								<tbody>
									{#each qualityStats.suspicious_matches || [] as match}
										<tr>
											<td>{match.ingredient}</td>
											<td>{match.matched_to}</td>
											<td>{match.source}</td>
											<td>{match.confidence.toFixed(2)}</td>
											<td class="action-cell">
												<button
													class="btn-tiny"
													onclick={() => refetchIngredient(match.id, match.ingredient)}
													disabled={refetchingIds.has(match.id)}
												>
													{refetchingIds.has(match.id) ? 'Queued' : 'Refetch'}
												</button>
											</td>
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					{/if}
				</div>
			{/if}
		</section>
	{/if}

	<!-- Enrichment Queues Section -->
	{#if enrichmentStats}
		<section class="enrichment-section">
			<h2>Enrichment Queues</h2>
			<div class="enrichment-grid">
				<div class="enrichment-card compact">
					<div class="enrichment-header">
						<h3>Nutrition</h3>
						<span class="queue-status">
							{#if enrichmentStats.nutrition.pending_jobs > 0}
								<span class="status-dot active"></span> {formatNumber(enrichmentStats.nutrition.pending_jobs)} pending
							{:else}
								<span class="status-dot idle"></span> Idle
							{/if}
						</span>
					</div>
					<div class="enrichment-mini-stats">
						<span>{formatNumber(enrichmentStats.nutrition.with_nutrition_data || 0)} complete</span>
						<span>{formatNumber(enrichmentStats.nutrition.total_ingredients - (enrichmentStats.nutrition.with_nutrition_data || 0))} missing</span>
					</div>
					<div class="enrichment-rate-compact">
						Today: {enrichmentStats.nutrition.completed_today}/{enrichmentStats.nutrition.daily_limit} |
						Hour: {enrichmentStats.nutrition.completed_this_hour}/{enrichmentStats.nutrition.hourly_limit}
					</div>
					<button onclick={enqueueNutrition} class="btn-primary btn-small">Enqueue Missing</button>
				</div>

				<div class="enrichment-card compact">
					<div class="enrichment-header">
						<h3>Density</h3>
						<span class="queue-status">
							{#if enrichmentStats.density.pending_jobs > 0}
								<span class="status-dot active"></span> {formatNumber(enrichmentStats.density.pending_jobs)} pending
							{:else}
								<span class="status-dot idle"></span> Idle
							{/if}
						</span>
					</div>
					<div class="enrichment-mini-stats">
						<span>{formatNumber(enrichmentStats.density.with_density_data || 0)} complete</span>
						<span>{formatNumber(enrichmentStats.density.without_density_data || 0)} missing</span>
					</div>
					<div class="enrichment-rate-compact">
						Today: {enrichmentStats.density.completed_today}/{enrichmentStats.density.daily_limit} |
						Hour: {enrichmentStats.density.completed_this_hour}/{enrichmentStats.density.hourly_limit}
					</div>
					<button onclick={enqueueDensity} class="btn-primary btn-small">Enqueue Missing</button>
				</div>
			</div>

			<div class="advanced-section">
				<button onclick={() => showAdvanced = !showAdvanced} class="btn-link">
					{showAdvanced ? 'Hide' : 'Show'} Advanced Options
				</button>
				{#if showAdvanced}
					<div class="advanced-actions">
						<button onclick={refetchNutrition} class="btn-danger btn-small">
							Refetch All Nutrition
						</button>
						<p class="help-text">Deletes all nutrition data and refetches from scratch. Use after improving matching algorithms.</p>
					</div>
				{/if}
			</div>
		</section>
	{/if}

	<section class="filters">
		<div class="filter-row">
			<label>
				<span>Category</span>
				<select bind:value={categoryFilter} onchange={() => loadIngredients()}>
					<option value="">All Categories</option>
					{#if options?.categories}
						{#each options.categories as cat}
							<option value={cat}>{formatLabel(cat)}</option>
						{/each}
					{/if}
				</select>
			</label>

			<label>
				<span>Animal Type</span>
				<select bind:value={animalTypeFilter} onchange={() => loadIngredients()}>
					<option value="">All Types</option>
					{#if options?.animal_types}
						{#each options.animal_types as type}
							<option value={type}>{formatLabel(type)}</option>
						{/each}
					{/if}
				</select>
			</label>

			<label class="checkbox-label">
				<input
					type="checkbox"
					bind:checked={showMissingOnly}
					onchange={() => loadIngredients()}
				/>
				<span>Show only missing animal_type</span>
			</label>

			<label>
				<span>Search</span>
				<input
					type="text"
					bind:value={searchQuery}
					oninput={handleSearchInput}
					placeholder="Search by name..."
				/>
			</label>
		</div>
	</section>

	{#if error}
		<p class="error">{error}</p>
	{/if}

	{#if loading}
		<p class="loading">Loading ingredients...</p>
	{:else if ingredients.length === 0}
		<p class="empty">No ingredients found matching the filters.</p>
	{:else}
		<p class="count">Showing {ingredients.length} ingredients</p>
		<table class="ingredients-table">
			<thead>
				<tr>
					<th>Name</th>
					<th>Category</th>
					<th>Subcategory</th>
					<th>Similarity Name</th>
					<th>Animal Type</th>
					<th>Rules</th>
					<th>Usage</th>
					<th>Actions</th>
				</tr>
			</thead>
			<tbody>
				{#each ingredients as ingredient}
					<tr>
						<td class="name-cell">
							<span class="display-name">{ingredient.display_name}</span>
							{#if ingredient.name !== ingredient.display_name.toLowerCase()}
								<span class="canonical-name">({ingredient.name})</span>
							{/if}
						</td>
						<td>{ingredient.category ? formatLabel(ingredient.category) : '-'}</td>
						<td>{ingredient.subcategory ? formatLabel(ingredient.subcategory) : '-'}</td>
						<td class="similarity-cell">
							{#if editingSimilarityId === ingredient.id}
								<div class="inline-edit">
									<input
										type="text"
										bind:value={editingSimilarityValue}
										disabled={savingSimilarity}
										placeholder="e.g., flour"
										onkeydown={(e) => {
											if (e.key === 'Enter') saveEditSimilarity(ingredient);
											if (e.key === 'Escape') cancelEditSimilarity();
										}}
									/>
									<button onclick={() => saveEditSimilarity(ingredient)} disabled={savingSimilarity} class="save-btn">
										{savingSimilarity ? '...' : 'Save'}
									</button>
									<button onclick={cancelEditSimilarity} disabled={savingSimilarity} class="cancel-btn">Cancel</button>
								</div>
							{:else}
								<span
									class="editable"
									class:has-value={!!ingredient.similarity_name}
									onclick={() => startEditSimilarity(ingredient)}
									onkeydown={(e) => e.key === 'Enter' && startEditSimilarity(ingredient)}
									role="button"
									tabindex="0"
								>
									{ingredient.similarity_name || '-'}
								</span>
							{/if}
						</td>
						<td class="animal-type-cell">
							{#if editingId === ingredient.id}
								<select bind:value={editingValue} disabled={saving}>
									<option value="">None</option>
									{#if options?.animal_types}
										{#each options.animal_types as type}
											<option value={type}>{formatLabel(type)}</option>
										{/each}
									{/if}
								</select>
							{:else if ingredient.animal_type}
								<span class="animal-badge">{formatLabel(ingredient.animal_type)}</span>
							{:else}
								<span class="missing">Not set</span>
							{/if}
						</td>
						<td class="rules-cell">
							<button onclick={() => openRulesModal(ingredient)} class="rules-btn" class:has-rules={ingredient.matching_rules}>
								{ingredient.matching_rules ? 'Edit' : 'Add'}
							</button>
						</td>
						<td class="usage-cell">{ingredient.usage_count}</td>
						<td class="actions-cell">
							{#if editingId === ingredient.id}
								<button onclick={() => saveEdit(ingredient)} disabled={saving} class="save-btn">
									{saving ? '...' : 'Save'}
								</button>
								<button onclick={cancelEdit} disabled={saving} class="cancel-btn">Cancel</button>
							{:else}
								<button onclick={() => startEdit(ingredient)} class="edit-btn">Edit</button>

								{#if !ingredient.animal_type}
									<div class="quick-set">
										{#each ['chicken', 'beef', 'pork', 'egg', 'salmon', 'shrimp'] as type}
											<button
												onclick={() => quickSetAnimalType(ingredient, type)}
												class="quick-btn"
												title="Set to {type}"
											>
												{type.slice(0, 3)}
											</button>
										{/each}
									</div>
								{/if}
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	{/if}
	{/if}
</div>

<!-- Matching Rules Modal -->
{#if rulesModalIngredient}
	<div class="modal-backdrop" onclick={closeRulesModal} onkeydown={(e) => e.key === 'Escape' && closeRulesModal()} role="dialog" aria-modal="true" tabindex="-1">
		<div class="modal" onclick={(e) => e.stopPropagation()} onkeydown={(e) => e.key === 'Escape' && closeRulesModal()} role="document" tabindex="-1">
			<div class="modal-header">
				<h2>Matching Rules: {rulesModalIngredient.display_name}</h2>
				<button class="modal-close" onclick={closeRulesModal}>&times;</button>
			</div>
			<div class="modal-body">
				<p class="modal-help">
					Define scoring rules for this ingredient. The scorer uses these rules to adjust confidence when matching ingredient text.
				</p>
				<div class="rules-field-help">
					<ul>
						<li><strong>boost_words</strong>: Words that increase confidence (e.g., ["fresh", "boneless"])</li>
						<li><strong>anti_patterns</strong>: Words that decrease confidence (e.g., ["sauce", "powder"])</li>
						<li><strong>required_words</strong>: Words that must be present (e.g., ["sauce"] for tomato sauce)</li>
						<li><strong>exclude_patterns</strong>: Regex patterns that disqualify matches (e.g., ["\\btomato\\s+sauce\\b"])</li>
						<li><strong>boost_amount</strong>: Points added per boost word (default: 0.05)</li>
						<li><strong>anti_penalty</strong>: Points subtracted per anti-pattern (default: 0.15)</li>
					</ul>
				</div>
				<textarea
					bind:value={rulesEditJson}
					class="rules-editor"
					rows="15"
					spellcheck="false"
				></textarea>
				{#if rulesJsonError}
					<p class="error">{rulesJsonError}</p>
				{/if}
			</div>
			<div class="modal-footer">
				<button class="btn-secondary" onclick={closeRulesModal}>Cancel</button>
				<button class="btn-primary" onclick={saveMatchingRules} disabled={rulesSaving}>
					{rulesSaving ? 'Saving...' : 'Save Rules'}
				</button>
			</div>
		</div>
	</div>
{/if}

<style>
	.admin-page {
		max-width: 1200px;
	}

	h1 {
		margin: 0 0 var(--space-6);
		color: var(--color-marinara-800);
	}

	.access-denied {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		text-align: center;
		box-shadow: var(--shadow-sm);
	}

	.access-denied h2 {
		color: var(--color-marinara-600);
		margin: 0 0 var(--space-3);
	}

	.access-denied p {
		color: var(--text-secondary);
		margin: 0 0 var(--space-4);
	}

	.access-denied a {
		color: var(--color-basil-600);
		font-weight: var(--font-medium);
	}

	.filters {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-4);
		margin-bottom: var(--space-6);
		box-shadow: var(--shadow-sm);
	}

	.filter-row {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-4);
		align-items: flex-end;
	}

	.filter-row label {
		display: flex;
		flex-direction: column;
		gap: var(--space-1);
	}

	.filter-row label span {
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.filter-row select,
	.filter-row input[type='text'] {
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
		min-width: 150px;
	}

	.checkbox-label {
		flex-direction: row !important;
		align-items: center !important;
		gap: var(--space-2) !important;
	}

	.checkbox-label input[type='checkbox'] {
		width: 18px;
		height: 18px;
	}

	.error {
		color: var(--color-error);
		background: rgba(220, 74, 61, 0.1);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	.loading,
	.empty {
		color: var(--text-muted);
		font-style: italic;
		text-align: center;
		padding: var(--space-8);
	}

	.count {
		color: var(--text-secondary);
		font-size: var(--text-sm);
		margin-bottom: var(--space-3);
	}

	.ingredients-table {
		width: 100%;
		border-collapse: collapse;
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		overflow: hidden;
		box-shadow: var(--shadow-sm);
	}

	.ingredients-table th {
		background: var(--color-pasta-100);
		padding: var(--space-3) var(--space-4);
		text-align: left;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	.ingredients-table td {
		padding: var(--space-3) var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
		font-size: var(--text-sm);
	}

	.ingredients-table tbody tr:hover {
		background: var(--color-pasta-50);
	}

	.name-cell {
		min-width: 200px;
	}

	.display-name {
		font-weight: var(--font-medium);
	}

	.canonical-name {
		color: var(--text-muted);
		font-size: var(--text-xs);
		display: block;
	}

	.similarity-cell .inline-edit {
		display: flex;
		align-items: center;
		gap: var(--space-1);
	}

	.similarity-cell .inline-edit input {
		padding: var(--space-1) var(--space-2);
		font-size: var(--text-sm);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-sm);
		min-width: 100px;
	}

	.editable {
		cursor: pointer;
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		transition: background var(--transition-fast);
	}

	.editable:hover {
		background: var(--color-pasta-100);
	}

	.editable:not(.has-value) {
		color: var(--text-muted);
		font-style: italic;
	}

	.animal-type-cell select {
		padding: var(--space-1) var(--space-2);
		font-size: var(--text-sm);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-sm);
	}

	.animal-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.missing {
		color: var(--text-muted);
		font-style: italic;
	}

	.usage-cell {
		text-align: right;
		color: var(--text-muted);
	}

	.actions-cell {
		white-space: nowrap;
	}

	.edit-btn,
	.save-btn,
	.cancel-btn {
		padding: var(--space-1) var(--space-2);
		border: none;
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		cursor: pointer;
		margin-right: var(--space-1);
	}

	.edit-btn {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.edit-btn:hover {
		background: var(--color-pasta-200);
	}

	.save-btn {
		background: var(--color-basil-500);
		color: white;
	}

	.save-btn:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.cancel-btn {
		background: var(--color-gray-200);
		color: var(--color-gray-700);
	}

	.cancel-btn:hover:not(:disabled) {
		background: var(--color-gray-300);
	}

	.quick-set {
		display: inline-flex;
		gap: 2px;
		margin-left: var(--space-2);
	}

	.quick-btn {
		padding: 2px 4px;
		border: var(--border-width-thin) solid var(--border-default);
		background: var(--bg-surface);
		border-radius: var(--radius-sm);
		font-size: 10px;
		cursor: pointer;
		text-transform: capitalize;
	}

	.quick-btn:hover {
		background: var(--color-pasta-100);
		border-color: var(--color-pasta-300);
	}

	/* Message */
	.message {
		color: var(--color-basil-700);
		background: var(--color-basil-100);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
	}

	/* Section styling */
	h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-lg);
		color: var(--color-marinara-700);
	}

	h3 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-base);
		color: var(--text-secondary);
	}

	/* Parsing Section */
	.parsing-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.parsing-overview {
		display: flex;
		flex-direction: column;
		gap: var(--space-4);
	}

	.parsing-progress {
		margin-bottom: var(--space-2);
	}

	.parsing-counts {
		display: flex;
		gap: var(--space-3);
	}

	.parsing-stat {
		flex: 1;
		text-align: center;
		padding: var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.parsing-stat-value {
		display: block;
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--color-marinara-600);
	}

	.parsing-stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.parsing-actions {
		display: flex;
		gap: var(--space-3);
	}

	.parsing-jobs {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.parsing-jobs h3 {
		margin: 0 0 var(--space-3);
	}

	.jobs-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.job-item {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-2) var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
	}

	.job-id {
		font-weight: var(--font-medium);
		color: var(--text-muted);
		min-width: 60px;
	}

	.job-state {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		background: var(--color-gray-200);
		color: var(--text-secondary);
	}

	.job-state.executing {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.job-state.available {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.job-state.scheduled {
		background: var(--color-gray-200);
		color: var(--text-secondary);
	}

	.job-offset {
		color: var(--text-secondary);
	}

	.job-force {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.job-time {
		margin-left: auto;
		color: var(--text-muted);
		font-size: var(--text-xs);
	}

	.parsing-last {
		margin-top: var(--space-3);
		font-size: var(--text-sm);
		color: var(--text-muted);
	}

	/* Progress bar */
	.progress-bar {
		height: 8px;
		background: var(--border-light);
		border-radius: var(--radius-full);
		overflow: hidden;
		margin-bottom: var(--space-1);
	}

	.progress-fill {
		height: 100%;
		background: var(--color-basil-500);
		border-radius: var(--radius-full);
		transition: width var(--transition-normal);
	}

	.progress-text {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	/* Quality Section */
	.quality-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.quality-section h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-lg);
		color: var(--color-marinara-800);
	}

	.quality-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-4);
	}

	.quality-card {
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: var(--space-4);
	}

	.quality-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-3);
	}

	.quality-header h3 {
		margin: 0;
		font-size: var(--text-base);
		color: var(--text-primary);
	}

	.quality-percent {
		font-size: var(--text-xl);
		font-weight: var(--font-bold);
		color: var(--color-basil-600);
	}

	.quality-badge {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.quality-badge.success {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.quality-badge.warning {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.quality-stats {
		display: flex;
		gap: var(--space-3);
		margin-bottom: var(--space-3);
	}

	.quality-stat {
		flex: 1;
		text-align: center;
		padding: var(--space-2);
		background: var(--bg-card);
		border-radius: var(--radius-sm);
	}

	.quality-stat .stat-value {
		display: block;
		font-size: var(--text-lg);
		font-weight: var(--font-bold);
		color: var(--color-marinara-600);
	}

	.quality-stat .stat-label {
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.quality-progress {
		margin-bottom: var(--space-2);
	}

	.source-breakdown {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
		margin-bottom: var(--space-3);
	}

	.source-badge {
		display: inline-block;
		padding: var(--space-1) var(--space-2);
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-medium);
	}

	.issue-summary {
		font-size: var(--text-sm);
		color: var(--text-secondary);
		margin-bottom: var(--space-3);
	}

	.issue-summary p {
		margin: var(--space-1) 0;
	}

	.quality-issues-detail {
		margin-top: var(--space-4);
		padding: var(--space-4);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.issue-list {
		margin-bottom: var(--space-4);
	}

	.issue-list h4 {
		margin: 0 0 var(--space-2);
		font-size: var(--text-sm);
		color: var(--text-primary);
	}

	.issue-items {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
	}

	.issue-item {
		padding: var(--space-1) var(--space-2);
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
	}

	.issue-item.actionable {
		display: inline-flex;
		align-items: center;
		gap: var(--space-2);
	}

	.issue-action {
		padding: 2px 6px;
		font-size: 10px;
		background: var(--color-basil-500);
		color: white;
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
	}

	.issue-action:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.issue-action:disabled {
		background: var(--color-gray-400);
		cursor: default;
	}

	.btn-tiny {
		padding: 2px 8px;
		font-size: 11px;
		background: var(--color-basil-500);
		color: white;
		border: none;
		border-radius: var(--radius-sm);
		cursor: pointer;
	}

	.btn-tiny:hover:not(:disabled) {
		background: var(--color-basil-600);
	}

	.btn-tiny:disabled {
		background: var(--color-gray-400);
		cursor: default;
	}

	.btn-tiny.btn-muted {
		background: var(--color-gray-500);
	}

	.btn-tiny.btn-muted:hover:not(:disabled) {
		background: var(--color-gray-600);
	}

	.action-cell {
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
	}

	.issue-help {
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin: 0 0 var(--space-2);
	}

	.mini-table {
		width: 100%;
		border-collapse: collapse;
		font-size: var(--text-xs);
	}

	.mini-table th,
	.mini-table td {
		padding: var(--space-2);
		text-align: left;
		border-bottom: 1px solid var(--border-light);
	}

	.mini-table th {
		background: var(--bg-card);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
	}

	/* Enrichment Section */
	.enrichment-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.enrichment-section h2 {
		margin: 0 0 var(--space-4);
		font-size: var(--text-lg);
		color: var(--color-marinara-800);
	}

	.enrichment-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: var(--space-4);
	}

	.enrichment-card {
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: var(--space-4);
	}

	.enrichment-card.compact {
		padding: var(--space-3);
	}

	.enrichment-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: var(--space-2);
	}

	.enrichment-header h3 {
		margin: 0;
		font-size: var(--text-base);
		color: var(--text-primary);
	}

	.queue-status {
		display: flex;
		align-items: center;
		gap: var(--space-1);
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.status-dot {
		width: 8px;
		height: 8px;
		border-radius: 50%;
	}

	.status-dot.active {
		background: var(--color-basil-500);
		animation: pulse 1.5s infinite;
	}

	.status-dot.idle {
		background: var(--color-gray-400);
	}

	@keyframes pulse {
		0%, 100% { opacity: 1; }
		50% { opacity: 0.5; }
	}

	.enrichment-mini-stats {
		display: flex;
		justify-content: space-between;
		font-size: var(--text-sm);
		color: var(--text-secondary);
		margin-bottom: var(--space-2);
	}

	.enrichment-rate-compact {
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin-bottom: var(--space-3);
	}

	.advanced-section {
		margin-top: var(--space-4);
		padding-top: var(--space-4);
		border-top: 1px solid var(--border-light);
	}

	.advanced-actions {
		margin-top: var(--space-3);
		padding: var(--space-3);
		background: var(--bg-surface);
		border-radius: var(--radius-md);
	}

	.help-text {
		margin: var(--space-2) 0 0;
		font-size: var(--text-xs);
		color: var(--text-muted);
	}

	/* Button styles */
	.btn-primary {
		background: var(--color-basil-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-primary:hover {
		background: var(--color-basil-600);
	}

	.btn-secondary {
		background: var(--color-gray-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-secondary:hover {
		background: var(--color-gray-600);
	}

	.btn-danger {
		background: var(--color-marinara-500);
		color: white;
		border: none;
		padding: var(--space-2) var(--space-4);
		border-radius: var(--radius-md);
		cursor: pointer;
		font-weight: var(--font-medium);
	}

	.btn-danger:hover {
		background: var(--color-marinara-600);
	}

	.btn-small {
		padding: var(--space-1) var(--space-3);
		font-size: var(--text-sm);
	}

	.btn-link {
		background: none;
		border: none;
		color: var(--color-basil-600);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: 0;
	}

	.btn-link:hover {
		text-decoration: underline;
	}

	/* Test Scorer Section */
	.scorer-section {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-5);
		margin-bottom: var(--space-5);
		box-shadow: var(--shadow-sm);
	}

	.scorer-form {
		display: flex;
		gap: var(--space-3);
		margin-bottom: var(--space-4);
	}

	.scorer-form input {
		flex: 1;
		padding: var(--space-2) var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		font-size: var(--text-sm);
	}

	.scorer-form input:focus {
		outline: none;
		border-color: var(--color-basil-500);
		box-shadow: 0 0 0 2px var(--color-basil-100);
	}

	.scorer-results {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-4);
	}

	.scorer-match,
	.scorer-alternatives {
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: var(--space-4);
	}

	.match-card {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-3);
		padding: var(--space-3);
		background: var(--bg-card);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-2);
	}

	.match-name {
		font-weight: var(--font-medium);
		color: var(--text-primary);
	}

	.match-score,
	.alt-score {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-sm);
		font-weight: var(--font-bold);
	}

	.match-score.high,
	.alt-score.high {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.match-score.medium,
	.alt-score.medium {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
	}

	.match-score.low,
	.alt-score.low {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.scoring-details {
		display: flex;
		gap: var(--space-2);
		flex-wrap: wrap;
	}

	.detail {
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
	}

	.detail.boost {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	.detail.anti {
		background: var(--color-marinara-100);
		color: var(--color-marinara-700);
	}

	.detail.base {
		background: var(--color-gray-200);
		color: var(--text-secondary);
	}

	.no-match {
		color: var(--text-muted);
		font-style: italic;
	}

	.scorer-alternatives ul {
		list-style: none;
		padding: 0;
		margin: 0;
	}

	.alt-item {
		display: flex;
		align-items: center;
		gap: var(--space-2);
		padding: var(--space-2);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.alt-item:last-child {
		border-bottom: none;
	}

	.alt-name {
		flex: 1;
		font-size: var(--text-sm);
	}

	.has-rules {
		padding: var(--space-1);
		border-radius: var(--radius-sm);
		font-size: var(--text-xs);
		font-weight: var(--font-bold);
		background: var(--color-basil-100);
		color: var(--color-basil-700);
	}

	/* Rules Cell */
	.rules-cell {
		text-align: center;
	}

	.rules-btn {
		padding: var(--space-1) var(--space-2);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-sm);
		background: var(--bg-surface);
		font-size: var(--text-xs);
		cursor: pointer;
	}

	.rules-btn:hover {
		background: var(--color-pasta-100);
		border-color: var(--color-pasta-300);
	}

	.rules-btn.has-rules {
		background: var(--color-basil-100);
		border-color: var(--color-basil-300);
		color: var(--color-basil-700);
	}

	/* Modal */
	.modal-backdrop {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.5);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
	}

	.modal {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		width: 90%;
		max-width: 600px;
		max-height: 90vh;
		overflow: hidden;
		display: flex;
		flex-direction: column;
		box-shadow: var(--shadow-lg);
	}

	.modal-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: var(--space-4);
		border-bottom: var(--border-width-thin) solid var(--border-light);
	}

	.modal-header h2 {
		margin: 0;
		font-size: var(--text-lg);
	}

	.modal-close {
		background: none;
		border: none;
		font-size: var(--text-2xl);
		cursor: pointer;
		color: var(--text-muted);
		line-height: 1;
		padding: 0;
	}

	.modal-close:hover {
		color: var(--text-primary);
	}

	.modal-body {
		padding: var(--space-4);
		overflow-y: auto;
		flex: 1;
	}

	.modal-help {
		margin: 0 0 var(--space-3);
		font-size: var(--text-sm);
		color: var(--text-secondary);
	}

	.rules-field-help {
		background: var(--bg-surface);
		border-radius: var(--radius-md);
		padding: var(--space-3);
		margin-bottom: var(--space-4);
	}

	.rules-field-help ul {
		margin: 0;
		padding-left: var(--space-4);
		font-size: var(--text-xs);
		color: var(--text-secondary);
	}

	.rules-field-help li {
		margin-bottom: var(--space-1);
	}

	.rules-field-help strong {
		color: var(--text-primary);
	}

	.rules-editor {
		width: 100%;
		font-family: monospace;
		font-size: var(--text-sm);
		padding: var(--space-3);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		resize: vertical;
	}

	.rules-editor:focus {
		outline: none;
		border-color: var(--color-basil-500);
		box-shadow: 0 0 0 2px var(--color-basil-100);
	}

	.modal-footer {
		display: flex;
		justify-content: flex-end;
		gap: var(--space-3);
		padding: var(--space-4);
		border-top: var(--border-width-thin) solid var(--border-light);
	}

	.modal-footer button {
		min-width: 100px;
	}

	.btn-primary:disabled,
	.btn-secondary:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}
</style>
