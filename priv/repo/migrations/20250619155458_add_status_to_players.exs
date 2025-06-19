defmodule CrimeToGo.Repo.Migrations.AddStatusToPlayers do
  use Ecto.Migration

  def change do
    alter table(:players) do
      add :status, :string, default: "offline", null: false
      add :last_seen_at, :utc_datetime
    end

    create index(:players, [:status])
  end
end
