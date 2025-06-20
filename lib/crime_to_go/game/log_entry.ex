defmodule CrimeToGo.Game.LogEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "log_entries" do
    field :event, :string
    field :player_nickname, :string
    field :actor_nickname, :string
    field :details, :string

    belongs_to :game, CrimeToGo.Game.Game
    belongs_to :player, CrimeToGo.Player.Player
    belongs_to :actor, CrimeToGo.Player.Player

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(log_entry, attrs) do
    log_entry
    |> cast(attrs, [:event, :player_nickname, :actor_nickname, :details, :game_id, :player_id, :actor_id])
    |> validate_required([:event, :game_id])
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:player_id)
    |> foreign_key_constraint(:actor_id)
  end
end
