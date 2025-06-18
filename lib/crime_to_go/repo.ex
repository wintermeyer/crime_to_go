defmodule CrimeToGo.Repo do
  use Ecto.Repo,
    otp_app: :crime_to_go,
    adapter: Ecto.Adapters.Postgres
end
