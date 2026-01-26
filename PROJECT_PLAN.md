# ControlCopyPasta - Project Plan

## Goals

Build a self-hosted, modern recipe management app that replicates the core "My Recipes" functionality of Copy Me That:

1. **Recipe Storage** - Save recipes with ingredients, instructions, images, source URL
2. **Recipe Import** - Browser extension to extract recipes from websites
3. **Recipe Organization** - Tags, search, filtering
4. **Recipe Editing** - Modify saved recipes
5. **Data Migration** - Import existing recipes from Copy Me That

---

## Finalized Tech Stack

| Component | Choice |
|-----------|--------|
| Backend | Elixir + Phoenix |
| Frontend | SvelteKit |
| Database | PostgreSQL with JSONB |
| ORM | Ecto |
| Auth | Guardian (JWT) + Magic Link (alpha) |
| Email (Dev) | Mailhog (SMTP interception) |
| Recipe Parsing | Hybrid (JSON-LD + custom scrapers) |
| Browser Extension | WebExtension API (Chrome + Firefox) |
| Deployment | Docker Compose |

---

## Database Schema

### Recipes Table

```sql
CREATE TABLE recipes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  source_url TEXT,
  source_domain VARCHAR(255),
  image_url TEXT,
  ingredients JSONB DEFAULT '[]',
  instructions JSONB DEFAULT '[]',
  prep_time_minutes INTEGER,
  cook_time_minutes INTEGER,
  total_time_minutes INTEGER,
  servings VARCHAR(50),
  notes TEXT,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### Tags Table

```sql
CREATE TABLE tags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE recipe_tags (
  recipe_id UUID REFERENCES recipes(id) ON DELETE CASCADE,
  tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (recipe_id, tag_id)
);
```

### Users Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) NOT NULL UNIQUE,
  inserted_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Post-alpha: add password_hash column for email/password auth
-- Post-alpha: add passkeys table for WebAuthn
-- Post-alpha: add user_identities table for OAuth
```

### JSONB Structure Examples

**Ingredients**:
```json
[
  {"text": "2 cups flour", "group": null},
  {"text": "1 tsp salt", "group": null},
  {"text": "1 cup butter, softened", "group": "For the frosting"}
]
```

**Instructions**:
```json
[
  {"step": 1, "text": "Preheat oven to 350°F"},
  {"step": 2, "text": "Mix dry ingredients in a large bowl"},
  {"step": 3, "text": "Add wet ingredients and stir until combined"}
]
```

---

## Project Structure

```
controlcopypasta/
├── backend/                 # Phoenix app
│   ├── lib/
│   │   ├── controlcopypasta/
│   │   │   ├── recipes/     # Recipe context
│   │   │   ├── accounts/    # User/auth context
│   │   │   └── parser/      # Recipe parsing logic
│   │   └── controlcopypasta_web/
│   │       ├── controllers/
│   │       └── router.ex
│   ├── priv/repo/migrations/
│   └── mix.exs
├── frontend/                # SvelteKit app
│   ├── src/
│   │   ├── routes/
│   │   ├── lib/
│   │   └── app.html
│   ├── package.json
│   └── svelte.config.js
├── extension/               # Browser extension
│   ├── manifest.json
│   ├── popup/
│   ├── content/
│   └── background/
├── docker-compose.yml
├── CLAUDE.md
├── PROJECT_PLAN.md
└── .env
```

---

## Implementation Phases

### Phase 1: Core Backend
- [ ] Initialize Phoenix project with API mode
- [ ] Set up Ecto with PostgreSQL
- [ ] Create recipe schema and migrations
- [ ] Build REST API endpoints (CRUD for recipes)
- [ ] Add JSON-LD recipe parser
- [ ] Add custom scrapers for common sites

### Phase 2: Authentication (Alpha - Magic Link Only)
- [ ] Create user schema and migrations
- [ ] Set up Guardian for JWT token generation/validation
- [ ] Implement magic link auth with Phoenix.Token
- [ ] Set up Swoosh for email sending (Mailhog in dev)
- [ ] Create auth controller (magic link request, verify, logout)
- [ ] Add authentication plug to protect API endpoints
- [ ] Token refresh mechanism

### Phase 3: Web Frontend
- [ ] Initialize SvelteKit project
- [ ] Set up API client for Phoenix backend
- [ ] Recipe list view with search/filter
- [ ] Recipe detail view
- [ ] Recipe editor (create/edit)
- [ ] Tag management
- [ ] Login/logout UI

### Phase 4: Browser Extension
- [ ] Set up WebExtension structure
- [ ] Content script to detect recipes on pages
- [ ] Popup UI to preview and save
- [ ] API integration with backend
- [ ] Handle authentication in extension

### Phase 5: Data Migration
- [ ] Research Copy Me That export options
- [ ] Build scraper/exporter for CMT account
- [ ] Create import endpoint in Phoenix
- [ ] Bulk import tool

### Phase 6: Auth Enhancements
- [ ] Passkeys with Wax (WebAuthn)
- [ ] Email/password with Bcrypt
- [ ] OAuth with Ueberauth (Google, GitHub)

### Phase 7: Polish & Deployment
- [ ] Docker Compose setup
- [ ] Image upload/storage
- [ ] Mobile-responsive design
- [ ] Print-friendly recipe view
- [ ] Recipe scaling feature

---

## API Endpoints

### Recipes
- `GET /api/recipes` - List all recipes (with pagination, search, tag filter)
- `GET /api/recipes/:id` - Get single recipe
- `POST /api/recipes` - Create recipe
- `PUT /api/recipes/:id` - Update recipe
- `DELETE /api/recipes/:id` - Delete recipe
- `POST /api/recipes/parse` - Parse recipe from URL

### Tags
- `GET /api/tags` - List all tags
- `POST /api/tags` - Create tag
- `DELETE /api/tags/:id` - Delete tag

### Auth (Alpha)
- `POST /api/auth/magic-link` - Request magic link email
- `POST /api/auth/magic-link/verify` - Verify token, returns JWT
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - Logout (invalidate token)
- `GET /api/auth/me` - Get current user

### Auth (Post-Alpha)
- `POST /api/auth/register` - Email/password registration
- `POST /api/auth/login` - Email/password login
- `POST /api/auth/passkey/*` - Passkey endpoints

---

## Next Steps

1. Initialize the Phoenix backend project
2. Set up PostgreSQL with Docker
3. Create the initial database schema
4. Build the first API endpoints
