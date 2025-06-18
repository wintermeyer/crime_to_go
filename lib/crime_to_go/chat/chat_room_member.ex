defmodule CrimeToGo.Chat.ChatRoomMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "chat_room_members" do
    field :joined_at, :utc_datetime

    belongs_to :chat_room, CrimeToGo.Chat.ChatRoom
    belongs_to :player, CrimeToGo.Player.Player

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_room_member, attrs) do
    chat_room_member
    |> cast(attrs, [:joined_at, :chat_room_id, :player_id])
    |> validate_required([:chat_room_id, :player_id])
    |> put_joined_at()
    |> unique_constraint(:player_id, name: :chat_room_members_chat_room_id_player_id_index)
    |> foreign_key_constraint(:chat_room_id)
    |> foreign_key_constraint(:player_id)
  end

  defp put_joined_at(changeset) do
    case get_change(changeset, :joined_at) do
      nil -> put_change(changeset, :joined_at, DateTime.utc_now() |> DateTime.truncate(:second))
      _ -> changeset
    end
  end
end
