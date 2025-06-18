defmodule CrimeToGo.Repo.Migrations.CreateChatRoomMembers do
  use Ecto.Migration

  def change do
    create table(:chat_room_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :joined_at, :utc_datetime, null: false, default: fragment("NOW()")

      add :chat_room_id, references(:chat_rooms, type: :binary_id, on_delete: :delete_all),
        null: false

      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_room_members, [:chat_room_id])
    create index(:chat_room_members, [:player_id])
    create unique_index(:chat_room_members, [:chat_room_id, :player_id])
  end
end
