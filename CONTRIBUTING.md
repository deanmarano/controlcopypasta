# Contributing to ControlCopyPasta

Thanks for your interest in contributing! This guide covers how to get set up and submit changes.

## Getting Started

1. Fork the repository and clone your fork
2. Follow the [Development Setup](README.md#development-setup) instructions in the README
3. Create a branch for your work: `git checkout -b my-feature`

## Development Environment

### Prerequisites

- Elixir 1.18+ (with Erlang/OTP 27)
- Node.js 22+
- Docker (for PostgreSQL and Mailhog)

### Running Locally

```bash
# Start infrastructure
docker compose up -d

# Backend (from backend/)
cd backend
mix deps.get
mix ecto.setup
mix phx.server    # http://localhost:4000

# Frontend (from frontend/)
cd frontend
npm install
npm run dev       # http://localhost:5173
```

Or use `overmind start -f Procfile.dev` to run everything at once.

### Running Tests

```bash
# Backend
cd backend && mix test

# Frontend
cd frontend && npm run test
```

## Submitting Changes

1. Make sure tests pass before submitting
2. Keep commits focused -- one logical change per commit
3. Open a pull request against `main` with a clear description of what changed and why

## Project Structure

- `backend/` -- Elixir/Phoenix JSON API
- `frontend/` -- SvelteKit SPA
- `extension/` -- Browser extension (Chrome + Firefox)

See `CLAUDE.md` for detailed architecture notes and API routes.

## Code Style

- **Backend**: Follow standard Elixir conventions. Run `mix format` before committing.
- **Frontend**: TypeScript with Svelte 5 runes (`$state`, `$derived`, `$effect`). Run `npx svelte-check` to catch type errors.

## Reporting Issues

Open an issue on GitHub with steps to reproduce. Include your environment (OS, Elixir version, Node version) if relevant.

## License

By contributing, you agree that your contributions will be licensed under the [AGPL-3.0](LICENSE).
