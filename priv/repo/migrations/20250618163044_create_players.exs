defmodule CrimeToGo.Repo.Migrations.CreatePlayers do
  use Ecto.Migration

  def change do
    create table(:players, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :game_host, :boolean, default: false, null: false
      add :is_robot, :boolean, default: false, null: false
      add :nickname, :string, size: 140, null: false
      add :avatar_file_name, :string, size: 255, null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:players, [:game_id])
    create unique_index(:players, [:game_id, :nickname])
    create unique_index(:players, [:game_id, :avatar_file_name])
  end
end
