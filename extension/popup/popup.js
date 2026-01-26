// Sections
const sections = {
  login: document.getElementById('login-section'),
  loading: document.getElementById('loading-section'),
  noRecipe: document.getElementById('no-recipe-section'),
  recipe: document.getElementById('recipe-section'),
  saving: document.getElementById('saving-section'),
  success: document.getElementById('success-section'),
  error: document.getElementById('error-section')
};

// Elements
const elements = {
  openOptions: document.getElementById('open-options'),
  recipeImage: document.getElementById('recipe-image'),
  recipeTitle: document.getElementById('recipe-title'),
  recipeMeta: document.getElementById('recipe-meta'),
  saveRecipe: document.getElementById('save-recipe'),
  viewRecipe: document.getElementById('view-recipe'),
  errorMessage: document.getElementById('error-message'),
  tryAgain: document.getElementById('try-again')
};

let currentRecipeData = null;
let currentUrl = null;

function showSection(sectionName) {
  Object.values(sections).forEach(section => section.classList.add('hidden'));
  if (sections[sectionName]) {
    sections[sectionName].classList.remove('hidden');
  }
}

async function getSettings() {
  const result = await chrome.storage.sync.get(['serverUrl', 'token']);
  return {
    serverUrl: result.serverUrl || 'http://localhost:4000',
    token: result.token || null
  };
}

async function initialize() {
  const settings = await getSettings();

  if (!settings.token) {
    showSection('login');
    return;
  }

  showSection('loading');

  // Get current tab URL
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  currentUrl = tab.url;

  // Try to detect recipe on page
  try {
    const [result] = await chrome.scripting.executeScript({
      target: { tabId: tab.id },
      func: detectRecipeOnPage
    });

    if (result && result.result) {
      displayRecipe(result.result);
    } else {
      // Fallback to server-side parsing
      await parseWithServer(settings);
    }
  } catch (error) {
    console.error('Content script error:', error);
    // Fallback to server-side parsing
    await parseWithServer(settings);
  }
}

function detectRecipeOnPage() {
  // Look for JSON-LD recipe data
  const scripts = document.querySelectorAll('script[type="application/ld+json"]');

  for (const script of scripts) {
    try {
      const data = JSON.parse(script.textContent);
      const recipe = findRecipe(data);
      if (recipe) {
        return normalizeRecipe(recipe);
      }
    } catch (e) {
      // Continue to next script
    }
  }

  return null;

  function findRecipe(data) {
    if (!data) return null;

    if (data['@type'] === 'Recipe') return data;
    if (Array.isArray(data['@type']) && data['@type'].includes('Recipe')) return data;

    if (data['@graph']) {
      for (const item of data['@graph']) {
        if (item['@type'] === 'Recipe') return item;
        if (Array.isArray(item['@type']) && item['@type'].includes('Recipe')) return item;
      }
    }

    if (Array.isArray(data)) {
      for (const item of data) {
        const found = findRecipe(item);
        if (found) return found;
      }
    }

    return null;
  }

  function normalizeRecipe(recipe) {
    return {
      title: recipe.name || '',
      description: recipe.description || '',
      image_url: getImageUrl(recipe.image),
      ingredients: (recipe.recipeIngredient || []).map(text => ({ text, group: null })),
      instructions: normalizeInstructions(recipe.recipeInstructions || []),
      prep_time_minutes: parseDuration(recipe.prepTime),
      cook_time_minutes: parseDuration(recipe.cookTime),
      total_time_minutes: parseDuration(recipe.totalTime),
      servings: getServings(recipe.recipeYield)
    };
  }

  function getImageUrl(image) {
    if (!image) return null;
    if (typeof image === 'string') return image;
    if (image.url) return image.url;
    if (Array.isArray(image)) return getImageUrl(image[0]);
    return null;
  }

  function normalizeInstructions(instructions) {
    const result = [];
    let step = 1;

    for (const inst of instructions) {
      if (typeof inst === 'string') {
        result.push({ step: step++, text: inst });
      } else if (inst.text) {
        result.push({ step: step++, text: inst.text });
      } else if (inst.itemListElement) {
        for (const item of inst.itemListElement) {
          if (item.text) {
            result.push({ step: step++, text: item.text });
          }
        }
      }
    }

    return result;
  }

  function parseDuration(duration) {
    if (!duration) return null;
    const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
    if (!match) return null;
    const hours = parseInt(match[1] || '0', 10);
    const minutes = parseInt(match[2] || '0', 10);
    return hours * 60 + minutes;
  }

  function getServings(yield_) {
    if (!yield_) return null;
    if (typeof yield_ === 'string') return yield_;
    if (Array.isArray(yield_)) return yield_[0];
    return String(yield_);
  }
}

async function parseWithServer(settings) {
  try {
    const response = await fetch(`${settings.serverUrl}/api/recipes/parse`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${settings.token}`
      },
      body: JSON.stringify({ url: currentUrl })
    });

    if (response.ok) {
      const data = await response.json();
      displayRecipe(data.data);
    } else {
      showSection('noRecipe');
    }
  } catch (error) {
    console.error('Server parse error:', error);
    showSection('noRecipe');
  }
}

function displayRecipe(data) {
  currentRecipeData = data;

  elements.recipeTitle.textContent = data.title || 'Untitled Recipe';

  if (data.image_url) {
    elements.recipeImage.src = data.image_url;
    elements.recipeImage.classList.remove('hidden');
  } else {
    elements.recipeImage.classList.add('hidden');
  }

  const meta = [];
  if (data.total_time_minutes) {
    meta.push(`${data.total_time_minutes} min`);
  }
  if (data.servings) {
    meta.push(`${data.servings} servings`);
  }
  if (data.ingredients && data.ingredients.length) {
    meta.push(`${data.ingredients.length} ingredients`);
  }
  elements.recipeMeta.textContent = meta.join(' • ');

  showSection('recipe');
}

async function saveRecipe() {
  if (!currentRecipeData) return;

  showSection('saving');

  const settings = await getSettings();

  try {
    const recipeToSave = {
      ...currentRecipeData,
      source_url: currentUrl
    };

    const response = await fetch(`${settings.serverUrl}/api/recipes`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${settings.token}`
      },
      body: JSON.stringify({ recipe: recipeToSave })
    });

    if (response.ok) {
      const data = await response.json();
      elements.viewRecipe.href = `${settings.serverUrl.replace('/api', '').replace(':4000', ':5173')}/recipes/${data.data.id}`;
      showSection('success');
    } else {
      const error = await response.json();
      throw new Error(error.errors ? Object.values(error.errors).flat().join(', ') : 'Failed to save recipe');
    }
  } catch (error) {
    elements.errorMessage.textContent = error.message || 'Failed to save recipe';
    showSection('error');
  }
}

// Event listeners
elements.openOptions.addEventListener('click', () => {
  chrome.runtime.openOptionsPage();
});

elements.saveRecipe.addEventListener('click', saveRecipe);

elements.tryAgain.addEventListener('click', initialize);

// Initialize
initialize();
