defmodule CrimeToGo.Player do
  @moduledoc """
  The Player context.

  This context manages player-related operations including creation, game membership,
  host management, and avatar/nickname availability checking.
  """

  import Ecto.Query, warn: false
  alias CrimeToGo.Repo
  alias CrimeToGo.Shared

  alias CrimeToGo.Player.Player
  alias CrimeToGo.Game.Game

  @doc """
  Returns the list of players.

  ## Examples

      iex> list_players()
      [%Player{}, ...]

  """
  def list_players do
    Repo.all(Player)
  end

  @doc """
  Returns the list of players for a specific game.

  ## Examples

      iex> list_players_for_game("game-id")
      [%Player{}, ...]

  """
  def list_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id)
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single player.

  Raises `Ecto.NoResultsError` if the Player does not exist.

  ## Examples

      iex> get_player!(123)
      %Player{}

      iex> get_player!("nonexistent")
      ** (Ecto.NoResultsError)

  """
  def get_player!(id), do: Repo.get!(Player, id)

  @doc """
  Gets a single player.

  Returns nil if the Player does not exist.

  ## Examples

      iex> get_player(123)
      %Player{}

      iex> get_player("nonexistent")
      nil

  """
  def get_player(id), do: Repo.get(Player, id)

  @doc """
  Gets a player by nickname within a game.

  ## Examples

      iex> get_player_by_nickname("game-id", "nickname")
      %Player{}

      iex> get_player_by_nickname("game-id", "nonexistent")
      nil

  """
  def get_player_by_nickname(game_id, nickname) do
    Player
    |> where([p], p.game_id == ^game_id and p.nickname == ^nickname)
    |> Repo.one()
  end

  @doc """
  Creates a player.

  ## Examples

      iex> create_player(%{field: value})
      {:ok, %Player{}}

      iex> create_player(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_player(attrs \\ %{}) do
    case %Player{}
         |> Player.changeset(attrs)
         |> Repo.insert() do
      {:ok, player} ->
        # Log the player joining
        if player.game_id do
          game = CrimeToGo.Game.get_game!(player.game_id)
          CrimeToGo.Game.log_player_joined(game, player)
        end
        
        {:ok, player}
      
      error ->
        error
    end
  end

  @doc """
  Updates a player.

  ## Examples

      iex> update_player(player, %{field: new_value})
      {:ok, %Player{}}

      iex> update_player(player, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_player(%Player{} = player, attrs) do
    player
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a player.

  ## Examples

      iex> delete_player(player)
      {:ok, %Player{}}

      iex> delete_player(player)
      {:error, %Ecto.Changeset{}}

  """
  def delete_player(%Player{} = player) do
    Repo.delete(player)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking player changes.

  ## Examples

      iex> change_player(player)
      %Ecto.Changeset{data: %Player{}}

  """
  def change_player(%Player{} = player, attrs \\ %{}) do
    Player.changeset(player, attrs)
  end

  @doc """
  Gets the game host for a specific game.

  ## Examples

      iex> get_game_host("game-id")
      %Player{}

      iex> get_game_host("nonexistent")
      nil

  """
  def get_game_host(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.game_host == true)
    |> Repo.one()
  end

  @doc """
  Sets a player as the game host.

  ## Examples

      iex> set_as_host(player)
      {:ok, %Player{}}

  """
  def set_as_host(%Player{} = player) do
    update_player(player, %{game_host: true})
  end

  @doc """
  Checks if a nickname is available within a game.

  ## Examples

      iex> nickname_available?("game-id", "nickname")
      true

      iex> nickname_available?("game-id", "taken_nickname")
      false

  """
  def nickname_available?(game_id, nickname) do
    is_nil(get_player_by_nickname(game_id, nickname))
  end

  @doc """
  Checks if a nickname is available within a game (case-insensitive).
  Optionally excludes a specific player ID from the check (for updates).

  ## Examples

      iex> nickname_available_case_insensitive?("game-id", "nickname", nil)
      true

      iex> nickname_available_case_insensitive?("game-id", "TAKEN_nickname", nil)
      false

      iex> nickname_available_case_insensitive?("game-id", "nickname", "player-id")
      true

  """
  def nickname_available_case_insensitive?(game_id, nickname, exclude_player_id \\ nil) do
    query =
      Player
      |> where([p], p.game_id == ^game_id)
      |> where([p], fragment("LOWER(?)", p.nickname) == ^String.downcase(nickname))

    query =
      if exclude_player_id do
        where(query, [p], p.id != ^exclude_player_id)
      else
        query
      end

    is_nil(Repo.one(query))
  end

  @doc """
  Checks if an avatar filename is available within a game.

  ## Examples

      iex> avatar_available?("game-id", "avatar.png")
      true

      iex> avatar_available?("game-id", "taken_avatar.png")
      false

  """
  def avatar_available?(game_id, avatar_file_name) do
    Player
    |> where([p], p.game_id == ^game_id and p.avatar_file_name == ^avatar_file_name)
    |> Repo.one()
    |> is_nil()
  end

  @doc """
  Creates the first player for a game and sets them as host.

  ## Examples

      iex> create_host_player(game, %{nickname: "Host", avatar_file_name: "host.png"})
      {:ok, %Player{}}

  """
  def create_host_player(%Game{} = game, attrs) do
    attrs_with_host =
      attrs
      |> Shared.normalize_attrs()
      |> Map.put("game_id", game.id)
      |> Map.put("game_host", true)

    create_player(attrs_with_host)
  end

  @doc """
  Gets players with their game preloaded.
  """
  def get_player_with_game!(id) do
    Player
    |> preload(:game)
    |> Repo.get!(id)
  end

  @doc """
  Gets all non-robot players for a game.
  """
  def list_human_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.is_robot == false)
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets all robot players for a game.
  """
  def list_robot_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.is_robot == true)
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Updates a player's status.

  ## Examples

      iex> update_player_status(player, "online")
      {:ok, %Player{}}
      
      iex> update_player_status(player, "offline")
      {:ok, %Player{}}
  """
  def update_player_status(%Player{} = player, status) when status in ["online", "offline", "kicked"] do
    attrs = %{
      status: status,
      last_seen_at: DateTime.utc_now()
    }

    player
    |> Player.status_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Sets a player as online and broadcasts the status change.
  """
  def set_player_online(%Player{} = player) do
    case update_player_status(player, "online") do
      {:ok, updated_player} ->
        broadcast_player_status_change(updated_player, "online")
        
        # Cancel any pending offline log (with error handling)
        was_scheduled_for_offline = safe_cancel_offline_log(updated_player.id)
        
        # Only log if player was actually offline and not just a quick reconnect
        # If there was a scheduled offline log, it means this is a quick reconnect
        if player.status == "offline" and not was_scheduled_for_offline do
          game = CrimeToGo.Game.get_game!(updated_player.game_id)
          CrimeToGo.Game.log_player_online(game, updated_player)
        end
        
        {:ok, updated_player}

      error ->
        error
    end
  end

  @doc """
  Sets a player as offline and broadcasts the status change.
  """
  def set_player_offline(%Player{} = player) do
    case update_player_status(player, "offline") do
      {:ok, updated_player} ->
        broadcast_player_status_change(updated_player, "offline")
        
        # Schedule delayed offline logging (can be cancelled if player comes back online)
        safe_schedule_offline_log(updated_player)
        
        {:ok, updated_player}

      error ->
        error
    end
  end

  @doc """
  Gets all online players for a game.
  """
  def list_online_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.status == "online")
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets all offline players for a game.
  """
  def list_offline_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.status == "offline")
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Sets a player as host by player ID.

  ## Examples

      iex> set_player_as_host("player-id", promoting_host)
      {:ok, %Player{}}

  """
  def set_player_as_host(player_id, promoting_host \\ nil) do
    case get_player(player_id) do
      nil ->
        {:error, :not_found}

      player ->
        case update_player(player, %{game_host: true}) do
          {:ok, updated_player} ->
            # Log the promotion
            if promoting_host do
              game = CrimeToGo.Game.get_game!(updated_player.game_id)
              CrimeToGo.Game.log_player_promoted_to_host(game, updated_player, promoting_host)
            end
            
            {:ok, updated_player}
          
          error ->
            error
        end
    end
  end

  @doc """
  Removes host privileges from a player by player ID.

  ## Examples

      iex> remove_player_as_host("player-id", demoting_host)
      {:ok, %Player{}}

  """
  def remove_player_as_host(player_id, demoting_host \\ nil) do
    case get_player(player_id) do
      nil ->
        {:error, :not_found}

      player ->
        case update_player(player, %{game_host: false}) do
          {:ok, updated_player} ->
            # Log the demotion
            if demoting_host do
              game = CrimeToGo.Game.get_game!(updated_player.game_id)
              CrimeToGo.Game.log_player_demoted_from_host(game, updated_player, demoting_host)
            end
            
            {:ok, updated_player}
          
          error ->
            error
        end
    end
  end

  @doc """
  Kicks a player from the game by setting their status to "kicked".

  ## Examples

      iex> kick_player_from_game(player, host)
      {:ok, %Player{}}

  """
  def kick_player_from_game(%Player{} = player, host \\ nil) do
    case update_player_status(player, "kicked") do
      {:ok, updated_player} ->
        broadcast_player_status_change(updated_player, "kicked")
        
        # Log the player being kicked
        if host do
          game = CrimeToGo.Game.get_game!(updated_player.game_id)
          CrimeToGo.Game.log_player_kicked(game, updated_player, host)
        end
        
        {:ok, updated_player}

      error ->
        error
    end
  end

  @doc """
  Gets all kicked players for a game.
  """
  def list_kicked_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.status == "kicked")
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets all active (non-kicked) players for a game.
  """
  def list_active_players_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.status != "kicked")
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets all host players for a game.

  ## Examples

      iex> list_hosts_for_game("game-id")
      [%Player{}, ...]

  """
  def list_hosts_for_game(game_id) do
    Player
    |> where([p], p.game_id == ^game_id and p.game_host == true and p.status != "kicked")
    |> order_by([p], p.inserted_at)
    |> Repo.all()
  end

  # Broadcasts player status changes to the game topic and player-specific topic.
  defp broadcast_player_status_change(%Player{} = player, status) do
    # Broadcast to game topic for all players in the game
    Phoenix.PubSub.broadcast(
      CrimeToGo.PubSub,
      "game:#{player.game_id}",
      {:player_status_changed, player, status}
    )

    # Broadcast to player-specific topic
    Phoenix.PubSub.broadcast(
      CrimeToGo.PubSub,
      "player:#{player.id}",
      {:status_changed, player, status}
    )
  end

  # Safe wrapper for StatusLogger calls with error handling
  defp safe_cancel_offline_log(player_id) do
    if CrimeToGo.Player.StatusLogger.alive? do
      try do
        CrimeToGo.Player.StatusLogger.cancel_offline_log(player_id)
      rescue
        error ->
          require Logger
          Logger.warning("StatusLogger error for cancel_offline_log: #{inspect(error)}")
          false
      catch
        :exit, reason ->
          require Logger
          Logger.warning("StatusLogger exit for cancel_offline_log: #{inspect(reason)}")
          false
      end
    else
      # StatusLogger not available, assume no scheduled log
      false
    end
  end

  defp safe_schedule_offline_log(player) do
    if CrimeToGo.Player.StatusLogger.alive? do
      try do
        CrimeToGo.Player.StatusLogger.schedule_offline_log(player)
      rescue
        error ->
          require Logger
          Logger.warning("StatusLogger error for schedule_offline_log: #{inspect(error)}")
          fallback_log_offline(player)
      catch
        :exit, reason ->
          require Logger
          Logger.warning("StatusLogger exit for schedule_offline_log: #{inspect(reason)}")
          fallback_log_offline(player)
      end
    else
      # StatusLogger not available, log immediately
      fallback_log_offline(player)
    end
  end

  defp fallback_log_offline(player) do
    game = CrimeToGo.Game.get_game!(player.game_id)
    CrimeToGo.Game.log_player_offline(game, player)
  end
end
