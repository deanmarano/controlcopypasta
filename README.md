# ControlCopyPasta

**Take control of your recipe collection.** A self-hosted recipe manager that lets you own your data, import from existing services, and save recipes from anywhere on the web.

## Why ControlCopyPasta?

- **Own your recipes forever** - No subscriptions, no shutdowns, no data harvesting. Your recipes live on your server.
- **Save from any website** - Browser extension (Chrome & Firefox) clips recipes with one click, extracting ingredients, instructions, and images.
- **Import from Copy Me That** - Migrate your entire collection in seconds.
- **Smart scaling** - Cook for 2 instead of 8. Scale any recipe 0.25x-4x with intelligent fraction handling.
- **Nutrition info** - Per-recipe nutrition breakdown with ingredient-level detail.
- **Find similar recipes** - Discover connections in your collection based on shared ingredients.
- **Compare side-by-side** - See what makes your three chocolate chip cookie recipes different.
- **Browse by source** - Group recipes by origin website.
- **Shopping lists** - Build shopping lists from recipes with automatic ingredient grouping.
- **Print-ready** - Clean layouts for the kitchen, no ads or clutter.

## Quick Start (Docker)

The fastest way to run ControlCopyPasta:

```bash
git clone https://github.com/deanmarano/controlcopypasta.git
cd controlcopypasta
cp .env.example .env
```

Edit `.env` with your settings (see [Configuration](#configuration)), then:

```bash
docker compose -f docker-compose.prod.yml up -d
```

Access your instance at `http://localhost`.

### Configuration

At minimum, generate two secrets and set a database password in `.env`:

```bash
# Generate secrets (run twice, one for each key)
docker run --rm elixir:1.18 mix phx.gen.secret

# Required in .env:
SECRET_KEY_BASE=<first generated secret>
GUARDIAN_SECRET_KEY=<second generated secret>
POSTGRES_PASSWORD=<a secure password>

# For magic link login to work, configure SMTP:
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your-username
SMTP_PASSWORD=your-password
```

See `.env.example` for all available options.

## Development Setup

### Prerequisites

- [Elixir](https://elixir-lang.org/install.html) 1.18+ (with Erlang/OTP 27)
- [Node.js](https://nodejs.org/) 22+
- [Docker](https://www.docker.com/) (for PostgreSQL and Mailhog)
- Optional: [overmind](https://github.com/DarthSim/overmind) or [foreman](https://github.com/ddollar/foreman) for process management

### Option A: All-in-one with Overmind

```bash
# Start everything (Postgres, Mailhog, backend, frontend)
overmind start -f Procfile.dev
```

Then run database setup once in another terminal:

```bash
cd backend && mix ecto.setup
```

### Option B: Start services individually

```bash
# 1. Start Postgres (dev on port 5434, test on 5433) and Mailhog
docker compose up -d

# 2. Backend (from backend/)
cd backend
mix deps.get
mix ecto.setup    # Creates DB, runs migrations, seeds data
mix phx.server    # Starts on localhost:4000

# 3. Frontend (from frontend/, in another terminal)
cd frontend
npm install
npm run dev       # Starts on localhost:5173
```

### Dev Services

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:5173 | SvelteKit dev server |
| Backend API | http://localhost:4000/api | Phoenix JSON API |
| Mailhog | http://localhost:8025 | Catches all dev emails (magic links) |

No `.env` file is needed for local development - all config has sensible defaults.

### Running Tests

```bash
# Backend (from backend/)
cd backend && mix test

# Frontend (from frontend/)
cd frontend && npm run test
```

## Browser Extension

Save recipes from any cooking website with one click.

**Chrome:**
1. Go to `chrome://extensions/`, enable Developer Mode
2. Click "Load unpacked", select the `extension/` folder
3. Configure with your server URL

**Firefox:**
1. Go to `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on", select `extension/manifest.firefox.json`
3. Configure with your server URL

## Importing From Copy Me That

1. In Copy Me That, export your recipes (Settings > Export)
2. In ControlCopyPasta, go to Settings > Import
3. Upload your Copy Me That JSON export

## Architecture

```
controlcopypasta/
  backend/          Elixir/Phoenix JSON API
    lib/            Business logic + web controllers
    priv/           Migrations + seed data
    test/           ExUnit tests
  frontend/         SvelteKit SPA
    src/lib/        API client, stores, utilities
    src/routes/     Pages (recipes, browse, admin, auth)
  extension/        Browser extension (Chrome + Firefox)
  deploy/           Nginx config + startup script
  Dockerfile        Production multi-stage build
```

## Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | Elixir / Phoenix |
| Frontend | SvelteKit |
| Database | PostgreSQL |
| Auth | Magic Link + JWT (Guardian) |
| Extension | WebExtension API |
| Deployment | Docker / Docker Compose |

## License

[AGPL-3.0](LICENSE)
