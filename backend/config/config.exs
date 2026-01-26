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

# Scraping rate limits (be a good citizen)
# Target: ~50k pages/month = ~1,700/day = ~70/hour
config :controlcopypasta, :scraping,
  # Minimum delay between requests (ms)
  min_delay_ms: 3000,
  # Random additional delay up to this amount (ms)
  max_random_delay_ms: 5000,
  # Maximum pages to scrape per hour (pauses queue when exceeded)
  max_per_hour: 75,
  # Maximum pages to scrape per day (pauses queue when exceeded)
  max_per_day: 1700

# Oban job queue configuration
config :controlcopypasta, Oban,
  repo: Controlcopypasta.Repo,
  # Only 1 concurrent scraper to reduce bandwidth/rate
  queues: [scraper: 1, scheduled: 1],
  plugins: [
    # Rate limit scraper to ~75/hour (1 job per 48 seconds)
    {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)},
    # Run scheduled jobs via cron
    {Oban.Plugins.Cron,
     crontab: [
       # Check if scraper can be resumed every 5 minutes
       {"*/5 * * * *", Controlcopypasta.Workers.ScraperUnpauser},
       # Seed ingredient images daily at 2 AM UTC
       {"0 2 * * *", Controlcopypasta.Workers.ImageSeeder},
       # Update ingredient usage counts weekly on Sunday at 3 AM UTC
       {"0 3 * * 0", Controlcopypasta.Workers.UsageCountUpdater}
     ]}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
