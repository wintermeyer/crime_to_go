defmodule CrimeToGo.Game.Game do
  use Ecto.Schema
  import Ecto.Changeset

  alias CrimeToGo.Shared.Constants

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_states Constants.game_states()
  @valid_languages Constants.supported_languages()

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
    |> validate_length(:invitation_code, max: Constants.max_length(:invitation_code))
    |> validate_length(:game_code, max: Constants.max_length(:game_code))
    |> validate_inclusion(:state, @valid_states)
    |> validate_inclusion(:lang, @valid_languages)
    |> unique_constraint(:game_code)
  end

  @doc """
  Returns the list of valid languages for games.
  """
  def valid_languages, do: @valid_languages

  @doc """
  Generates a unique game code with checksum using digits that avoid confusion (no 0, 1, or 7).

  Uses the GameCode module to generate codes with built-in checksum validation.
  """
  def generate_game_code do
    CrimeToGo.Shared.GameCode.generate()
  end

  @doc """
  Validates a game code format and checksum without database lookup.

  ## Examples

      iex> valid_code = CrimeToGo.Game.Game.generate_game_code()
      iex> CrimeToGo.Game.Game.valid_game_code?(valid_code)
      true
      
      iex> CrimeToGo.Game.Game.valid_game_code?("invalid")
      false
  """
  def valid_game_code?(game_code) do
    CrimeToGo.Shared.GameCode.valid?(game_code)
  end
end
