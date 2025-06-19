defmodule CrimeToGo.Game.Game do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_states ~w(pre_game active post_game)
  @valid_languages ~w(de en fr es it tr ru uk)

  schema "games" do
    field :invitation_code, :string
    field :start_at, :utc_datetime
    field :end_at, :utc_datetime
    field :state, :string, default: "pre_game"
    field :game_code, :string
    field :lang, :string, default: "en"

    has_many :players, CrimeToGo.Player.Player
    has_many :chat_rooms, CrimeToGo.Chat.ChatRoom

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:invitation_code, :start_at, :end_at, :state, :game_code, :lang])
    |> validate_required([:invitation_code, :game_code, :lang])
    |> validate_length(:invitation_code, max: 20)
    |> validate_length(:game_code, max: 20)
    |> validate_inclusion(:state, @valid_states)
    |> validate_inclusion(:lang, @valid_languages)
    |> unique_constraint(:game_code)
  end

  @doc """
  Returns the list of valid languages for games.
  """
  def valid_languages, do: @valid_languages

  @doc """
  Generates a unique 12-digit game code without 0, 1, and 7
  """
  def generate_game_code do
    # Valid digits: 2, 3, 4, 5, 6, 8, 9
    valid_digits = ~w(2 3 4 5 6 8 9)

    1..12
    |> Enum.map(fn _ -> Enum.random(valid_digits) end)
    |> Enum.join()
  end
end
