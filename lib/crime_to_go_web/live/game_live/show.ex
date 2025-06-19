defmodule CrimeToGoWeb.GameLive.Show do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Player

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Game.get_game!(game_id)
    players = Player.list_players_for_game(game_id)

    # Check if this user has a player cookie for this game
    cookie_name = "player_#{game_id}"
    current_player = get_player_from_cookies(socket, cookie_name, players)

    # If no valid player found, redirect to join page
    if is_nil(current_player) do
      {:ok,
       socket
       |> put_flash(:info, gettext("Please join the game first"))
       |> push_navigate(to: ~p"/games/#{game_id}/join")}
    else
      # If current player is not the host, redirect to lobby
      if not current_player.game_host do
        {:ok,
         socket
         |> push_navigate(to: ~p"/games/#{game_id}/lobby")}
      else
        # Host can access this page
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
           players: players,
           current_player: current_player
         )}
      end
    end
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, gettext("Game not found"))
       |> push_navigate(to: ~p"/")}
  end

  # Helper function to get player from cookies
  defp get_player_from_cookies(socket, cookie_name, players) do
    case get_connect_params(socket) do
      %{} = connect_params ->
        player_id = Map.get(connect_params, cookie_name)
        if player_id, do: Enum.find(players, &(&1.id == player_id))

      _ ->
        nil
    end
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
    {:noreply, push_event(socket, "phx:copy_to_clipboard", %{text: socket.assigns.game.game_code})}
  end

  @impl true
  def handle_event("copy_join_url", _params, socket) do
    {:noreply, push_event(socket, "phx:copy_to_clipboard", %{text: socket.assigns.join_url})}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    players = Player.list_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:player_status_changed, _player, _status}, socket) do
    # Refresh players list when player status changes
    players = Player.list_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def terminate(_reason, socket) do
    # Set player as offline when LiveView terminates
    case socket.assigns[:current_player] do
      nil -> :ok
      current_player -> Player.set_player_offline(current_player)
    end
    :ok
  end
end
