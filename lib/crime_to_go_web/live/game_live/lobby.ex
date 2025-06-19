defmodule CrimeToGoWeb.GameLive.Lobby do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Player

  @impl true
  def mount(%{"id" => game_id} = params, _session, socket) do
    game = Game.get_game!(game_id)
    players = Player.list_players_for_game(game_id)

    # Check if this user is accessing with a valid player_id parameter
    current_player =
      case Map.get(params, "player_id") do
        nil -> nil
        player_id -> Enum.find(players, &(&1.id == player_id))
      end

    # If no valid player_id is provided, redirect to join page
    if is_nil(current_player) do
      {:ok,
       socket
       |> put_flash(:info, gettext("Please join the game first"))
       |> push_navigate(to: ~p"/games/#{game_id}/join")}
    else
      if connected?(socket) do
        # Subscribe to game updates
        Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
      end

      {:ok,
       assign(socket,
         game: game,
         players: players,
         current_player: current_player
       )}
    end
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

  @impl true
  def handle_event("copy_game_code", _params, socket) do
    {:noreply, push_event(socket, "copy_to_clipboard", %{text: socket.assigns.game.game_code})}
  end

  @impl true
  def handle_event("copy_join_url", _params, socket) do
    url = CrimeToGoWeb.Endpoint.url() <> "/games/#{socket.assigns.game.id}/join"
    {:noreply, push_event(socket, "copy_to_clipboard", %{text: url})}
  end
end
