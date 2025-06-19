defmodule CrimeToGoWeb.GameLive.Lobby do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Player

  @impl true
  def mount(%{"id" => game_id} = params, _session, socket) do
    game = Game.get_game!(game_id)

    if connected?(socket) do
      # Subscribe to game updates
      Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
    end

    current_player =
      case Map.get(params, "player_id") do
        nil -> nil
        player_id -> Player.get_player!(player_id)
      end

    {:ok,
     assign(socket,
       game: game,
       players: Player.list_players_for_game(game_id),
       current_player: current_player
     )}
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, gettext("Game not found"))
       |> push_navigate(to: ~p"/")}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_started, game}, socket) do
    # Redirect to game page when game starts
    {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/play")}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    players = Player.list_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end
end
