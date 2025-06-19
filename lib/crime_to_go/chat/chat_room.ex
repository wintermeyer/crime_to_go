defmodule CrimeToGo.Chat.ChatRoom do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias CrimeToGo.Shared.{Constants, Validations}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_room_types Constants.chat_room_types()

  schema "chat_rooms" do
    field :name, :string
    field :room_type, :string

    belongs_to :game, CrimeToGo.Game.Game
    belongs_to :creator, CrimeToGo.Player.Player, foreign_key: :created_by

    has_many :chat_messages, CrimeToGo.Chat.ChatMessage
    has_many :chat_room_members, CrimeToGo.Chat.ChatRoomMember

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(chat_room, attrs) do
    chat_room
    |> cast(attrs, [:name, :room_type, :game_id, :created_by])
    |> validate_required([:name, :room_type, :game_id])
    |> validate_length(:name, max: Constants.max_length(:chat_room_name))
    |> Validations.validate_not_blank(:name)
    |> Validations.validate_safe_text(:name)
    |> validate_inclusion(:room_type, @valid_room_types)
    |> unique_constraint(:name, name: :chat_rooms_game_id_name_index)
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:created_by)
  end
end
