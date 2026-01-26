import { chromium } from 'playwright';
import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));

const username = process.env.COPYMETHAT_USERNAME;
const password = process.env.COPYMETHAT_PASSWORD;

if (!username || !password) {
  console.error('Please set COPYMETHAT_USERNAME and COPYMETHAT_PASSWORD environment variables');
  process.exit(1);
}

async function scrape() {
  console.log('Launching browser...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  try {
    // Navigate to homepage first
    console.log('Navigating to Copy Me That...');
    await page.goto('https://www.copymethat.com/', { waitUntil: 'networkidle' });
    await page.waitForTimeout(2000);

    // Take screenshot for debugging
    await page.screenshot({ path: '/tmp/cmt-home.png' });
    console.log('Homepage screenshot saved to /tmp/cmt-home.png');

    // Print all links on page for debugging
    const links = await page.$$eval('a', anchors => anchors.map(a => ({ text: a.textContent.trim(), href: a.href })));
    console.log('Links found:', links.filter(l => l.text.toLowerCase().includes('log') || l.href.includes('log')));

    // Click the LOGIN link - it's in the header
    console.log('Clicking LOGIN button...');
    try {
      // Try various selectors
      await page.click('a:text-is("LOGIN")', { timeout: 3000 });
    } catch {
      try {
        await page.click('text="LOGIN"', { timeout: 3000 });
      } catch {
        try {
          await page.click('.login-link, .nav-login, header a:last-child', { timeout: 3000 });
        } catch {
          // Try using evaluate to click the login link
          await page.evaluate(() => {
            const links = document.querySelectorAll('a');
            for (const link of links) {
              if (link.textContent.trim().toUpperCase() === 'LOGIN') {
                link.click();
                return;
              }
            }
          });
        }
      }
    }
    await page.waitForTimeout(3000);

    // Take screenshot for debugging
    await page.screenshot({ path: '/tmp/cmt-login.png' });
    console.log('Screenshot saved to /tmp/cmt-login.png');

    // Check if we have a login form visible - it might be in a modal
    console.log('Waiting for login form...');

    // Wait for modal to appear - look for email/username input
    // The placeholder says "Email or username"
    const emailInput = page.locator('input[placeholder*="Email"], input[placeholder*="email"], input[placeholder*="username"]').first();
    await emailInput.waitFor({ state: 'visible', timeout: 10000 });

    // Fill in login form
    console.log('Logging in...');
    await emailInput.fill(username);

    const passwordInput = page.locator('input[placeholder*="Password"], input[placeholder*="password"], input[type="password"]').first();
    await passwordInput.fill(password);

    // Take screenshot before submit
    await page.screenshot({ path: '/tmp/cmt-filled.png' });
    console.log('Filled form screenshot saved');

    // Find and click the "Log In" button - might be button, a, or div
    console.log('Looking for submit button...');
    const submitButton = page.locator('text="Log In" >> visible=true').first();
    await submitButton.click({ timeout: 10000 }).catch(async () => {
      console.log('First selector failed, trying alternative...');
      // Try clicking any element with Log In text
      await page.evaluate(() => {
        const elements = document.querySelectorAll('button, a, div, span');
        for (const el of elements) {
          if (el.textContent.trim() === 'Log In' || el.textContent.trim() === 'Log in') {
            el.click();
            return;
          }
        }
      });
    });

    // Wait for navigation after login
    await page.waitForURL('**/recipes/**', { timeout: 30000 }).catch(() => {
      // May redirect elsewhere
    });
    await page.waitForTimeout(2000);

    // Navigate to recipes page - use ?page= parameter for pagination
    console.log('Navigating to recipes...');

    let allRecipeLinks = new Set();
    let page_num = 1;
    const maxPages = 20; // Safety limit

    while (page_num <= maxPages) {
      const url = page_num === 1
        ? 'https://www.copymethat.com/recipes/'
        : `https://www.copymethat.com/recipes/?page=${page_num}`;

      console.log(`Loading page ${page_num}: ${url}`);
      await page.goto(url, { waitUntil: 'networkidle' });
      await page.waitForTimeout(2000);

      // Get recipe links on this page
      const pageLinks = await page.$$eval('a[href*="/r/"]', links =>
        links.map(a => a.href).filter(href => href.includes('/r/'))
      );

      const uniquePageLinks = [...new Set(pageLinks)];
      console.log(`  Found ${uniquePageLinks.length} recipes on page ${page_num}`);

      // Check if we got any new recipes
      const previousCount = allRecipeLinks.size;
      uniquePageLinks.forEach(link => allRecipeLinks.add(link));

      if (allRecipeLinks.size === previousCount && page_num > 1) {
        // No new recipes found, we've likely reached the end
        console.log(`  -> No new recipes, stopping pagination`);
        break;
      }

      if (uniquePageLinks.length === 0) {
        console.log(`  -> Empty page, stopping pagination`);
        break;
      }

      console.log(`  Total unique recipes so far: ${allRecipeLinks.size}`);
      page_num++;
    }

    const uniqueLinks = [...allRecipeLinks];
    console.log(`\nFound ${uniqueLinks.length} total recipes across all pages`);

    const recipes = [];

    for (let i = 0; i < uniqueLinks.length; i++) {
      const link = uniqueLinks[i];
      console.log(`[${i + 1}/${uniqueLinks.length}] Scraping: ${link}`);

      // Skip edit pages
      if (link.includes('/edit/')) {
        console.log('  -> Skipping edit page');
        continue;
      }

      try {
        await page.goto(link, { waitUntil: 'networkidle' });

        // Wait for recipe content to load - CMT uses JavaScript rendering
        await page.waitForSelector('.recipe-container, [class*="recipe"], [class*="Recipe"]', { timeout: 10000 }).catch(() => {});
        await page.waitForTimeout(2000);

        // Take screenshot of first recipe for debugging
        if (i === 1) {
          await page.screenshot({ path: '/tmp/cmt-recipe.png', fullPage: true });
          console.log('  -> Recipe screenshot saved to /tmp/cmt-recipe.png');
        }

        const recipe = await page.evaluate(() => {
          // CMT-specific extraction based on observed page structure
          // The recipe name appears to be in a large text near the top
          // Source URL is shown as a link below the title

          // Get all text content for analysis
          const bodyText = document.body?.innerText || '';

          // Recipe name - look for the first large text that's not navigation
          let name = null;
          // Try to find the recipe title - it's usually the first significant text after navigation
          const possibleTitles = document.querySelectorAll('h1, h2, [class*="title"], [class*="name"], [class*="Title"], [class*="Name"]');
          for (const el of possibleTitles) {
            const text = el.textContent.trim();
            if (text && text.length > 3 && text.length < 200 && !text.includes('RECIPES') && !text.includes('COPY ME THAT')) {
              name = text;
              break;
            }
          }

          // If no title found via selectors, try to find it from the page text
          if (!name) {
            // Look for text that appears before common recipe sections
            const lines = bodyText.split('\n').map(l => l.trim()).filter(l => l);
            for (const line of lines.slice(0, 20)) {
              if (line.length > 5 && line.length < 100 &&
                  !line.includes('RECIPES') && !line.includes('SHOPPING') &&
                  !line.includes('MEAL PLAN') && !line.includes('MORE') &&
                  !line.includes('CREATE') && !line.includes('COMMUNITY') &&
                  !line.includes('MINE')) {
                name = line;
                break;
              }
            }
          }

          // Source URL - look for external links (not copymethat, facebook, etc)
          let url = null;
          const allLinks = document.querySelectorAll('a[href]');
          for (const link of allLinks) {
            const href = link.href;
            const text = link.textContent.trim();
            // Look for links that look like source URLs
            if (href && href.startsWith('http') &&
                !href.includes('copymethat.com') &&
                !href.includes('facebook') &&
                !href.includes('pinterest') &&
                !href.includes('twitter') &&
                !href.includes('google') &&
                text && !text.includes('Share') && !text.includes('Print')) {
              url = href;
              break;
            }
          }

          // Description - usually appears after title, before ingredients
          let description = null;
          const descCandidates = document.querySelectorAll('[class*="description"], [class*="Description"], [class*="summary"], p');
          for (const el of descCandidates) {
            const text = el.textContent.trim();
            if (text && text.length > 10 && text.length < 500 &&
                !text.includes('Ingredients') && !text.includes('Steps')) {
              description = text;
              break;
            }
          }

          // Image - look for recipe images
          let image = null;
          const imgs = document.querySelectorAll('img[src]');
          for (const img of imgs) {
            const src = img.src;
            if (src && !src.includes('avatar') && !src.includes('icon') && !src.includes('logo') &&
                (src.includes('recipe') || src.includes('food') || src.includes('cloudfront') || img.width > 200)) {
              image = src;
              break;
            }
          }

          // Ingredients - look for list items in ingredients section
          let ingredients = [];
          // First try to find an Ingredients header and get following list items
          const ingredientsHeader = Array.from(document.querySelectorAll('h2, h3, strong, b, [class*="heading"]'))
            .find(el => el.textContent.trim().toLowerCase().includes('ingredient'));

          if (ingredientsHeader) {
            let sibling = ingredientsHeader.nextElementSibling;
            while (sibling && !sibling.textContent.toLowerCase().includes('step') &&
                   !sibling.textContent.toLowerCase().includes('instruction') &&
                   !sibling.textContent.toLowerCase().includes('direction')) {
              const items = sibling.querySelectorAll('li');
              if (items.length > 0) {
                ingredients = [...ingredients, ...Array.from(items).map(li => li.textContent.trim())];
              } else if (sibling.tagName === 'LI') {
                ingredients.push(sibling.textContent.trim());
              }
              sibling = sibling.nextElementSibling;
            }
          }

          // Fallback: look for any list that looks like ingredients
          if (ingredients.length === 0) {
            const lists = document.querySelectorAll('ul, ol');
            for (const list of lists) {
              const items = Array.from(list.querySelectorAll('li')).map(li => li.textContent.trim());
              // Check if items look like ingredients (contain measurements)
              const looksLikeIngredients = items.some(item =>
                /\d/.test(item) && (
                  item.includes('cup') || item.includes('tsp') || item.includes('tbsp') ||
                  item.includes('oz') || item.includes('lb') || item.includes('g ') ||
                  item.includes('ml') || item.includes('pinch') || item.includes('egg')
                )
              );
              if (looksLikeIngredients && items.length >= 2) {
                ingredients = items;
                break;
              }
            }
          }

          // Instructions/Steps
          let instructionTexts = [];
          const stepsHeader = Array.from(document.querySelectorAll('h2, h3, strong, b, [class*="heading"]'))
            .find(el => {
              const text = el.textContent.trim().toLowerCase();
              return text.includes('step') || text.includes('instruction') || text.includes('direction');
            });

          if (stepsHeader) {
            let sibling = stepsHeader.nextElementSibling;
            while (sibling) {
              const items = sibling.querySelectorAll('li');
              if (items.length > 0) {
                instructionTexts = [...instructionTexts, ...Array.from(items).map(li => li.textContent.trim())];
              } else if (sibling.tagName === 'LI' || sibling.tagName === 'P') {
                const text = sibling.textContent.trim();
                if (text && text.length > 10) {
                  instructionTexts.push(text);
                }
              }
              sibling = sibling.nextElementSibling;
            }
          }

          const instructions = instructionTexts.filter(t => t).join('\n');

          // Servings - look for "Servings:" text
          let yield_ = null;
          const servingsMatch = bodyText.match(/Servings?:?\s*(\d+)/i);
          if (servingsMatch) {
            yield_ = servingsMatch[1];
          }

          // Times
          const prepTimeMatch = bodyText.match(/Prep(?:\s*Time)?:?\s*(\d+\s*(?:min|hour|hr|m|h)[a-z]*)/i);
          const cookTimeMatch = bodyText.match(/Cook(?:\s*Time)?:?\s*(\d+\s*(?:min|hour|hr|m|h)[a-z]*)/i);
          const totalTimeMatch = bodyText.match(/Total(?:\s*Time)?:?\s*(\d+\s*(?:min|hour|hr|m|h)[a-z]*)/i);

          const prepTime = prepTimeMatch ? prepTimeMatch[1] : null;
          const cookTime = cookTimeMatch ? cookTimeMatch[1] : null;
          const totalTime = totalTimeMatch ? totalTimeMatch[1] : null;

          // Tags/Categories
          const tagEls = document.querySelectorAll('[class*="tag"], [class*="category"], [class*="Tag"], [class*="Category"]');
          const tags = Array.from(tagEls).map(el => el.textContent.trim()).filter(t => t && t.length < 50);

          // Debug info
          const debug = {
            foundName: !!name,
            foundUrl: !!url,
            ingredientCount: ingredients.length,
            instructionCount: instructionTexts.length,
            firstLine: bodyText.split('\n').filter(l => l.trim())[0]?.substring(0, 50)
          };

          return {
            name,
            url,
            description,
            image,
            ingredients: ingredients.filter(i => i),
            instructions,
            prepTime,
            cookTime,
            totalTime,
            yield: yield_,
            tags,
            _debug: debug
          };
        });

        if (recipe.name) {
          // Remove debug info before saving
          const { _debug, ...cleanRecipe } = recipe;
          recipes.push(cleanRecipe);
          console.log(`  -> ${recipe.name} (URL: ${recipe.url || 'none'})`);
        } else {
          console.log(`  -> No name found. Debug: ${JSON.stringify(recipe._debug)}`);
        }
      } catch (err) {
        console.error(`  Error scraping ${link}: ${err.message}`);
      }
    }

    // Save to fixture file
    const outputPath = join(__dirname, '..', 'test', 'fixtures', 'cmt_export.json');
    writeFileSync(outputPath, JSON.stringify(recipes, null, 2));
    console.log(`\nSaved ${recipes.length} recipes to ${outputPath}`);

    // Summary
    const withUrls = recipes.filter(r => r.url && r.url.startsWith('http')).length;
    console.log(`Recipes with source URLs: ${withUrls}/${recipes.length}`);

  } finally {
    await browser.close();
  }
}

scrape().catch(err => {
  console.error('Scrape failed:', err);
  process.exit(1);
});
