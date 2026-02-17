<script>
  import Modal from '$lib/components/Modal.svelte';

  let inputValue = $state('');
  let textareaValue = $state('');
  let showModal = $state(false);
</script>

<svelte:head>
  <title>Styleguide | ControlCopyPasta</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous">
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,600;0,700;1,400&family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</svelte:head>

<div class="styleguide">
  <header class="styleguide-header">
    <h1>ControlCopyPasta</h1>
    <p>Design System & Styleguide</p>
  </header>

  <!-- Color Palette Section -->
  <section class="section">
    <h2>Color Palette</h2>
    <p class="section-description">An editorial botanical palette of forest green, terracotta, and sage.</p>

    <h3>Pasta (Linen / Terracotta)</h3>
    <p class="color-description">Warm linen and terracotta tones for backgrounds, accents, and highlights.</p>
    <div class="color-grid">
      <div class="color-swatch pasta-50"><span>50</span></div>
      <div class="color-swatch pasta-100"><span>100</span></div>
      <div class="color-swatch pasta-200"><span>200</span></div>
      <div class="color-swatch pasta-300"><span>300</span></div>
      <div class="color-swatch pasta-400"><span>400</span></div>
      <div class="color-swatch pasta-500"><span>500</span></div>
      <div class="color-swatch pasta-600"><span>600</span></div>
      <div class="color-swatch pasta-700"><span>700</span></div>
      <div class="color-swatch pasta-800"><span>800</span></div>
      <div class="color-swatch pasta-900"><span>900</span></div>
    </div>

    <h3>Marinara (Forest Green)</h3>
    <p class="color-description">Deep forest greens for primary actions and important accents.</p>
    <div class="color-grid">
      <div class="color-swatch marinara-50"><span>50</span></div>
      <div class="color-swatch marinara-100"><span>100</span></div>
      <div class="color-swatch marinara-200"><span>200</span></div>
      <div class="color-swatch marinara-300"><span>300</span></div>
      <div class="color-swatch marinara-400"><span>400</span></div>
      <div class="color-swatch marinara-500"><span>500</span></div>
      <div class="color-swatch marinara-600"><span>600</span></div>
      <div class="color-swatch marinara-700"><span>700</span></div>
      <div class="color-swatch marinara-800"><span>800</span></div>
      <div class="color-swatch marinara-900"><span>900</span></div>
    </div>

    <h3>Basil (Sage)</h3>
    <p class="color-description">Muted sage greens for success states and secondary elements.</p>
    <div class="color-grid">
      <div class="color-swatch basil-50"><span>50</span></div>
      <div class="color-swatch basil-100"><span>100</span></div>
      <div class="color-swatch basil-200"><span>200</span></div>
      <div class="color-swatch basil-300"><span>300</span></div>
      <div class="color-swatch basil-400"><span>400</span></div>
      <div class="color-swatch basil-500"><span>500</span></div>
      <div class="color-swatch basil-600"><span>600</span></div>
      <div class="color-swatch basil-700"><span>700</span></div>
      <div class="color-swatch basil-800"><span>800</span></div>
      <div class="color-swatch basil-900"><span>900</span></div>
    </div>
  </section>

  <!-- Typography Section -->
  <section class="section">
    <h2>Typography</h2>
    <p class="section-description">A combination of Cormorant Garamond for headings and Inter for body text creates an editorial, botanical feel.</p>

    <div class="typography-samples">
      <div class="type-sample">
        <span class="type-label">Heading 1</span>
        <h1 class="heading-1">Fresh Homemade Pasta</h1>
      </div>
      <div class="type-sample">
        <span class="type-label">Heading 2</span>
        <h2 class="heading-2">Grandma's Secret Recipe</h2>
      </div>
      <div class="type-sample">
        <span class="type-label">Heading 3</span>
        <h3 class="heading-3">Ingredients You'll Need</h3>
      </div>
      <div class="type-sample">
        <span class="type-label">Heading 4</span>
        <h4 class="heading-4">Preparation Tips</h4>
      </div>
      <div class="type-sample">
        <span class="type-label">Body Large</span>
        <p class="body-large">Cook pasta in well-salted boiling water until al dente. The starchy pasta water is liquid gold for your sauce.</p>
      </div>
      <div class="type-sample">
        <span class="type-label">Body Default</span>
        <p class="body-default">This classic marinara sauce comes together in just 30 minutes. Use San Marzano tomatoes for the best flavor.</p>
      </div>
      <div class="type-sample">
        <span class="type-label">Body Small</span>
        <p class="body-small">Recipe adapted from traditional Italian cooking methods passed down through generations.</p>
      </div>
      <div class="type-sample">
        <span class="type-label">Caption</span>
        <span class="caption">Prep Time: 15 min</span>
      </div>
    </div>
  </section>

  <!-- Buttons Section -->
  <section class="section">
    <h2>Buttons</h2>
    <p class="section-description">Action buttons with the marinara and basil color scheme.</p>

    <h3>Button Variants</h3>
    <div class="button-row">
      <button class="btn btn-primary">Save Recipe</button>
      <button class="btn btn-secondary">Add to List</button>
      <button class="btn btn-outline">View Details</button>
      <button class="btn btn-ghost">Cancel</button>
      <button class="btn btn-danger">Delete</button>
    </div>

    <h3>Button Sizes</h3>
    <div class="button-row">
      <button class="btn btn-primary btn-sm">Small</button>
      <button class="btn btn-primary">Default</button>
      <button class="btn btn-primary btn-lg">Large</button>
    </div>

    <h3>Button States</h3>
    <div class="button-row">
      <button class="btn btn-primary">Normal</button>
      <button class="btn btn-primary" disabled>Disabled</button>
    </div>
  </section>

  <!-- Cards Section -->
  <section class="section">
    <h2>Cards</h2>
    <p class="section-description">Recipe cards with warm, inviting surfaces.</p>

    <div class="cards-grid">
      <div class="card card-recipe">
        <div class="card-image-placeholder">
          <span>Recipe Image</span>
        </div>
        <span class="card-recipe-time">30 min</span>
        <div class="card-body">
          <h3 class="card-title">Classic Spaghetti Marinara</h3>
          <p class="card-text">A simple yet delicious pasta dish with homemade tomato sauce, fresh basil, and aged parmesan.</p>
          <div class="card-tags">
            <span class="tag tag-basil">Italian</span>
            <span class="tag tag-marinara">Quick</span>
            <span class="tag tag-pasta">Vegetarian</span>
          </div>
        </div>
        <div class="card-footer">
          <button class="btn btn-primary btn-sm">View Recipe</button>
        </div>
      </div>

      <div class="card card-recipe">
        <div class="card-image-placeholder">
          <span>Recipe Image</span>
        </div>
        <span class="card-recipe-time">45 min</span>
        <div class="card-body">
          <h3 class="card-title">Pesto Pasta</h3>
          <p class="card-text">Fresh basil pesto tossed with linguine, pine nuts, and plenty of parmesan cheese.</p>
          <div class="card-tags">
            <span class="tag tag-basil">Italian</span>
            <span class="tag tag-pasta">Cheese</span>
          </div>
        </div>
        <div class="card-footer">
          <button class="btn btn-primary btn-sm">View Recipe</button>
        </div>
      </div>

      <div class="card card-recipe">
        <div class="card-image-placeholder">
          <span>Recipe Image</span>
        </div>
        <span class="card-recipe-time">1 hr</span>
        <div class="card-body">
          <h3 class="card-title">Bolognese Ragu</h3>
          <p class="card-text">Rich, slow-simmered meat sauce with aromatics, wine, and a touch of cream.</p>
          <div class="card-tags">
            <span class="tag tag-marinara">Comfort Food</span>
          </div>
        </div>
        <div class="card-footer">
          <button class="btn btn-primary btn-sm">View Recipe</button>
        </div>
      </div>
    </div>
  </section>

  <!-- Forms Section -->
  <section class="section">
    <h2>Forms</h2>
    <p class="section-description">Input fields with warm, approachable styling.</p>

    <div class="form-demo">
      <div class="form-group">
        <label class="form-label" for="recipe-name">Recipe Name</label>
        <input type="text" id="recipe-name" class="form-input" placeholder="Enter recipe name..." bind:value={inputValue}>
        <span class="form-hint">Give your recipe a memorable name</span>
      </div>

      <div class="form-group">
        <label class="form-label" for="recipe-source">Source URL</label>
        <input type="url" id="recipe-source" class="form-input" placeholder="https://...">
      </div>

      <div class="form-group">
        <label class="form-label" for="category">Category</label>
        <select id="category" class="form-input form-select">
          <option value="">Select a category...</option>
          <option value="pasta">Pasta</option>
          <option value="soup">Soup</option>
          <option value="salad">Salad</option>
          <option value="dessert">Dessert</option>
        </select>
      </div>

      <div class="form-group">
        <label class="form-label" for="instructions">Instructions</label>
        <textarea id="instructions" class="form-input form-textarea" placeholder="Write the cooking instructions..." bind:value={textareaValue}></textarea>
      </div>

      <div class="form-group">
        <label class="form-label" for="error-field">Field with Error</label>
        <input type="text" id="error-field" class="form-input form-input-error" value="Invalid input">
        <span class="form-error">This field is required</span>
      </div>
    </div>
  </section>

  <!-- Tags & Badges Section -->
  <section class="section">
    <h2>Tags & Badges</h2>
    <p class="section-description">Labels and counters for categorization.</p>

    <h3>Tags</h3>
    <div class="tags-row">
      <span class="tag tag-basil">Vegetarian</span>
      <span class="tag tag-marinara">Spicy</span>
      <span class="tag tag-pasta">Quick Meal</span>
      <span class="tag tag-pasta">Cheesy</span>
    </div>

    <h3>Badges</h3>
    <div class="badges-row">
      <span>Recipes <span class="badge">24</span></span>
      <span>Shopping Lists <span class="badge">3</span></span>
      <span>Tags <span class="badge">12</span></span>
    </div>
  </section>

  <!-- Alerts Section -->
  <section class="section">
    <h2>Alerts</h2>
    <p class="section-description">Feedback messages for different states.</p>

    <div class="alerts-stack">
      <div class="alert alert-success">
        <strong>Success!</strong> Your recipe has been saved successfully.
      </div>
      <div class="alert alert-warning">
        <strong>Warning:</strong> This recipe has been archived and won't appear in your main list.
      </div>
      <div class="alert alert-error">
        <strong>Error:</strong> Failed to import recipe. Please check the URL and try again.
      </div>
      <div class="alert alert-info">
        <strong>Tip:</strong> You can scale ingredients by clicking the serving size.
      </div>
    </div>
  </section>

  <!-- Lists Section -->
  <section class="section">
    <h2>Lists</h2>
    <p class="section-description">Styled lists for ingredients and instructions.</p>

    <div class="lists-demo">
      <div class="list-column">
        <h3>Ingredients</h3>
        <ul class="list list-ingredients">
          <li class="list-item">400g spaghetti</li>
          <li class="list-item">2 cans San Marzano tomatoes</li>
          <li class="list-item">4 cloves garlic, minced</li>
          <li class="list-item">1/4 cup olive oil</li>
          <li class="list-item">Fresh basil leaves</li>
          <li class="list-item">Parmesan cheese, grated</li>
        </ul>
      </div>

      <div class="list-column">
        <h3>Instructions</h3>
        <ol class="list list-instructions">
          <li class="list-item">Bring a large pot of salted water to boil.</li>
          <li class="list-item">Heat olive oil in a large skillet over medium heat.</li>
          <li class="list-item">Add garlic and cook until fragrant, about 1 minute.</li>
          <li class="list-item">Add tomatoes and simmer for 20 minutes.</li>
          <li class="list-item">Cook pasta until al dente, then toss with sauce.</li>
        </ol>
      </div>
    </div>
  </section>

  <!-- Modal Section -->
  <section class="section">
    <h2>Modal</h2>
    <p class="section-description">Dialog overlay for focused interactions.</p>

    <button class="btn btn-primary" onclick={() => showModal = true}>Open Modal</button>

    <Modal bind:open={showModal} title="Add to Shopping List">
      <p>Would you like to add all ingredients from this recipe to your shopping list?</p>
      <div class="form-group">
        <label class="form-label" for="list-select">Select List</label>
        <select id="list-select" class="form-input form-select">
          <option>Weekly Groceries</option>
          <option>Party Prep</option>
          <option>Create New List...</option>
        </select>
      </div>

      {#snippet footer()}
        <button class="btn btn-ghost" onclick={() => showModal = false}>Cancel</button>
        <button class="btn btn-primary" onclick={() => showModal = false}>Add Ingredients</button>
      {/snippet}
    </Modal>
  </section>

  <!-- Navigation Section -->
  <section class="section">
    <h2>Navigation</h2>
    <p class="section-description">Header and navigation components.</p>

    <nav class="nav-header nav-demo">
      <a href="/styleguide" class="nav-brand">ControlCopyPasta</a>
      <div class="nav-links">
        <a href="/styleguide" class="nav-link nav-link-active">Recipes</a>
        <a href="/styleguide" class="nav-link">Shopping Lists</a>
        <a href="/styleguide" class="nav-link">Tags</a>
        <a href="/styleguide" class="nav-link">Settings</a>
      </div>
    </nav>
  </section>

  <!-- Spacing & Shadows Section -->
  <section class="section">
    <h2>Spacing & Shadows</h2>
    <p class="section-description">Consistent spacing scale and elevation system.</p>

    <h3>Spacing Scale</h3>
    <div class="spacing-demo">
      <div class="spacing-item"><div class="spacing-box space-1"></div><span>4px</span></div>
      <div class="spacing-item"><div class="spacing-box space-2"></div><span>8px</span></div>
      <div class="spacing-item"><div class="spacing-box space-3"></div><span>12px</span></div>
      <div class="spacing-item"><div class="spacing-box space-4"></div><span>16px</span></div>
      <div class="spacing-item"><div class="spacing-box space-6"></div><span>24px</span></div>
      <div class="spacing-item"><div class="spacing-box space-8"></div><span>32px</span></div>
    </div>

    <h3>Shadows</h3>
    <div class="shadows-demo">
      <div class="shadow-box shadow-sm">sm</div>
      <div class="shadow-box shadow-md">md</div>
      <div class="shadow-box shadow-lg">lg</div>
      <div class="shadow-box shadow-xl">xl</div>
    </div>

    <h3>Colored Shadows</h3>
    <div class="shadows-demo">
      <div class="shadow-box shadow-marinara-demo">marinara</div>
      <div class="shadow-box shadow-basil-demo">basil</div>
      <div class="shadow-box shadow-pasta-demo">pasta</div>
    </div>
  </section>
</div>

<style>
  @import '$lib/styles/styleguide.css';

  .styleguide {
    font-family: var(--font-sans);
    background-color: var(--bg-primary);
    min-height: 100vh;
    padding-bottom: var(--space-16);
  }

  .styleguide-header {
    background: linear-gradient(135deg, var(--color-marinara-700) 0%, var(--color-marinara-900) 100%);
    padding: var(--space-16) var(--space-6);
    text-align: center;
    color: var(--color-white);
  }

  .styleguide-header h1 {
    font-family: var(--font-serif);
    font-size: var(--text-5xl);
    font-weight: var(--font-bold);
    margin: 0 0 var(--space-2) 0;
    color: var(--color-pasta-100);
  }

  .styleguide-header p {
    font-size: var(--text-xl);
    margin: 0;
    opacity: 0.9;
  }

  .section {
    max-width: var(--container-xl);
    margin: 0 auto;
    padding: var(--space-12) var(--space-6);
    border-bottom: var(--border-width-thin) solid var(--border-light);
  }

  .section:last-child {
    border-bottom: none;
  }

  .section h2 {
    font-family: var(--font-serif);
    font-size: var(--text-3xl);
    color: var(--color-marinara-700);
    margin: 0 0 var(--space-2) 0;
  }

  .section h3 {
    font-size: var(--text-lg);
    color: var(--text-primary);
    margin: var(--space-8) 0 var(--space-4) 0;
  }

  .section-description {
    font-size: var(--text-lg);
    color: var(--text-secondary);
    margin: 0 0 var(--space-8) 0;
    max-width: 600px;
  }

  /* Color Grid */
  .color-description {
    font-size: var(--text-sm);
    color: var(--text-muted);
    margin: var(--space-1) 0 var(--space-4) 0;
  }

  .color-grid {
    display: flex;
    gap: var(--space-2);
    flex-wrap: wrap;
    margin-bottom: var(--space-6);
  }

  .color-swatch {
    width: 80px;
    height: 80px;
    border-radius: var(--radius-lg);
    display: flex;
    align-items: flex-end;
    justify-content: center;
    padding-bottom: var(--space-2);
    box-shadow: var(--shadow-sm);
    border: 1px solid rgba(0,0,0,0.05);
  }

  .color-swatch span {
    font-size: var(--text-xs);
    font-weight: var(--font-medium);
  }

  /* Pasta swatches - Linen / Terracotta */
  .pasta-50 { background: #fdfcf8; color: #333; }
  .pasta-100 { background: #f7f5f0; color: #333; }
  .pasta-200 { background: #ede9e0; color: #333; }
  .pasta-300 { background: #e8c4ab; color: #333; }
  .pasta-400 { background: #d4a07a; color: #333; }
  .pasta-500 { background: #c17c5a; color: #fff; }
  .pasta-600 { background: #a6664a; color: #fff; }
  .pasta-700 { background: #8a5038; color: #fff; }
  .pasta-800 { background: #6e3e2c; color: #fff; }
  .pasta-900 { background: #542e1e; color: #fff; }

  /* Marinara swatches - Forest Green */
  .marinara-50 { background: #f0f5f2; color: #333; }
  .marinara-100 { background: #ddeae4; color: #333; }
  .marinara-200 { background: #c2d1c8; color: #333; }
  .marinara-300 { background: #a8bfb0; color: #333; }
  .marinara-400 { background: #7fa898; color: #333; }
  .marinara-500 { background: #2d5a47; color: #fff; }
  .marinara-600 { background: #1b3a2d; color: #fff; }
  .marinara-700 { background: #162f24; color: #fff; }
  .marinara-800 { background: #11261c; color: #fff; }
  .marinara-900 { background: #0c1e14; color: #fff; }

  /* Basil swatches - Sage */
  .basil-50 { background: #f0f5f2; color: #333; }
  .basil-100 { background: #ddeae4; color: #333; }
  .basil-200 { background: #bcd3c8; color: #333; }
  .basil-300 { background: #96b9a8; color: #333; }
  .basil-400 { background: #729f8a; color: #333; }
  .basil-500 { background: #5a7264; color: #fff; }
  .basil-600 { background: #4a5e53; color: #fff; }
  .basil-700 { background: #3b4c42; color: #fff; }
  .basil-800 { background: #2c3a32; color: #fff; }
  .basil-900 { background: #1d2820; color: #fff; }

  /* Typography samples */
  .typography-samples {
    background: var(--bg-card);
    padding: var(--space-6);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-md);
  }

  .type-sample {
    padding: var(--space-4) 0;
    border-bottom: var(--border-width-thin) solid var(--border-light);
  }

  .type-sample:last-child {
    border-bottom: none;
  }

  .type-label {
    display: inline-block;
    font-size: var(--text-xs);
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: var(--tracking-wider);
    margin-bottom: var(--space-2);
  }

  .type-sample h1, .type-sample h2, .type-sample h3, .type-sample h4, .type-sample p, .type-sample span:not(.type-label) {
    margin: 0;
  }

  /* Button rows */
  .button-row {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-4);
    align-items: center;
    margin-bottom: var(--space-4);
  }

  /* Cards grid */
  .cards-grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
    gap: var(--space-6);
  }

  .card-image-placeholder {
    height: 180px;
    background: linear-gradient(135deg, var(--color-pasta-300) 0%, var(--color-pasta-400) 100%);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--color-pasta-700);
    font-weight: var(--font-medium);
    border-bottom: var(--border-width-thin) solid var(--border-light);
  }

  .card-tags {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2);
    margin-top: var(--space-4);
  }

  /* Form demo */
  .form-demo {
    max-width: 500px;
    background: var(--bg-card);
    padding: var(--space-6);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-md);
  }

  /* Tags row */
  .tags-row {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-3);
  }

  .badges-row {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-6);
    margin-top: var(--space-4);
    font-weight: var(--font-medium);
  }

  /* Alerts stack */
  .alerts-stack {
    display: flex;
    flex-direction: column;
    gap: var(--space-4);
    max-width: 600px;
  }

  /* Lists demo */
  .lists-demo {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: var(--space-8);
  }

  .list-column {
    background: var(--bg-card);
    padding: var(--space-6);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-md);
  }

  .list-column h3 {
    margin-top: 0;
  }

  /* Nav demo */
  .nav-demo {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  .nav-links {
    display: flex;
    gap: var(--space-2);
  }

  /* Spacing demo */
  .spacing-demo {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-6);
    align-items: flex-end;
  }

  .spacing-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: var(--space-2);
  }

  .spacing-box {
    background: var(--color-marinara-500);
    border-radius: var(--radius-sm);
  }

  .space-1 { width: 4px; height: 4px; }
  .space-2 { width: 8px; height: 8px; }
  .space-3 { width: 12px; height: 12px; }
  .space-4 { width: 16px; height: 16px; }
  .space-6 { width: 24px; height: 24px; }
  .space-8 { width: 32px; height: 32px; }

  .spacing-item span {
    font-size: var(--text-xs);
    color: var(--text-muted);
  }

  /* Shadows demo */
  .shadows-demo {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-8);
    margin-bottom: var(--space-8);
  }

  .shadow-box {
    width: 100px;
    height: 100px;
    background: var(--bg-card);
    border-radius: var(--radius-lg);
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: var(--text-sm);
    color: var(--text-muted);
  }

  .shadow-sm { box-shadow: var(--shadow-sm); }
  .shadow-md { box-shadow: var(--shadow-md); }
  .shadow-lg { box-shadow: var(--shadow-lg); }
  .shadow-xl { box-shadow: var(--shadow-xl); }
  .shadow-marinara-demo { box-shadow: 0 4px 14px 0 rgba(27, 58, 45, 0.25); }
  .shadow-basil-demo { box-shadow: 0 4px 14px 0 rgba(90, 114, 100, 0.25); }
  .shadow-pasta-demo { box-shadow: 0 4px 14px 0 rgba(193, 124, 90, 0.35); }

  @media (max-width: 768px) {
    .styleguide-header h1 {
      font-size: var(--text-3xl);
    }

    .color-swatch {
      width: 60px;
      height: 60px;
    }

    .nav-demo {
      flex-direction: column;
      gap: var(--space-4);
    }

    .nav-links {
      flex-wrap: wrap;
      justify-content: center;
    }
  }
</style>
