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
    field :status, :string, default: "offline"
    field :last_seen_at, :utc_datetime

    belongs_to :game, CrimeToGo.Game.Game
    has_many :chat_messages, CrimeToGo.Chat.ChatMessage
    has_many :chat_room_members, CrimeToGo.Chat.ChatRoomMember
    has_many :created_chat_rooms, CrimeToGo.Chat.ChatRoom, foreign_key: :created_by

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [
      :game_host,
      :is_robot,
      :nickname,
      :avatar_file_name,
      :game_id,
      :status,
      :last_seen_at
    ])
    |> validate_required([:nickname, :avatar_file_name, :game_id])
    |> validate_length(:avatar_file_name, max: Constants.max_length(:avatar_file_name))
    |> validate_inclusion(:status, ["online", "offline", "kicked"])
    |> Validations.validate_not_blank(:nickname)
    |> Validations.validate_nickname_format(:nickname)
    |> Validations.validate_unique_nickname_in_game()
    |> unique_constraint(:avatar_file_name, name: :players_game_id_avatar_file_name_index)
    |> foreign_key_constraint(:game_id)
  end

  @doc """
  Status changeset for updating only status and last_seen_at
  """
  def status_changeset(player, attrs) do
    player
    |> cast(attrs, [:status, :last_seen_at])
    |> validate_inclusion(:status, ["online", "offline", "kicked"])
  end
end
