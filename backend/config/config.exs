# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :controlcopypasta,
  ecto_repos: [Controlcopypasta.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configure the endpoint
config :controlcopypasta, ControlcopypastaWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: ControlcopypastaWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Controlcopypasta.PubSub,
  live_view: [signing_salt: "q8iUlEc1"]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Guardian JWT configuration
config :controlcopypasta, Controlcopypasta.Accounts.Guardian,
  issuer: "controlcopypasta",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "dev_secret_key_change_in_production"

# Swoosh email configuration (adapter set per environment)
config :controlcopypasta, Controlcopypasta.Mailer,
  adapter: Swoosh.Adapters.Local

# Disable Swoosh API client (we use SMTP adapter in dev)
config :swoosh, :api_client, false

# Frontend URL for magic links
# Set FRONTEND_URL env var to your machine's IP/hostname for LAN access
# e.g., FRONTEND_URL=http://192.168.1.100:5173
config :controlcopypasta, :frontend_url, System.get_env("FRONTEND_URL") || "http://localhost:5173"

# WebAuthn/Passkey configuration
config :controlcopypasta, :webauthn,
  origin: System.get_env("WEBAUTHN_ORIGIN") || "http://localhost:5173",
  rp_id: System.get_env("WEBAUTHN_RP_ID") || "localhost",
  rp_name: "ControlCopyPasta"

# Browser pool configuration for scraping
config :controlcopypasta, :browser_pool_size, 1

# Scraping rate limits per domain (be a good citizen)
# These limits apply independently to each domain
config :controlcopypasta, :scraping,
  # Minimum delay between requests (ms)
  min_delay_ms: 3000,
  # Random additional delay up to this amount (ms)
  max_random_delay_ms: 5000,
  # Maximum pages to scrape per hour per domain
  max_per_hour: 150,
  # Maximum pages to scrape per day per domain
  max_per_day: 2500

# Oban job queue configuration is set in runtime.exs based on environment
# Dev: scraping disabled by default (set ENABLE_SCRAPING=true to enable)
# Prod: scraping enabled by default (set ENABLE_SCRAPING=false to disable)

# FatSecret API rate limiting (free tier: 5,000 calls/month)
config :controlcopypasta, :fatsecret,
  max_per_hour: 150,
  max_per_day: 4000,
  delay_ms: 3000

# Density enrichment rate limiting (uses both FatSecret and USDA)
config :controlcopypasta, :density,
  max_per_hour: 150,
  max_per_day: 4000,
  delay_ms: 3000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
