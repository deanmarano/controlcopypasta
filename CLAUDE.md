# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary

ControlCopyPasta is a self-hosted recipe management app with a Phoenix (Elixir) backend, SvelteKit frontend, and browser extension. PostgreSQL with JSONB for storing ingredients/instructions. Includes a web scraping system for discovering and importing recipes from external sites.

## Commands

```bash
# Start everything with Procfile (recommended)
overmind start -f Procfile.dev   # Or: foreman start -f Procfile.dev

# Or start services individually:

# Start infrastructure (PostgreSQL + Mailhog)
docker compose up -d   # Dev postgres on 5434, test on 5433, Mailhog on 8025

# Backend (Phoenix) - run from backend/
mix deps.get
mix ecto.setup        # Create DB + run migrations
mix ecto.migrate      # Run pending migrations only
mix phx.server        # Start at localhost:4000
mix test              # Run all tests
mix test path/to/test.exs:42  # Run single test at line

# Frontend (SvelteKit) - run from frontend/
npm install
npm run dev           # Start at localhost:5173
npm run build
npm run test          # Run tests

# Dev database on port 5434, test database on port 5433

# Production deployment
git push dokku                            # Deploy to Dokku (expects trunk branch)
docker compose -f docker-compose.prod.yml up -d  # Or: local Docker deployment
```

## Architecture

- **backend/** - Phoenix API (no HTML views, JSON only)
  - `lib/controlcopypasta/` - Business logic contexts:
    - `recipes/`, `accounts/`, `parser/`, `import/` - Core domain logic
    - `browser/` - Playwright browser pool for headless scraping (pool.ex, worker.ex)
    - `scraper/` - URL queue management, rate limiting, domain metadata
    - `workers/` - Oban background jobs (ingredient_parser.ex, scraper_unpauser.ex)
  - `lib/controlcopypasta_web/` - Controllers, router, plugs
    - `controllers/admin/` - Admin-only endpoints (scraper management)
  - `test/` - ExUnit tests
- **frontend/** - SvelteKit SPA consuming the Phoenix API
  - `src/lib/` - API client, stores, utilities
  - `src/routes/` - Pages (recipes, tags, auth, admin/scraping)
  - Vitest tests for API client and auth store
- **extension/** - Browser extension (WebExtension API for Chrome/Firefox)
  - `manifest.chrome.json` - Chrome Manifest V3
  - `manifest.firefox.json` - Firefox Manifest V2
- **scripts/** - Supporting scripts
  - `browser-worker.js` - Node.js Playwright script for headless browser operations

## Key Technical Decisions

- **Auth (Alpha)**: Magic link only via Phoenix.Token + Guardian JWTs. No passwords initially.
- **Recipe data**: Ingredients and instructions stored as JSONB arrays (see PROJECT_PLAN.md for structure)
- **Recipe parsing**: Hybrid approach - Schema.org JSON-LD first, custom scrapers as fallback
- **Recipe scaling**: Frontend supports scaling ingredient quantities (0.25x to 4x)
- **Print view**: Print-friendly CSS for recipe detail pages
- **Email (dev)**: Mailhog captures all emails at http://localhost:8025
- **Web scraping**: NimblePool-based browser pool using Playwright (Node.js) for JS-rendered pages
- **Background jobs**: Oban for job queuing (scraping, ingredient parsing, scheduled tasks)
- **Rate limiting**: Per-domain rate limits (default 150/hour, 2500/day) with polite delays

## Environment Variables

Store in `.env` (not committed). See `.env.example` for full list:
- `DATABASE_URL` - Default: `postgres://postgres:postgres@localhost/controlcopypasta_dev`
- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `GUARDIAN_SECRET_KEY` - JWT signing (generate with `mix phx.gen.secret`)
- `SMTP_HOST`/`SMTP_PORT` - Dev: `localhost:1025` (Mailhog)
- `FRONTEND_URL` - URL for magic link emails (default: http://localhost:5173)
- `ENABLE_SCRAPING` - Enable scraping system (default: false in dev, true in prod)
- `DISABLE_BROWSER_POOL` - Set to disable browser pool startup
- `BROWSER_POOL_SIZE` - Number of browser instances in pool (default: 1)
- `OBAN_SCRAPER_CONCURRENCY` - Number of concurrent scraper workers (default: 1, should match pool size)

## API Routes

Key patterns:
- `/api/recipes` - Recipe CRUD
- `/api/recipes/parse` - Parse recipe from URL
- `/api/tags` - Tag management
- `/api/auth/*` - Authentication (magic-link, verify, refresh, logout, me)
- `/api/import/copymethat` - Import recipes from Copy Me That JSON export
- `/api/browse/domains/:domain/screenshot` - Public domain screenshot endpoint

### Admin Routes (require admin role)
- `/admin/scraper/domains` - List/add domains for scraping
- `/admin/scraper/queue` - Queue statistics (pending, processing, completed, failed, paused)
- `/admin/scraper/rate-limits` - Per-domain rate limit status
- `/admin/scraper/pause` / `/admin/scraper/resume` - Pause/resume scraping
- `/admin/scraper/failed` - List failed URLs
- `/admin/scraper/retry-failed` - Retry failed URLs
- `/admin/scraper/browser-status` - Browser pool health and statistics
- `/admin/scraper/reset-stale` - Reset URLs stuck in processing
- `/admin/scraper/parse-ingredients` - Trigger ingredient parsing for scraped recipes

## Browser Pool & Scraping

The scraping system discovers and imports recipes from external websites.

### Components
- **Browser Pool** (`browser/pool.ex`) - NimblePool managing headless Chromium instances via Playwright
- **Browser Worker** (`browser/worker.ex`) - GenServer wrapping Node.js process running `scripts/browser-worker.js`
- **Scraper Context** (`scraper.ex`) - URL queue management, domain stats, rate limiting
- **Scrape Worker** (`scraper/scrape_worker.ex`) - Oban job that fetches and parses URLs
- **Ingredient Parser** (`workers/ingredient_parser.ex`) - Background job to parse ingredients in scraped recipes

### Rate Limiting (configurable in config.exs)
- Default: 150 requests/hour, 2500 requests/day per domain
- Polite delays: 3-8 seconds between requests to same domain

### Admin Dashboard
The frontend includes an admin scraping dashboard at `/admin/scraping` for:
- Monitoring browser pool health and queue statistics
- Adding domains with seed URLs
- Viewing per-domain rate limit status
- Pausing/resuming scraping
- Retrying failed URLs
- Triggering ingredient parsing

## Import Feature

Import recipes from Copy Me That using the `/api/import/copymethat` endpoint:

```bash
curl -X POST http://localhost:4000/api/import/copymethat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"recipes": [{"name": "Recipe Title", "ingredients": ["1 cup flour"], ...}]}'
```

Expected JSON format matches Copy Me That export structure.
