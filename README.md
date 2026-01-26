# ControlCopyPasta

**Take control of your recipe collection.** A self-hosted recipe manager that lets you own your data, import from existing services, and save recipes from anywhere on the web.

## Why ControlCopyPasta?

### Own Your Recipes Forever
No more worrying about subscription fees, service shutdowns, or corporate data harvesting. Your recipes live on your server, backed by your database, accessible only to you.

### Save Recipes From Any Website
The browser extension (Chrome & Firefox) lets you clip recipes from any cooking site with one click. It intelligently extracts ingredients, instructions, prep times, and images - no more copying and pasting.

### Migrate From Copy Me That
Switching from Copy Me That? Import your entire recipe collection in seconds. Just export your data and upload - all your recipes, tags, and notes come along.

### Smart Recipe Scaling
Cooking for 2 instead of 8? Scale any recipe up or down (0.25x to 4x) with intelligent fraction handling. "1/2 cup" becomes "1/8 cup" - no calculator needed.

### Find Similar Recipes
Discover connections in your collection. ControlCopyPasta analyzes ingredients to suggest similar recipes, helping you find variations or substitutes for dishes you love.

### Compare Recipes Side-by-Side
Have 3 different chocolate chip cookie recipes? Compare them side-by-side to see ingredient overlaps, proportional differences, and what makes each unique.

### Browse By Source
See all recipes from your favorite cooking sites grouped together. Quickly find "all my Serious Eats recipes" or "everything from Bon Appetit."

### Print-Ready
Clean, ink-friendly print layouts that show just what you need in the kitchen - no ads, no navigation, no clutter.

---

## Features

- **Recipe Management** - Create, edit, organize, and archive recipes
- **Browser Extension** - One-click save from any recipe website (Chrome & Firefox)
- **Import/Export** - Migrate from Copy Me That with full data import
- **Tags** - Organize recipes with custom tags
- **Search** - Find recipes by title, ingredients, or tags
- **Recipe Scaling** - Adjust serving sizes with smart fraction math
- **Similar Recipes** - AI-powered recipe similarity matching
- **Recipe Comparison** - Side-by-side ingredient analysis
- **Source Browsing** - Group recipes by origin website
- **Print View** - Kitchen-friendly recipe printouts
- **Passwordless Auth** - Secure magic link login (no passwords to remember)
- **Mobile Responsive** - Works on phone, tablet, or desktop
- **Docker Deployment** - One-command setup with Docker Compose

---

## Quick Start

### Prerequisites
- Docker and Docker Compose
- SMTP server for magic link emails (or use a service like Mailgun, SendGrid, etc.)

### Deploy with Docker Compose

1. Clone the repository:
   ```bash
   git clone https://github.com/deanmarano/controlcopypasta.git
   cd controlcopypasta
   ```

2. Copy and configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env with your settings (see Configuration below)
   ```

3. Generate secrets:
   ```bash
   # Generate two unique secrets for these .env values:
   docker run --rm elixir:1.16 mix phx.gen.secret
   ```

4. Start the application:
   ```bash
   docker compose -f docker-compose.prod.yml up -d
   ```

5. Access your instance at `http://localhost` (or your configured domain)

### Configuration

Edit your `.env` file with the following:

```bash
# Required
POSTGRES_PASSWORD=your_secure_database_password
SECRET_KEY_BASE=your_generated_secret_1
GUARDIAN_SECRET_KEY=your_generated_secret_2

# Your domain (for links in emails)
PHX_HOST=recipes.yourdomain.com
VITE_API_URL=https://recipes.yourdomain.com/api

# Email (required for magic link login)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
```

---

## Browser Extension

Save recipes directly from any cooking website.

### Installation

**Chrome:**
1. Download the extension from `extension/`
2. Go to `chrome://extensions/`
3. Enable "Developer mode"
4. Click "Load unpacked" and select the `extension/` folder
5. Configure the extension with your server URL

**Firefox:**
1. Go to `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on"
3. Select `extension/manifest.firefox.json`
4. Configure the extension with your server URL

### Usage

1. Navigate to any recipe page
2. Click the ControlCopyPasta extension icon
3. Review the extracted recipe
4. Click "Save" to add it to your collection

The extension uses Schema.org JSON-LD data when available, with fallback scrapers for popular recipe sites.

---

## Importing From Copy Me That

1. In Copy Me That, export your recipes (Settings > Export)
2. In ControlCopyPasta, go to Settings > Import
3. Upload your Copy Me That JSON export
4. All recipes, including tags and notes, will be imported

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| Backend | Elixir + Phoenix |
| Frontend | SvelteKit |
| Database | PostgreSQL |
| Auth | Magic Link + JWT |
| Extension | WebExtension API |
| Deployment | Docker Compose |

---

## Development

### Prerequisites
- Elixir 1.16+
- Node.js 20+
- PostgreSQL 16+ (or use Docker)

### Setup

```bash
# Start database
docker compose up -d

# Backend setup (from backend/)
cd backend
mix deps.get
mix ecto.setup
mix phx.server  # Runs on localhost:4000

# Frontend setup (from frontend/)
cd frontend
npm install
npm run dev  # Runs on localhost:5173
```

### Running Tests

```bash
# Backend tests
cd backend && mix test

# Frontend tests
cd frontend && npm run test
```

---

## License

MIT

---

## Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.
