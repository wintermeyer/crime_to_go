defmodule CrimeToGo.Player do
  @moduledoc """
  The Player context.
  """

  import Ecto.Query, warn: false
  alias CrimeToGo.Repo

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
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
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
    # Convert attrs to string keys if they contain atom keys
    attrs_normalized =
      if Enum.any?(Map.keys(attrs), &is_atom/1) do
        for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
      else
        attrs
      end

    attrs_with_host =
      attrs_normalized
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
end
