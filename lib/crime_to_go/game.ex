defmodule CrimeToGo.Game do
  @moduledoc """
  The Game context.
  """

  import Ecto.Query, warn: false
  alias CrimeToGo.Repo

  alias CrimeToGo.Game.Game

  @doc """
  Returns the list of games.

  ## Examples

      iex> list_games()
      [%Game{}, ...]

  """
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
  def get_game!(id), do: Repo.get!(Game, id)

  @doc """
  Gets a game by game code.

  ## Examples

      iex> get_game_by_code("123456789012")
      %Game{}

      iex> get_game_by_code("nonexistent")
      nil

  """
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
  def create_game(attrs \\ %{}) do
    game_code = generate_unique_game_code()

    # Convert attrs to string keys if they contain atom keys
    attrs_normalized =
      if Enum.any?(Map.keys(attrs), &is_atom/1) do
        for {key, val} <- attrs, into: %{}, do: {to_string(key), val}
      else
        attrs
      end

    attrs_with_code =
      attrs_normalized
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
  def delete_game(%Game{} = game) do
    Repo.delete(game)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking game changes.

  ## Examples

      iex> change_game(game)
      %Ecto.Changeset{data: %Game{}}

  """
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
        # Broadcast game started event
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "game:#{game.id}",
          {:game_started, updated_game}
        )

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

  defp generate_unique_game_code do
    game_code = Game.generate_game_code()

    case get_game_by_code(game_code) do
      nil -> game_code
      _game -> generate_unique_game_code()
    end
  end
end
