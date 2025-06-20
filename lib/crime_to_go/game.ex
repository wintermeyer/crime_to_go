defmodule CrimeToGo.Game do
  @moduledoc """
  The Game context.

  This context manages game-related operations including creation, state management,
  and player interactions. It provides the main business logic for game lifecycle.
  """

  import Ecto.Query, warn: false
  alias CrimeToGo.Repo
  alias CrimeToGo.Shared

  alias CrimeToGo.Game.Game
  alias CrimeToGo.Game.LogEntry

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
  @spec list_games() :: [Game.t()]
  def list_games do
    Repo.all(Game)
  end

  @doc """
  Gets a single game.

  Raises `Ecto.NoResultsError` if the Game does not exist.

  ## Examples

      iex> get_game!(123)
      %Game{}

      iex> get_game!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  @spec get_game!(binary()) :: Game.t()
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Gets a game by game code.

  ## Examples

      iex> get_game_by_code("123456789012")
      %Game{}

      iex> get_game_by_code("nonexistent")
      nil

  """
  @spec get_game_by_code(String.t()) :: Game.t() | nil
  def get_game_by_code(game_code) do
    Repo.get_by(Game, game_code: game_code)
  end

  @doc """
  Creates a game with a unique game code.

  ## Examples

      iex> create_game(%{field: value})
      {:ok, %Game{}}

      iex> create_game(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_game(map()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def create_game(attrs \\ %{}) do
    game_code = generate_unique_game_code()

    attrs_with_code =
      attrs
      |> Shared.normalize_attrs()
      |> Map.put("game_code", game_code)
      |> Map.put_new("invitation_code", game_code)

    %Game{}
    |> Game.changeset(attrs_with_code)
    |> Repo.insert()
  end

  @doc """
  Updates a game.

  ## Examples

      iex> update_game(game, %{field: new_value})
      {:ok, %Game{}}

      iex> update_game(game, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec update_game(Game.t(), map()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def update_game(%Game{} = game, attrs) do
    game
    |> Game.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a game.

  ## Examples

      iex> delete_game(game)
      {:ok, %Game{}}

      iex> delete_game(game)
      {:error, %Ecto.Changeset{}}

  """
  @spec delete_game(Game.t()) :: {:ok, Game.t()} | {:error, Ecto.Changeset.t()}
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
  @spec change_game(Game.t(), map()) :: Ecto.Changeset.t()
  def change_game(%Game{} = game, attrs \\ %{}) do
    Game.changeset(game, attrs)
  end

  @doc """
  Starts a game by changing its state from pre_game to active.
  """
  def start_game(%Game{} = game) do
    game
    |> Game.changeset(%{state: "active", start_at: DateTime.utc_now()})
    |> Repo.update()
    |> case do
      {:ok, updated_game} = result ->
        Shared.broadcast_event("game:#{game.id}", {:game_started, updated_game})
        result

      error ->
        error
    end
  end

  @doc """
  Ends a game by changing its state to "post_game".
  """
  def end_game(%Game{} = game) do
    update_game(game, %{state: "post_game", end_at: DateTime.utc_now()})
  end

  @doc """
  Gets games with their players preloaded.
  """
  def list_games_with_players do
    Game
    |> preload(:players)
    |> Repo.all()
  end

  @doc """
  Gets a game with its players preloaded.
  """
  def get_game_with_players!(id) do
    Game
    |> preload(:players)
    |> Repo.get!(id)
  end

  # Log Entry Functions

  @doc """
  Creates a log entry for a game event.

  ## Examples

      iex> create_log_entry("player_joined", game, player, %{details: "Player joined the game"})
      {:ok, %LogEntry{}}

  """
  def create_log_entry(event, game, player \\ nil, opts \\ %{}) do
    attrs = %{
      event: event,
      game_id: game.id,
      player_id: player && player.id,
      player_nickname: player && player.nickname,
      actor_id: opts[:actor] && opts[:actor].id,
      actor_nickname: opts[:actor] && opts[:actor].nickname,
      details: opts[:details]
    }

    case %LogEntry{}
         |> LogEntry.changeset(attrs)
         |> Repo.insert() do
      {:ok, log_entry} = result ->
        # Broadcast log entry update to game subscribers
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "game:#{game.id}",
          {:log_entry_created, log_entry}
        )
        result

      error ->
        error
    end
  end

  @doc """
  Gets all log entries for a game, ordered by newest first.

  ## Examples

      iex> list_log_entries_for_game("game-id")
      [%LogEntry{}, ...]

  """
  def list_log_entries_for_game(game_id) do
    LogEntry
    |> where([l], l.game_id == ^game_id)
    |> order_by([l], desc: l.inserted_at)
    |> Repo.all()
  end

  @doc """
  Logs a player joining the game.
  """
  def log_player_joined(game, player) do
    create_log_entry("player_joined", game, player, %{
      details: "#{player.nickname} joined the game"
    })
  end

  @doc """
  Logs a player going offline.
  """
  def log_player_offline(game, player) do
    create_log_entry("player_offline", game, player, %{
      details: "#{player.nickname} went offline"
    })
  end

  @doc """
  Logs a player coming online.
  """
  def log_player_online(game, player) do
    create_log_entry("player_online", game, player, %{
      details: "#{player.nickname} came online"
    })
  end

  @doc """
  Logs a player being warned by a host.
  """
  def log_player_warned(game, player, host) do
    create_log_entry("player_warned", game, player, %{
      actor: host,
      details: "#{player.nickname} was warned by host #{host.nickname}"
    })
  end

  @doc """
  Logs a player being kicked from the game.
  """
  def log_player_kicked(game, player, host) do
    create_log_entry("player_kicked", game, player, %{
      actor: host,
      details: "#{player.nickname} was kicked by host #{host.nickname}"
    })
  end

  @doc """
  Logs a player being promoted to host.
  """
  def log_player_promoted_to_host(game, player, promoting_host) do
    create_log_entry("player_promoted_to_host", game, player, %{
      actor: promoting_host,
      details: "#{player.nickname} was promoted to host by #{promoting_host.nickname}"
    })
  end

  @doc """
  Logs a player being demoted from host.
  """
  def log_player_demoted_from_host(game, player, demoting_host) do
    create_log_entry("player_demoted_from_host", game, player, %{
      actor: demoting_host,
      details: "#{player.nickname} was demoted from host by #{demoting_host.nickname}"
    })
  end

  defp generate_unique_game_code do
    game_code = Game.generate_game_code()

    case get_game_by_code(game_code) do
      nil -> game_code
      _game -> generate_unique_game_code()
    end
  end
end
