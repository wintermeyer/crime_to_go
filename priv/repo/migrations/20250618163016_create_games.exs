defmodule CrimeToGo.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :invitation_code, :string, size: 20, null: false
      add :start_at, :utc_datetime
      add :end_at, :utc_datetime
      add :state, :string, null: false, default: "pre_game"
      add :game_code, :string, size: 20, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:games, [:game_code])
    create index(:games, [:state])
    create index(:games, [:invitation_code])
  end
end
