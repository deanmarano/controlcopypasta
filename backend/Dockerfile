# Build stage
FROM hexpm/elixir:1.18.4-erlang-27.2-debian-bookworm-20250113-slim AS build

# Install build dependencies
RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV=prod

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy application code
COPY priv priv
COPY lib lib

# Compile the release
RUN mix compile

# Copy runtime config
COPY config/runtime.exs config/

# Build the release
RUN mix release

# Runtime stage
FROM debian:bookworm-slim AS runtime

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR /app

# Create a non-privileged user to run the app
RUN useradd -ms /bin/bash app
USER app

# Copy the release from the build stage
COPY --from=build --chown=app:app /app/_build/prod/rel/controlcopypasta ./

ENV HOME=/app
ENV PHX_SERVER=true

EXPOSE 4000

CMD ["bin/controlcopypasta", "start"]
