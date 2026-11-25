// What the sitemap captures and how it is grouped. Routes themselves are discovered
// from frontend/src/routes, so a new page shows up without touching this file; it
// lands in "Other" until a section claims its prefix.

export const BASE_URL = process.env.SITEMAP_BASE_URL || 'https://controlcopypasta.com';

export const TOKEN_KEY = 'controlcopypasta_token';

export const VIEWPORTS = [
  { id: 'desktop', width: 1440, height: 900 },
  { id: 'mobile', width: 390, height: 844 }
];

// Full-page captures are cut off here (px) so an endless list doesn't dominate the canvas.
export const MAX_HEIGHT = Number(process.env.SITEMAP_MAX_HEIGHT || 7000);

// First matching prefix wins.
export const SECTIONS = [
  { id: 'entry', title: 'Entry & auth', match: ['/', '/login', '/auth', '/setup', '/link-account'], exact: ['/'] },
  { id: 'home', title: 'Home & deciding what to cook', match: ['/home', '/quicklist'] },
  { id: 'recipes', title: 'My recipes', match: ['/recipes'] },
  { id: 'browse', title: 'Browse', match: ['/browse'] },
  { id: 'inbox', title: 'Inbox', match: ['/inbox'] },
  { id: 'ingredients', title: 'Ingredients', match: ['/ingredients'] },
  { id: 'shopping', title: 'Shopping lists', match: ['/shopping-lists'] },
  { id: 'account', title: 'Tags & settings', match: ['/tags', '/settings'] },
  { id: 'admin', title: 'Admin', match: ['/admin'] },
  { id: 'design', title: 'Design references', match: ['/mockups', '/styleguide'] },
  { id: 'other', title: 'Other', match: [''] }
];

// Listed on the map as placeholders but not screenshotted unless asked for:
//   node capture.mjs --include=admin,design
export const SKIPPED_SECTIONS = ['admin', 'design'];

// Captured with the auth token temporarily set aside, so the logged-out view is what shows.
export const ANONYMOUS = ['/', '/login', '/auth/verify'];

// Routes that only make sense with a query string. `links` maps a captured route
// pattern to the internal hrefs found on it.
export const QUERY = {
  '/recipes/compare': (links) => {
    const ids = [...new Set((links['/recipes'] || []).map((h) => (h.match(/^\/recipes\/([^/?]+)$/) || [])[1]))]
      .filter((id) => id && id !== 'new' && id !== 'compare')
      .slice(0, 2);
    return ids.length === 2 ? `?id1=${ids[0]}&id2=${ids[1]}` : '';
  }
};

// Pin a dynamic segment instead of taking the first link found on the parent page,
// e.g. { '/recipes/[id]': 'a-specific-recipe-uuid' }.
export const PARAMS = {};
