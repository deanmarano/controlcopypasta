# Build frontend
FROM node:22-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
ARG VITE_API_URL=/api
RUN npm run build

# Build scripts (browser worker with Playwright)
FROM node:22-slim AS scripts-builder
WORKDIR /app/scripts
COPY scripts/package*.json ./
RUN npm ci
COPY scripts/*.js ./
# Install Playwright Chromium browser
RUN npx playwright install chromium

# Build backend
FROM hexpm/elixir:1.18.2-erlang-27.2-debian-bookworm-20250113-slim AS backend-builder
RUN apt-get update && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV MIX_ENV=prod
COPY backend/mix.exs backend/mix.lock ./
RUN mix local.hex --force && mix local.rebar --force && mix deps.get --only prod
COPY backend/config config/
COPY backend/lib lib/
COPY backend/priv priv/
RUN mix compile && mix release

# Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates nginx \
  curl \
  # Playwright Chromium dependencies
  libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 libdbus-1-3 \
  libxkbcommon0 libatspi2.0-0 libxcomposite1 libxdamage1 libxfixes3 libxrandr2 \
  libgbm1 libasound2 libpango-1.0-0 libcairo2 \
  && rm -rf /var/lib/apt/lists/* \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Install Node.js for browser worker
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN useradd -m app && chown -R app:app /app

# Copy backend release
COPY --from=backend-builder --chown=app:app /app/_build/prod/rel/controlcopypasta ./backend/

# Copy frontend build
COPY --from=frontend-builder /app/frontend/build /var/www/html

# Copy scripts and Playwright browsers
COPY --from=scripts-builder --chown=app:app /app/scripts ./scripts/
COPY --from=scripts-builder --chown=app:app /root/.cache/ms-playwright /home/app/.cache/ms-playwright
ENV PLAYWRIGHT_BROWSERS_PATH=/home/app/.cache/ms-playwright

# Nginx config for frontend + API proxy
COPY deploy/nginx.conf /etc/nginx/nginx.conf

ENV PHX_SERVER=true
EXPOSE 5000

# Start script that runs both nginx and Phoenix
COPY deploy/start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
