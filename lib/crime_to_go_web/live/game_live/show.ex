defmodule CrimeToGoWeb.GameLive.Show do
  use CrimeToGoWeb, :live_view

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

    # Generate QR code as SVG
    qr_svg = generate_qr_code_svg(join_url)

    {:ok,
     assign(socket,
       game: game,
       join_url: join_url,
       qr_svg: qr_svg,
       players: Player.list_players_for_game(game_id)
     )}
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, "Game not found")
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
        {:noreply, put_flash(socket, :error, "Unable to start game")}
    end
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    players = Player.list_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  defp generate_qr_code_svg(url) do
    # Generate QR code using EQRCode library
    url |> EQRCode.encode() |> EQRCode.svg()
  end
end
