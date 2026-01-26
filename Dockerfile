# Build frontend
FROM node:22-slim AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
ARG VITE_API_URL=/api
RUN npm run build

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
  && rm -rf /var/lib/apt/lists/* \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
WORKDIR /app
RUN useradd -m app && chown -R app:app /app

# Copy backend release
COPY --from=backend-builder --chown=app:app /app/_build/prod/rel/controlcopypasta ./backend/

# Copy frontend build
COPY --from=frontend-builder /app/frontend/build /var/www/html

# Nginx config for frontend + API proxy
COPY deploy/nginx.conf /etc/nginx/nginx.conf

ENV PHX_SERVER=true
EXPOSE 5000

# Start script that runs both nginx and Phoenix
COPY deploy/start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
