import Config

# Load .env file from project root (parent directory)
# This makes environment variables available without manual sourcing
if config_env() in [:dev, :test] do
  {:ok, env} = Dotenvy.source(["../.env", ".env", System.get_env()])
  Enum.each(env, fn {key, value} ->
    System.put_env(key, value)
  end)
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/controlcopypasta start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :controlcopypasta, ControlcopypastaWeb.Endpoint, server: true
end

# WebAuthn/Passkey configuration - runtime so env vars are read at startup
if webauthn_origin = System.get_env("WEBAUTHN_ORIGIN") do
  config :controlcopypasta, :webauthn,
    origin: webauthn_origin,
    rp_id: System.get_env("WEBAUTHN_RP_ID") || "localhost",
    rp_name: "ControlCopyPasta"
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :controlcopypasta, Controlcopypasta.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    # For machines with several cores, consider starting multiple pools of `pool_size`
    # pool_count: 4,
    socket_options: maybe_ipv6

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :controlcopypasta, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :controlcopypasta, ControlcopypastaWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: String.to_integer(System.get_env("PORT") || "4000")
    ],
    secret_key_base: secret_key_base

  # Guardian JWT configuration
  guardian_secret =
    System.get_env("GUARDIAN_SECRET_KEY") ||
      raise """
      environment variable GUARDIAN_SECRET_KEY is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :controlcopypasta, Controlcopypasta.Accounts.Guardian,
    issuer: "controlcopypasta",
    secret_key: guardian_secret

  # Frontend URL for magic links
  config :controlcopypasta, :frontend_url,
    System.get_env("FRONTEND_URL") || "https://#{host}"

  # SMTP configuration for production emails
  smtp_host = System.get_env("SMTP_HOST")

  if smtp_host && smtp_host != "" do
    smtp_config = [
      adapter: Swoosh.Adapters.SMTP,
      relay: smtp_host,
      port: String.to_integer(System.get_env("SMTP_PORT") || "587"),
      ssl: System.get_env("SMTP_SSL") == "true",
      tls: :if_available,
      auth: :if_available
    ]

    # Only add auth credentials if username is set (for authenticated SMTP)
    smtp_config =
      case System.get_env("SMTP_USERNAME") do
        nil -> smtp_config
        "" -> smtp_config
        username -> smtp_config ++ [username: username, password: System.get_env("SMTP_PASSWORD")]
      end

    config :controlcopypasta, Controlcopypasta.Mailer, smtp_config
  end

  # Oban configuration - all queues including scraper, fatsecret, density
  scraper_concurrency = String.to_integer(System.get_env("OBAN_SCRAPER_CONCURRENCY") || "1")

  config :controlcopypasta, Oban,
    repo: Controlcopypasta.Repo,
    queues: [scraper: scraper_concurrency, scheduled: 1, fatsecret: 1, density: 1],
    plugins: [
      {Oban.Plugins.Lifeline, rescue_after: :timer.minutes(30)},
      {Oban.Plugins.Cron,
       crontab: [
         {"*/5 * * * *", Controlcopypasta.Workers.ScraperUnpauser},
         {"0 2 * * *", Controlcopypasta.Workers.ImageSeeder},
         {"0 3 * * 0", Controlcopypasta.Workers.UsageCountUpdater}
       ]}
    ]

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :controlcopypasta, ControlcopypastaWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :controlcopypasta, ControlcopypastaWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
