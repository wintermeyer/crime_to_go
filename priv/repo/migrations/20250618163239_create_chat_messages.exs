defmodule CrimeToGo.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :content, :text, null: false
      add :deleted_at, :utc_datetime

      add :chat_room_id, references(:chat_rooms, type: :binary_id, on_delete: :delete_all),
        null: false

      add :player_id, references(:players, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:chat_messages, [:chat_room_id])
    create index(:chat_messages, [:player_id])
    create index(:chat_messages, [:deleted_at])
    create index(:chat_messages, [:inserted_at])
  end
end
