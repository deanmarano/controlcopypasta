defmodule Controlcopypasta.Repo do
  use Ecto.Repo,
    otp_app: :controlcopypasta,
    adapter: Ecto.Adapters.Postgres
end
