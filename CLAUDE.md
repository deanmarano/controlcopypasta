# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Summary

ControlCopyPasta is a self-hosted recipe management app with a Phoenix (Elixir) backend, SvelteKit frontend, and browser extension. PostgreSQL with JSONB for storing ingredients/instructions. Parse recipes from any URL, manage your collection, calculate nutrition, and create shopping lists.

## Commands

```bash
# Start everything with Procfile (recommended)
overmind start -f Procfile.dev   # Or: foreman start -f Procfile.dev

# Or start services individually:

# Start infrastructure (PostgreSQL + Mailhog)
docker compose up -d   # Dev postgres on 5434, test on 5433, Mailhog on 8025

# Backend (Phoenix) - run from backend/
mix deps.get
mix ecto.setup        # Create DB + run migrations + seed data
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
    - `recipes/` - Recipe CRUD, domain browsing, similarity
    - `accounts/` - User accounts, preferences, avoided ingredients
    - `parser/` - Recipe URL parsing (JSON-LD + custom scrapers)
    - `import/` - Recipe import from external formats
    - `ingredients/` - Canonical ingredient catalog, matching, nutrition
    - `nutrition/` - Nutrition calculator with range propagation
  - `lib/controlcopypasta_web/` - Controllers, router, plugs
    - `controllers/admin/` - Admin-only endpoints (ingredient management)
  - `test/` - ExUnit tests
- **frontend/** - SvelteKit SPA consuming the Phoenix API
  - `src/lib/` - API client, stores, utilities
  - `src/routes/` - Pages (recipes, tags, auth, admin)
  - Vitest tests for API client and auth store
- **extension/** - Browser extension (WebExtension API for Chrome/Firefox)
  - `manifest.chrome.json` - Chrome Manifest V3
  - `manifest.firefox.json` - Firefox Manifest V2

## Key Technical Decisions

- **Auth (Alpha)**: Magic link only via Phoenix.Token + Guardian JWTs. No passwords initially.
- **Recipe data**: Ingredients and instructions stored as JSONB arrays (see PROJECT_PLAN.md for structure)
- **Recipe parsing**: Hybrid approach - Schema.org JSON-LD first, custom scrapers as fallback
- **Recipe scaling**: Frontend supports scaling ingredient quantities (0.25x to 4x)
- **Nutrition**: Per-recipe nutrition with range propagation (min/best/max per nutrient)
- **Print view**: Print-friendly CSS for recipe detail pages
- **Email (dev)**: Mailhog captures all emails at http://localhost:8025
- **Seed data**: Canonical ingredients, densities, and nutrition data loaded via `mix ecto.setup`

## Environment Variables

Store in `.env` (not committed). See `.env.example` for full list:
- `DATABASE_URL` - Default: `postgres://postgres:postgres@localhost/controlcopypasta_dev`
- `SECRET_KEY_BASE` - Phoenix secret (generate with `mix phx.gen.secret`)
- `GUARDIAN_SECRET_KEY` - JWT signing (generate with `mix phx.gen.secret`)
- `SMTP_HOST`/`SMTP_PORT` - Dev: `localhost:1025` (Mailhog)
- `FRONTEND_URL` - URL for magic link emails (default: http://localhost:5173)
- `ADMIN_EMAILS` - Comma-separated list of admin email addresses

## API Routes

Key patterns:
- `/api/recipes` - Recipe CRUD
- `/api/recipes/parse` - Parse recipe from URL
- `/api/recipes/:id/nutrition` - Recipe nutrition data
- `/api/tags` - Tag management
- `/api/auth/*` - Authentication (magic-link, verify, refresh, logout, me)
- `/api/import/copymethat` - Import recipes from Copy Me That JSON export
- `/api/browse/domains` - Browse recipes by source domain
- `/api/ingredients` - Ingredient catalog and scaling
- `/api/shopping-lists` - Shopping list management

### Admin Routes (require admin role)
- `/admin/ingredients` - Manage canonical ingredients (categories, allergens, matching rules)
- `/admin/preparations` - Manage preparation words (dice, chop, mince)
- `/admin/kitchen-tools` - Manage kitchen tools
- `/admin/pending-ingredients` - Review unmatched ingredients

## Import Feature

Import recipes from Copy Me That using the `/api/import/copymethat` endpoint:

```bash
curl -X POST http://localhost:4000/api/import/copymethat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"recipes": [{"name": "Recipe Title", "ingredients": ["1 cup flour"], ...}]}'
```

Expected JSON format matches Copy Me That export structure.
