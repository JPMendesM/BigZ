defmodule Bigz.Repo do
  use Ecto.Repo,
    otp_app: :bigz,
    adapter: Ecto.Adapters.Postgres
end
