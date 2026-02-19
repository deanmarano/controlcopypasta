<script lang="ts">
	import { goto } from '$app/navigation';
	import { authStore, isAuthenticated } from '$lib/stores/auth';
	import { avoidedIngredients, settings } from '$lib/api/client';

	type Step = 'welcome' | 'presets' | 'review';

	let step = $state<Step>('welcome');
	let selectedPresets = $state<Set<string>>(new Set());
	let hideAvoided = $state(true);
	let saving = $state(false);
	let error = $state('');
	let disabledAvoidances = $state<Set<string>>(new Set());

	// Preset definitions mapping to avoidance records
	const presets: Record<string, { label: string; icon: string; description: string; avoidances: Array<{ type: string; value: string }> }> = {
		vegetarian: {
			label: 'Vegetarian',
			icon: '\u{1F966}',
			description: 'No meat or seafood',
			avoidances: [
				{ type: 'animal', value: 'chicken' },
				{ type: 'animal', value: 'beef' },
				{ type: 'animal', value: 'pork' },
				{ type: 'animal', value: 'lamb' },
				{ type: 'animal', value: 'turkey' },
				{ type: 'animal', value: 'duck' },
				{ type: 'animal', value: 'veal' },
				{ type: 'animal', value: 'venison' },
				{ type: 'animal', value: 'bison' },
				{ type: 'animal', value: 'goat' },
				{ type: 'animal', value: 'rabbit' },
				{ type: 'category', value: 'seafood' }
			]
		},
		vegan: {
			label: 'Vegan',
			icon: '\u{1F331}',
			description: 'No animal products',
			avoidances: [
				{ type: 'animal', value: 'chicken' },
				{ type: 'animal', value: 'beef' },
				{ type: 'animal', value: 'pork' },
				{ type: 'animal', value: 'lamb' },
				{ type: 'animal', value: 'turkey' },
				{ type: 'animal', value: 'duck' },
				{ type: 'animal', value: 'veal' },
				{ type: 'animal', value: 'venison' },
				{ type: 'animal', value: 'bison' },
				{ type: 'animal', value: 'goat' },
				{ type: 'animal', value: 'rabbit' },
				{ type: 'category', value: 'seafood' },
				{ type: 'allergen', value: 'dairy' },
				{ type: 'allergen', value: 'eggs' }
			]
		},
		pescatarian: {
			label: 'Pescatarian',
			icon: '\u{1F41F}',
			description: 'No land meat',
			avoidances: [
				{ type: 'animal', value: 'chicken' },
				{ type: 'animal', value: 'beef' },
				{ type: 'animal', value: 'pork' },
				{ type: 'animal', value: 'lamb' },
				{ type: 'animal', value: 'turkey' },
				{ type: 'animal', value: 'duck' },
				{ type: 'animal', value: 'veal' },
				{ type: 'animal', value: 'venison' },
				{ type: 'animal', value: 'bison' },
				{ type: 'animal', value: 'goat' },
				{ type: 'animal', value: 'rabbit' }
			]
		},
		'gluten-free': {
			label: 'Gluten-free',
			icon: '\u{1F33E}',
			description: 'No wheat or gluten',
			avoidances: [
				{ type: 'allergen', value: 'wheat' },
				{ type: 'allergen', value: 'gluten' }
			]
		},
		'dairy-free': {
			label: 'Dairy-free',
			icon: '\u{1F95B}',
			description: 'No dairy products',
			avoidances: [
				{ type: 'allergen', value: 'dairy' }
			]
		},
		'nut-free': {
			label: 'Nut-free',
			icon: '\u{1F95C}',
			description: 'No peanuts or tree nuts',
			avoidances: [
				{ type: 'allergen', value: 'peanuts' },
				{ type: 'allergen', value: 'tree_nuts' }
			]
		}
	};

	$effect(() => {
		if (!$isAuthenticated) {
			goto('/login');
		}
	});

	function togglePreset(key: string) {
		const newSet = new Set(selectedPresets);
		if (newSet.has(key)) {
			newSet.delete(key);
		} else {
			newSet.add(key);
		}
		selectedPresets = newSet;
	}

	function getAvoidanceSummary(): Array<{ type: string; value: string }> {
		// Deduplicate avoidances across all selected presets
		const seen = new Set<string>();
		const result: Array<{ type: string; value: string }> = [];

		for (const presetKey of selectedPresets) {
			const preset = presets[presetKey];
			if (!preset) continue;
			for (const a of preset.avoidances) {
				const key = `${a.type}:${a.value}`;
				if (!seen.has(key)) {
					seen.add(key);
					result.push(a);
				}
			}
		}

		return result;
	}

	function formatAvoidanceLabel(a: { type: string; value: string }): string {
		return a.value.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
	}

	function avoidanceKey(a: { type: string; value: string }): string {
		return `${a.type}:${a.value}`;
	}

	function toggleAvoidance(a: { type: string; value: string }) {
		const key = avoidanceKey(a);
		const newSet = new Set(disabledAvoidances);
		if (newSet.has(key)) {
			newSet.delete(key);
		} else {
			newSet.add(key);
		}
		disabledAvoidances = newSet;
	}

	function getEnabledAvoidances(): Array<{ type: string; value: string }> {
		return getAvoidanceSummary().filter((a) => !disabledAvoidances.has(avoidanceKey(a)));
	}

	async function finishSetup() {
		const token = authStore.getToken();
		if (!token) return;

		saving = true;
		error = '';

		try {
			const avoidances = getEnabledAvoidances();

			// Create avoidances if any
			if (avoidances.length > 0) {
				await avoidedIngredients.bulkCreate(token, avoidances);
			}

			// Set hide preference
			if (hideAvoided && avoidances.length > 0) {
				await settings.updatePreferences(token, { hide_avoided_ingredients: true });
			}

			// Mark onboarding complete
			await settings.completeOnboarding(token);

			goto('/home');
		} catch {
			error = 'Something went wrong. Please try again.';
		} finally {
			saving = false;
		}
	}

	async function skipSetup() {
		const token = authStore.getToken();
		if (!token) return;

		saving = true;
		try {
			await settings.completeOnboarding(token);
			goto('/home');
		} catch {
			error = 'Something went wrong.';
		} finally {
			saving = false;
		}
	}
</script>

<div class="setup-page">
	<div class="setup-card">
		{#if step === 'welcome'}
			<div class="step">
				<h1>Welcome to ControlCopyPasta</h1>
				<p class="subtitle">Let's set up your dietary preferences so we can show you the best recipes.</p>

				<div class="welcome-actions">
					<button class="btn-primary" onclick={() => step = 'presets'}>
						Yes, I avoid some foods
					</button>
					<button class="btn-secondary" onclick={skipSetup} disabled={saving}>
						{saving ? 'Setting up...' : 'I eat everything'}
					</button>
				</div>

				<button class="skip-link" onclick={skipSetup} disabled={saving}>
					Skip for now
				</button>
			</div>
		{:else if step === 'presets'}
			<div class="step">
				<h1>What do you avoid?</h1>
				<p class="subtitle">Select any that apply. You can always change this later in settings.</p>

				<div class="preset-grid">
					{#each Object.entries(presets) as [key, preset]}
						<button
							class="preset-card"
							class:selected={selectedPresets.has(key)}
							onclick={() => togglePreset(key)}
						>
							<span class="preset-icon">{preset.icon}</span>
							<span class="preset-label">{preset.label}</span>
							<span class="preset-desc">{preset.description}</span>
						</button>
					{/each}
				</div>

				<div class="step-actions">
					<button class="btn-primary" onclick={() => step = 'review'} disabled={selectedPresets.size === 0}>
						Continue
					</button>
					<button class="btn-text" onclick={() => step = 'welcome'}>Back</button>
				</div>

				<button class="skip-link" onclick={skipSetup} disabled={saving}>
					Skip for now
				</button>
			</div>
		{:else if step === 'review'}
			<div class="step">
				<h1>Review your preferences</h1>
				<p class="subtitle">These ingredients will be avoided when browsing recipes.</p>

				{#if error}
					<div class="error">{error}</div>
				{/if}

				<div class="avoidance-summary">
					{#each getAvoidanceSummary() as avoidance}
						<button
							class="avoidance-tag"
							class:disabled={disabledAvoidances.has(avoidanceKey(avoidance))}
							onclick={() => toggleAvoidance(avoidance)}
						>
							<span class="tag-type">{avoidance.type}</span>
							{formatAvoidanceLabel(avoidance)}
							<span class="tag-toggle">{disabledAvoidances.has(avoidanceKey(avoidance)) ? '＋' : '✕'}</span>
						</button>
					{/each}
				</div>

				{#if disabledAvoidances.size > 0}
					<p class="exceptions-note">{disabledAvoidances.size} exception{disabledAvoidances.size === 1 ? '' : 's'} — tap to re-enable</p>
				{/if}

				<label class="toggle-row">
					<input type="checkbox" bind:checked={hideAvoided} />
					<span>Hide recipes containing avoided ingredients</span>
				</label>

				<div class="step-actions">
					<button class="btn-primary" onclick={finishSetup} disabled={saving}>
						{saving ? 'Setting up...' : 'Finish Setup'}
					</button>
					<button class="btn-text" onclick={() => step = 'presets'} disabled={saving}>Back</button>
				</div>

				<button class="skip-link" onclick={skipSetup} disabled={saving}>
					Skip for now
				</button>
			</div>
		{/if}
	</div>
</div>

<style>
	.setup-page {
		display: flex;
		justify-content: center;
		align-items: center;
		min-height: 70vh;
		padding: var(--space-4);
	}

	.setup-card {
		background: var(--bg-card);
		border-radius: var(--radius-lg);
		padding: var(--space-8);
		box-shadow: var(--shadow-lg);
		width: 100%;
		max-width: 520px;
	}

	.step {
		display: flex;
		flex-direction: column;
		align-items: center;
		text-align: center;
	}

	h1 {
		font-family: var(--font-serif);
		font-size: var(--text-2xl);
		color: var(--color-marinara-800);
		margin: 0 0 var(--space-2);
	}

	.subtitle {
		color: var(--text-secondary);
		margin: 0 0 var(--space-8);
		font-size: var(--text-base);
	}

	.welcome-actions {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
		width: 100%;
		max-width: 320px;
		margin-bottom: var(--space-6);
	}

	.btn-primary {
		padding: var(--space-3) var(--space-6);
		background: var(--color-marinara-500);
		color: var(--color-white);
		border: none;
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.btn-primary:hover:not(:disabled) {
		background: var(--color-marinara-600);
		box-shadow: var(--shadow-marinara);
	}

	.btn-primary:disabled {
		background: var(--color-gray-400);
		cursor: not-allowed;
	}

	.btn-secondary {
		padding: var(--space-3) var(--space-6);
		background: var(--bg-card);
		color: var(--color-marinara-700);
		border: var(--border-width-default) solid var(--color-marinara-300);
		border-radius: var(--radius-md);
		font-size: var(--text-base);
		font-weight: var(--font-medium);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.btn-secondary:hover:not(:disabled) {
		background: var(--color-marinara-50);
	}

	.btn-secondary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.btn-text {
		background: none;
		border: none;
		color: var(--color-marinara-600);
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-medium);
		padding: var(--space-2);
	}

	.btn-text:hover:not(:disabled) {
		text-decoration: underline;
	}

	.skip-link {
		background: none;
		border: none;
		color: var(--text-muted);
		cursor: pointer;
		font-size: var(--text-sm);
		padding: var(--space-2);
		margin-top: var(--space-4);
	}

	.skip-link:hover:not(:disabled) {
		text-decoration: underline;
		color: var(--text-secondary);
	}

	/* Presets */
	.preset-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: var(--space-3);
		width: 100%;
		margin-bottom: var(--space-6);
	}

	.preset-card {
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: var(--space-4) var(--space-3);
		background: var(--bg-page);
		border: var(--border-width-default) solid var(--border-default);
		border-radius: var(--radius-md);
		cursor: pointer;
		transition: all var(--transition-fast);
		text-align: center;
	}

	.preset-card:hover {
		border-color: var(--color-marinara-400);
		background: var(--color-marinara-50);
	}

	.preset-card.selected {
		border-color: var(--color-marinara-500);
		background: var(--color-marinara-50);
		box-shadow: 0 0 0 2px var(--color-marinara-200);
	}

	.preset-icon {
		font-size: var(--text-3xl);
		line-height: 1;
		margin-bottom: var(--space-2);
	}

	.preset-label {
		font-weight: var(--font-semibold);
		font-size: var(--text-base);
		color: var(--text-primary);
		margin-bottom: var(--space-1);
	}

	.preset-desc {
		font-size: var(--text-xs);
		color: var(--text-muted);
	}

	/* Review */
	.avoidance-summary {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-2);
		justify-content: center;
		margin-bottom: var(--space-6);
		width: 100%;
	}

	.avoidance-tag {
		display: inline-flex;
		align-items: center;
		gap: var(--space-1);
		padding: var(--space-1) var(--space-3);
		background: var(--color-marinara-100);
		border: var(--border-width-default) solid var(--color-marinara-200);
		border-radius: var(--radius-full);
		font-size: var(--text-sm);
		color: var(--color-marinara-800);
		cursor: pointer;
		transition: all var(--transition-fast);
	}

	.avoidance-tag:hover {
		border-color: var(--color-marinara-400);
	}

	.avoidance-tag.disabled {
		background: var(--color-gray-100);
		color: var(--text-muted);
		border-color: var(--border-light);
		text-decoration: line-through;
	}

	.avoidance-tag.disabled .tag-type {
		color: var(--text-muted);
	}

	.tag-type {
		font-size: var(--text-xs);
		color: var(--color-marinara-500);
		text-transform: uppercase;
		font-weight: var(--font-medium);
	}

	.tag-toggle {
		font-size: var(--text-xs);
		margin-left: var(--space-1);
		opacity: 0.6;
	}

	.exceptions-note {
		font-size: var(--text-xs);
		color: var(--text-muted);
		margin: 0 0 var(--space-4);
	}

	.toggle-row {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		margin-bottom: var(--space-6);
		cursor: pointer;
		font-size: var(--text-sm);
		color: var(--text-primary);
	}

	.toggle-row input[type='checkbox'] {
		width: 18px;
		height: 18px;
		accent-color: var(--color-marinara-500);
	}

	.step-actions {
		display: flex;
		flex-direction: column;
		gap: var(--space-3);
		width: 100%;
		max-width: 320px;
	}

	.error {
		background: var(--color-error-bg);
		color: var(--color-error);
		padding: var(--space-3);
		border-radius: var(--radius-md);
		margin-bottom: var(--space-4);
		border-left: var(--border-width-thick) solid var(--color-error);
		width: 100%;
		text-align: left;
	}

	@media (max-width: 400px) {
		.preset-grid {
			grid-template-columns: 1fr;
		}

		.setup-card {
			padding: var(--space-6);
		}
	}
</style>
