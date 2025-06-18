defmodule CrimeToGo.Chat.ChatMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "chat_messages" do
    field :content, :string
    field :deleted_at, :utc_datetime

    belongs_to :chat_room, CrimeToGo.Chat.ChatRoom
    belongs_to :player, CrimeToGo.Player.Player

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:content, :deleted_at, :chat_room_id, :player_id])
    |> validate_required([:content, :chat_room_id, :player_id])
    |> validate_length(:content, max: 1000)
    |> foreign_key_constraint(:chat_room_id)
    |> foreign_key_constraint(:player_id)
  end

  @doc """
  Soft deletes a message by setting the deleted_at timestamp
  """
  def soft_delete(chat_message) do
    changeset(chat_message, %{deleted_at: DateTime.utc_now()})
  end

  @doc """
  Checks if a message is deleted
  """
  def deleted?(chat_message) do
    not is_nil(chat_message.deleted_at)
  end
end
