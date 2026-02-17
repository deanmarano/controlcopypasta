<script lang="ts">
	import type { Ingredient } from '$lib/api/client';

	interface Props {
		ingredients: Ingredient[];
	}

	let { ingredients }: Props = $props();
	let expandedIndex = $state<number | null>(null);

	function toggleExpand(index: number) {
		expandedIndex = expandedIndex === index ? null : index;
	}

	function getConfidenceColor(confidence: number | undefined): string {
		if (confidence === undefined) return 'var(--color-gray-400)';
		if (confidence >= 0.95) return '#5a7264';
		if (confidence >= 0.8) return '#d97706';
		return '#c53030';
	}

	function formatParseTime(us: number): string {
		if (us >= 1000) {
			return `${(us / 1000).toFixed(1)}ms`;
		}
		return `${us}us`;
	}

	const ingredientsWithDiagnostics = $derived(ingredients.filter((i) => i._diagnostics));
</script>

{#if ingredientsWithDiagnostics.length > 0}
	<details class="diagnostics-panel">
		<summary>
			Parse Diagnostics
			<span class="count">({ingredients.length} ingredients)</span>
		</summary>

		<div class="diagnostics-content">
			<table class="diagnostics-table">
				<thead>
					<tr>
						<th class="col-original">Original Text</th>
						<th class="col-matched">Matched</th>
						<th class="col-confidence">Confidence</th>
						<th class="col-parser">Parser</th>
						<th class="col-expand"></th>
					</tr>
				</thead>
				<tbody>
					{#each ingredients as ing, i}
						<tr
							class:low-confidence={(ing.confidence ?? 1) < 0.8}
							class:no-match={!ing.canonical_name}
						>
							<td class="original-text" title={ing.text}>
								{ing.text}
							</td>
							<td class="matched-name">
								{#if ing.canonical_name}
									{ing.canonical_name}
								{:else}
									<span class="unmatched">No match</span>
								{/if}
							</td>
							<td class="confidence">
								{#if ing.confidence !== undefined}
									<span
										class="confidence-bar"
										style="--width: {ing.confidence * 100}%; --color: {getConfidenceColor(ing.confidence)}"
									>
										{Math.round(ing.confidence * 100)}%
									</span>
								{:else}
									<span class="no-confidence">-</span>
								{/if}
							</td>
							<td class="parser-used">
								{ing._diagnostics?.parser || 'standard'}
							</td>
							<td class="expand-cell">
								{#if ing._diagnostics}
									<button
										class="expand-btn"
										onclick={() => toggleExpand(i)}
										aria-label={expandedIndex === i ? 'Collapse' : 'Expand'}
									>
										{expandedIndex === i ? '-' : '+'}
									</button>
								{/if}
							</td>
						</tr>

						{#if expandedIndex === i && ing._diagnostics}
							<tr class="diagnostics-detail">
								<td colspan="5">
									<div class="detail-content">
										<div class="detail-row">
											<strong>Tokens:</strong>
											<code class="token-display">{ing._diagnostics.tokens}</code>
										</div>

										{#if ing._diagnostics.match_strategy}
											<div class="detail-row">
												<strong>Match Strategy:</strong>
												<span class="strategy-badge">{ing._diagnostics.match_strategy}</span>
											</div>
										{/if}

										{#if ing._diagnostics.alternatives && ing._diagnostics.alternatives.length > 0}
											<div class="detail-row">
												<strong>Other Candidates:</strong>
												<span class="alternatives">
													{ing._diagnostics.alternatives.join(', ')}
												</span>
											</div>
										{/if}

										{#if ing._diagnostics.warnings && ing._diagnostics.warnings.length > 0}
											<div class="detail-row warnings-row">
												<strong>Warnings:</strong>
												<div class="warnings">
													{#each ing._diagnostics.warnings as warning}
														<span class="warning-badge">{warning}</span>
													{/each}
												</div>
											</div>
										{/if}

										<div class="detail-row parse-time">
											Parsed in {formatParseTime(ing._diagnostics.parse_time_us)}
										</div>
									</div>
								</td>
							</tr>
						{/if}
					{/each}
				</tbody>
			</table>
		</div>
	</details>
{/if}

<style>
	.diagnostics-panel {
		margin-top: var(--space-6);
		border: 1px solid var(--border-light);
		border-radius: var(--radius-md);
		background: var(--bg-card);
	}

	.diagnostics-panel summary {
		padding: var(--space-3) var(--space-4);
		cursor: pointer;
		background: var(--bg-surface);
		font-weight: var(--font-medium);
		font-size: var(--text-sm);
		border-radius: var(--radius-md);
		user-select: none;
		display: flex;
		align-items: center;
		gap: var(--space-2);
	}

	.diagnostics-panel summary:hover {
		background: var(--bg-surface-hover, var(--bg-surface));
	}

	.diagnostics-panel[open] summary {
		border-bottom: 1px solid var(--border-light);
		border-radius: var(--radius-md) var(--radius-md) 0 0;
	}

	.count {
		font-weight: var(--font-normal);
		color: var(--text-muted);
		font-size: var(--text-xs);
	}

	.diagnostics-content {
		padding: var(--space-3);
		overflow-x: auto;
	}

	.diagnostics-table {
		width: 100%;
		border-collapse: collapse;
		font-size: var(--text-xs);
	}

	.diagnostics-table th,
	.diagnostics-table td {
		padding: var(--space-2);
		text-align: left;
		border-bottom: 1px solid var(--border-light);
	}

	.diagnostics-table th {
		background: var(--bg-surface);
		font-weight: var(--font-medium);
		color: var(--text-secondary);
		text-transform: uppercase;
		font-size: 10px;
		letter-spacing: 0.05em;
	}

	.col-original {
		width: 35%;
	}

	.col-matched {
		width: 25%;
	}

	.col-confidence {
		width: 15%;
	}

	.col-parser {
		width: 15%;
	}

	.col-expand {
		width: 40px;
	}

	.original-text {
		max-width: 250px;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		color: var(--text-secondary);
	}

	.matched-name {
		font-weight: var(--font-medium);
	}

	.unmatched {
		color: var(--color-marinara-500);
		font-style: italic;
		font-weight: var(--font-normal);
	}

	.confidence-bar {
		display: inline-block;
		background: linear-gradient(to right, var(--color) var(--width), var(--border-light) var(--width));
		padding: 2px 8px;
		border-radius: var(--radius-sm);
		font-size: 10px;
		font-weight: var(--font-medium);
	}

	.no-confidence {
		color: var(--text-muted);
	}

	.parser-used {
		color: var(--text-muted);
		font-family: var(--font-mono, monospace);
	}

	.expand-btn {
		width: 24px;
		height: 24px;
		border: 1px solid var(--border-default);
		border-radius: var(--radius-sm);
		background: var(--bg-card);
		cursor: pointer;
		font-size: var(--text-sm);
		font-weight: var(--font-bold);
		color: var(--text-secondary);
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.expand-btn:hover {
		background: var(--bg-surface);
		border-color: var(--border-default);
	}

	.low-confidence {
		background: rgba(255, 200, 0, 0.05);
	}

	.no-match {
		background: rgba(255, 100, 100, 0.05);
	}

	.diagnostics-detail td {
		background: var(--bg-surface);
		padding: 0;
	}

	.detail-content {
		padding: var(--space-3) var(--space-4);
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
	}

	.detail-row {
		display: flex;
		align-items: flex-start;
		gap: var(--space-2);
		font-size: var(--text-xs);
	}

	.detail-row strong {
		min-width: 100px;
		color: var(--text-secondary);
	}

	.token-display {
		background: var(--bg-card);
		padding: var(--space-1) var(--space-2);
		border-radius: var(--radius-sm);
		font-family: var(--font-mono, monospace);
		font-size: 11px;
		overflow-x: auto;
		max-width: 100%;
		display: block;
		white-space: nowrap;
	}

	.strategy-badge {
		background: var(--color-basil-100);
		color: var(--color-basil-700);
		padding: 2px 8px;
		border-radius: var(--radius-sm);
		font-size: 10px;
		text-transform: uppercase;
	}

	.alternatives {
		color: var(--text-muted);
	}

	.warnings-row {
		align-items: flex-start;
	}

	.warnings {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-1);
	}

	.warning-badge {
		background: var(--color-pasta-100);
		color: var(--color-pasta-700);
		padding: 2px 8px;
		border-radius: var(--radius-sm);
		font-size: 10px;
	}

	.parse-time {
		color: var(--text-muted);
		font-size: 10px;
		margin-top: var(--space-1);
		justify-content: flex-end;
	}

	/* Print styles */
	@media print {
		.diagnostics-panel {
			display: none;
		}
	}
</style>
