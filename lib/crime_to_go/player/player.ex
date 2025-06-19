defmodule CrimeToGo.Player.Player do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias CrimeToGo.Shared.{Constants, Validations}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "players" do
    field :game_host, :boolean, default: false
    field :is_robot, :boolean, default: false
    field :nickname, :string
    field :avatar_file_name, :string

    belongs_to :game, CrimeToGo.Game.Game
    has_many :chat_messages, CrimeToGo.Chat.ChatMessage
    has_many :chat_room_members, CrimeToGo.Chat.ChatRoomMember
    has_many :created_chat_rooms, CrimeToGo.Chat.ChatRoom, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:game_host, :is_robot, :nickname, :avatar_file_name, :game_id])
    |> validate_required([:nickname, :avatar_file_name, :game_id])
    |> validate_length(:nickname, max: Constants.max_length(:nickname))
    |> validate_length(:avatar_file_name, max: Constants.max_length(:avatar_file_name))
    |> Validations.validate_not_blank(:nickname)
    |> Validations.validate_safe_text(:nickname)
    |> unique_constraint(:nickname, name: :players_game_id_nickname_index)
    |> unique_constraint(:avatar_file_name, name: :players_game_id_avatar_file_name_index)
    |> foreign_key_constraint(:game_id)
  end
end
