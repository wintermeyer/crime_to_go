defmodule CrimeToGoWeb.GameLive.Show do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Player

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Game.get_game!(game_id)

    if connected?(socket) do
      # Subscribe to game updates
      Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
    end

    # Generate the join URL for the QR code
    join_url = CrimeToGoWeb.Endpoint.url() <> "/games/#{game_id}/join"

    {:ok,
     assign(socket,
       game: game,
       join_url: join_url,
       players: Player.list_players_for_game(game_id)
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
  def handle_event("start_game", _params, socket) do
    case Game.start_game(socket.assigns.game) do
      {:ok, _game} ->
        {:noreply, push_navigate(socket, to: ~p"/games/#{socket.assigns.game.id}/lobby")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Unable to start game"))}
    end
  end

  @impl true
  def handle_event("copy_game_code", _params, socket) do
    {:noreply, push_event(socket, "copy_to_clipboard", %{text: socket.assigns.game.game_code})}
  end

  @impl true
  def handle_event("copy_join_url", _params, socket) do
    {:noreply, push_event(socket, "copy_to_clipboard", %{text: socket.assigns.join_url})}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    players = Player.list_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end
end
