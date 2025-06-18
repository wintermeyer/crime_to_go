defmodule CrimeToGo.Repo.Migrations.CreateChatRooms do
  use Ecto.Migration

  def change do
    create table(:chat_rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, size: 100, null: false
      add :room_type, :string, null: false
      add :game_id, references(:games, type: :binary_id, on_delete: :delete_all), null: false
      add :created_by, references(:players, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:chat_rooms, [:game_id])
    create index(:chat_rooms, [:created_by])
    create index(:chat_rooms, [:room_type])
    create unique_index(:chat_rooms, [:game_id, :name])
  end
end
