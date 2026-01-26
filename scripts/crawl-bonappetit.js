const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const BASE_URL = 'https://www.bonappetit.com';
const START_URLS = [
  'https://www.bonappetit.com/recipes',
  'https://www.bonappetit.com/recipe'
];

const MAX_RECIPES = parseInt(process.env.MAX_RECIPES || '1000', 10);
const OUTPUT_FILE = path.join(__dirname, 'bonappetit-recipes.json');
const VISITED_FILE = path.join(__dirname, 'bonappetit-visited.json');
const QUEUE_FILE = path.join(__dirname, 'bonappetit-queue.json');

// Load previous state if exists
let visitedUrls = new Set();
let recipeUrls = new Set();
let savedQueue = [];

try {
  const visited = JSON.parse(fs.readFileSync(VISITED_FILE, 'utf8'));
  visitedUrls = new Set(visited);
  console.log(`Loaded ${visitedUrls.size} previously visited URLs`);
} catch (e) {
  // Start fresh
}

try {
  savedQueue = JSON.parse(fs.readFileSync(QUEUE_FILE, 'utf8'));
  console.log(`Loaded ${savedQueue.length} URLs from previous queue`);
} catch (e) {
  // Start fresh
}

const recipes = [];

function isRecipeUrl(url) {
  // Bon Appétit recipe URLs look like: /recipe/recipe-name
  return url && url.includes('/recipe/') && !url.includes('/recipes');
}

function extractLinks(html, baseUrl) {
  const links = [];
  const linkRegex = /href="([^"]+)"/g;
  let match;

  while ((match = linkRegex.exec(html)) !== null) {
    let href = match[1];

    // Skip non-http links
    if (href.startsWith('#') || href.startsWith('javascript:') || href.startsWith('mailto:')) {
      continue;
    }

    // Convert relative URLs to absolute
    if (href.startsWith('/')) {
      href = BASE_URL + href;
    }

    // Only keep bonappetit.com links
    if (href.includes('bonappetit.com')) {
      links.push(href);
    }
  }

  return links;
}

function extractJsonLd(html) {
  const scripts = html.match(/<script[^>]*type="application\/ld\+json"[^>]*>([\s\S]*?)<\/script>/gi) || [];

  for (const script of scripts) {
    const jsonMatch = script.match(/<script[^>]*>([\s\S]*?)<\/script>/i);
    if (jsonMatch) {
      try {
        const data = JSON.parse(jsonMatch[1]);

        // Handle @graph structure
        if (data['@graph']) {
          const recipe = data['@graph'].find(item => item['@type'] === 'Recipe');
          if (recipe) return recipe;
        }

        // Direct recipe
        if (data['@type'] === 'Recipe') {
          return data;
        }

        // Array of items
        if (Array.isArray(data)) {
          const recipe = data.find(item => item['@type'] === 'Recipe');
          if (recipe) return recipe;
        }
      } catch (e) {
        // Continue to next script
      }
    }
  }

  return null;
}

function parseRecipe(jsonLd, url) {
  if (!jsonLd) return null;

  const recipe = {
    title: jsonLd.name || '',
    description: jsonLd.description || null,
    source_url: url,
    source_domain: 'bonappetit.com',
    image_url: null,
    ingredients: [],
    instructions: [],
    prep_time_minutes: null,
    cook_time_minutes: null,
    total_time_minutes: null,
    servings: null,
    notes: null
  };

  // Image
  if (jsonLd.image) {
    if (typeof jsonLd.image === 'string') {
      recipe.image_url = jsonLd.image;
    } else if (Array.isArray(jsonLd.image)) {
      recipe.image_url = jsonLd.image[0]?.url || jsonLd.image[0] || null;
    } else if (jsonLd.image.url) {
      recipe.image_url = jsonLd.image.url;
    }
  }

  // Ingredients
  if (jsonLd.recipeIngredient) {
    recipe.ingredients = jsonLd.recipeIngredient.map(text => ({ text, group: null }));
  }

  // Instructions
  if (jsonLd.recipeInstructions) {
    recipe.instructions = jsonLd.recipeInstructions.map((inst, idx) => {
      const text = typeof inst === 'string' ? inst : (inst.text || inst.name || '');
      return { step: idx + 1, text };
    }).filter(i => i.text);
  }

  // Times (ISO 8601 duration)
  function parseDuration(duration) {
    if (!duration) return null;
    const match = duration.match(/PT(?:(\d+)H)?(?:(\d+)M)?/);
    if (match) {
      const hours = parseInt(match[1] || '0', 10);
      const minutes = parseInt(match[2] || '0', 10);
      return hours * 60 + minutes;
    }
    return null;
  }

  recipe.prep_time_minutes = parseDuration(jsonLd.prepTime);
  recipe.cook_time_minutes = parseDuration(jsonLd.cookTime);
  recipe.total_time_minutes = parseDuration(jsonLd.totalTime);

  // Servings
  if (jsonLd.recipeYield) {
    recipe.servings = Array.isArray(jsonLd.recipeYield)
      ? jsonLd.recipeYield[0]
      : String(jsonLd.recipeYield);
  }

  return recipe;
}

async function crawl() {
  console.log(`Starting Bon Appétit crawler (max ${MAX_RECIPES} recipes)...`);

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({
    userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  });

  const page = await context.newPage();

  // Queue of URLs to visit - use saved queue if exists, otherwise start fresh
  const queue = savedQueue.length > 0 ? [...savedQueue] : [...START_URLS];

  try {
    while (queue.length > 0 && recipes.length < MAX_RECIPES) {
      const url = queue.shift();

      // Skip if already visited
      if (visitedUrls.has(url)) continue;
      visitedUrls.add(url);

      console.log(`\nVisiting: ${url}`);
      console.log(`  Progress: ${recipes.length}/${MAX_RECIPES} recipes, ${queue.length} URLs queued`);

      try {
        await page.goto(url, {
          waitUntil: 'domcontentloaded',
          timeout: 30000
        });

        // Wait a bit for dynamic content
        await page.waitForTimeout(1000);

        const html = await page.content();

        // Extract links for more recipes
        const links = extractLinks(html, url);
        for (const link of links) {
          const cleanLink = link.split('?')[0].split('#')[0];

          if (isRecipeUrl(cleanLink) && !recipeUrls.has(cleanLink)) {
            recipeUrls.add(cleanLink);
            queue.push(cleanLink);
          } else if (cleanLink.includes('/recipes') && !visitedUrls.has(cleanLink)) {
            // Recipe listing pages
            queue.push(cleanLink);
          }
        }

        // If this is a recipe page, extract the recipe
        if (isRecipeUrl(url)) {
          const jsonLd = extractJsonLd(html);
          if (jsonLd) {
            const recipe = parseRecipe(jsonLd, url);
            if (recipe && recipe.title && recipe.ingredients.length > 0) {
              recipes.push(recipe);
              console.log(`  ✓ Extracted: ${recipe.title} (${recipe.ingredients.length} ingredients)`);
            } else {
              console.log(`  ✗ Could not parse recipe data`);
            }
          } else {
            console.log(`  ✗ No JSON-LD recipe data found`);
          }
        }

        // Small delay to be nice to the server
        await page.waitForTimeout(500);

      } catch (e) {
        console.log(`  ✗ Error: ${e.message}`);
      }
    }

  } finally {
    await browser.close();
  }

  // Save state for resuming later
  fs.writeFileSync(VISITED_FILE, JSON.stringify([...visitedUrls], null, 2));
  console.log(`Saved ${visitedUrls.size} visited URLs to ${VISITED_FILE}`);

  fs.writeFileSync(QUEUE_FILE, JSON.stringify(queue, null, 2));
  console.log(`Saved ${queue.length} queued URLs to ${QUEUE_FILE}`);

  // Save results
  console.log(`\n\nCrawling complete!`);
  console.log(`Found ${recipes.length} recipes`);

  fs.writeFileSync(OUTPUT_FILE, JSON.stringify(recipes, null, 2));
  console.log(`Saved to ${OUTPUT_FILE}`);

  return recipes;
}

crawl().catch(console.error);
