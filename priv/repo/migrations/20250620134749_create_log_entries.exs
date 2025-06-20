defmodule CrimeToGo.Repo.Migrations.CreateLogEntries do
  use Ecto.Migration

  def change do
    create table(:log_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event, :string, null: false
      add :player_nickname, :string
      add :actor_nickname, :string
      add :details, :text
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :player_id, references(:players, type: :binary_id, on_delete: :nilify_all)
      add :actor_id, references(:players, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:log_entries, [:game_id])
    create index(:log_entries, [:player_id])
    create index(:log_entries, [:actor_id])
    create index(:log_entries, [:inserted_at])
  end
end
