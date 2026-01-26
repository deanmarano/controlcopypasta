// Content script for ControlCopyPasta
// This script runs on every page and can detect recipe data

// Listen for messages from the popup
chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'detectRecipe') {
    const recipe = detectRecipeOnPage();
    sendResponse({ recipe });
  }
  return true;
});

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
}

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
    ingredients: (recipe.recipeIngredient || []).map(text => ({ text: String(text).trim(), group: null })),
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
      result.push({ step: step++, text: inst.trim() });
    } else if (inst.text) {
      result.push({ step: step++, text: inst.text.trim() });
    } else if (inst.itemListElement) {
      for (const item of inst.itemListElement) {
        if (item.text) {
          result.push({ step: step++, text: item.text.trim() });
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
  return hours * 60 + minutes || null;
}

function getServings(yield_) {
  if (!yield_) return null;
  if (typeof yield_ === 'string') return yield_;
  if (Array.isArray(yield_)) return String(yield_[0]);
  if (typeof yield_ === 'number') return String(yield_);
  return null;
}
