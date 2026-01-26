<script lang="ts">
  import type { Snippet } from 'svelte';

  interface Props {
    open: boolean;
    title: string;
    onclose?: () => void;
    children: Snippet;
    footer?: Snippet;
  }

  let { open = $bindable(), title, onclose, children, footer }: Props = $props();

  function handleClose() {
    open = false;
    onclose?.();
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape') {
      handleClose();
    }
  }

  function handleBackdropClick() {
    handleClose();
  }

  function stopPropagation(e: Event) {
    e.stopPropagation();
  }
</script>

{#if open}
  <!-- svelte-ignore a11y_no_static_element_interactions -->
  <div
    class="modal-overlay"
    onclick={handleBackdropClick}
    onkeydown={handleKeydown}
    role="dialog"
    aria-modal="true"
    aria-labelledby="modal-title"
    tabindex="-1"
  >
    <!-- svelte-ignore a11y_no_noninteractive_element_interactions -->
    <div
      class="modal"
      role="document"
      onclick={stopPropagation}
      onkeydown={stopPropagation}
    >
      <div class="modal-header">
        <h3 id="modal-title" class="modal-title">{title}</h3>
        <button class="modal-close" onclick={handleClose} aria-label="Close modal">
          &times;
        </button>
      </div>

      <div class="modal-body">
        {@render children()}
      </div>

      {#if footer}
        <div class="modal-footer">
          {@render footer()}
        </div>
      {/if}
    </div>
  </div>
{/if}

<style>
  .modal-overlay {
    position: fixed;
    inset: 0;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1000;
    padding: var(--space-4, 1rem);
  }

  .modal {
    background: var(--bg-card, white);
    border-radius: var(--radius-lg, 0.75rem);
    box-shadow: var(--shadow-xl, 0 20px 25px -5px rgba(0, 0, 0, 0.1));
    max-width: 500px;
    width: 100%;
    max-height: 90vh;
    display: flex;
    flex-direction: column;
    overflow: hidden;
  }

  .modal-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: var(--space-4, 1rem) var(--space-6, 1.5rem);
    border-bottom: var(--border-width-thin, 1px) solid var(--border-light, #e5e7eb);
  }

  .modal-title {
    margin: 0;
    font-size: var(--text-lg, 1.125rem);
    font-weight: var(--font-semibold, 600);
    color: var(--text-primary, #1f2937);
  }

  .modal-close {
    background: none;
    border: none;
    font-size: var(--text-2xl, 1.5rem);
    cursor: pointer;
    color: var(--text-secondary, #6b7280);
    padding: var(--space-1, 0.25rem);
    line-height: 1;
    border-radius: var(--radius-md, 0.375rem);
    transition: all var(--transition-fast, 150ms);
  }

  .modal-close:hover {
    background: var(--bg-surface, #f3f4f6);
    color: var(--text-primary, #1f2937);
  }

  .modal-body {
    padding: var(--space-6, 1.5rem);
    overflow-y: auto;
    flex: 1;
  }

  .modal-footer {
    display: flex;
    justify-content: flex-end;
    gap: var(--space-3, 0.75rem);
    padding: var(--space-4, 1rem) var(--space-6, 1.5rem);
    border-top: var(--border-width-thin, 1px) solid var(--border-light, #e5e7eb);
    background: var(--bg-surface, #f9fafb);
  }

  @media (max-width: 640px) {
    .modal {
      max-width: 100%;
      margin: var(--space-4, 1rem);
    }
  }
</style>
