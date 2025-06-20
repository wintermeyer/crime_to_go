defmodule CrimeToGoWeb.GameLive.HostDashboard do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.{Game, Player, Chat}

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Game.get_game!(game_id)
    players = Player.list_active_players_for_game(game_id)

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
          # Subscribe to player-specific updates
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "player:#{current_player.id}")
        end

        # Generate the join URL for the QR code
        join_url = CrimeToGoWeb.Endpoint.url() <> "/games/#{game_id}/join"

        # Get the public chat room for this game
        public_chat_room = Chat.get_public_chat_room(game_id)

        # Ensure player is a member of the public chat room
        if public_chat_room && current_player && 
           not Chat.member_of_chat_room?(public_chat_room.id, current_player.id) do
          Chat.add_member_to_chat_room(public_chat_room, current_player)
        end

        # Subscribe to chat room updates if connected
        if connected?(socket) && public_chat_room do
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "chat_room:#{public_chat_room.id}")
        end

        {:ok,
         assign(socket,
           game: game,
           join_url: join_url,
           players: players,
           current_player: current_player,
           public_chat_room: public_chat_room
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
        {:noreply,
         socket
         |> put_flash(:info, gettext("Game started! All players have been notified."))
         |> push_navigate(to: ~p"/games/#{socket.assigns.game.id}/lobby")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Unable to start game"))}
    end
  end

  @impl true
  def handle_event("show_end_game_modal", _params, socket) do
    handle_show_end_game_modal(socket)
  end

  @impl true
  def handle_event("hide_end_game_modal", _params, socket) do
    handle_hide_end_game_modal(socket)
  end

  @impl true
  def handle_event("confirm_end_game", _params, socket) do
    handle_confirm_end_game(socket)
  end

  @impl true
  def handle_event("grant_host", %{"player-id" => player_id}, socket) do
    case Player.set_player_as_host(player_id, socket.assigns.current_player) do
      {:ok, updated_player} ->
        # Broadcast the change to all connected clients
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "game:#{socket.assigns.game.id}",
          {:player_promoted_to_host, updated_player}
        )

        # Refresh players list
        players = Player.list_active_players_for_game(socket.assigns.game.id)

        {:noreply,
         socket
         |> assign(players: players)
         |> put_flash(:info, gettext("Player %{name} is now a host", name: updated_player.nickname))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Unable to grant host privileges"))}
    end
  end

  @impl true
  def handle_event("revoke_host", %{"player-id" => player_id}, socket) do
    case Player.remove_player_as_host(player_id, socket.assigns.current_player) do
      {:ok, updated_player} ->
        # Broadcast the change to all connected clients
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "game:#{socket.assigns.game.id}",
          {:player_demoted_from_host, updated_player}
        )

        # Refresh players list
        players = Player.list_active_players_for_game(socket.assigns.game.id)

        {:noreply,
         socket
         |> assign(players: players)
         |> put_flash(:info, gettext("Player %{name} is no longer a host", name: updated_player.nickname))}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, gettext("Unable to revoke host privileges"))}
    end
  end

  @impl true
  def handle_event("warn_player", %{"player-id" => player_id}, socket) do
    case Player.get_player(player_id) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("Player not found"))}

      player ->
        # Log the warning
        CrimeToGo.Game.log_player_warned(socket.assigns.game, player, socket.assigns.current_player)
        
        # Broadcast warning to the specific player
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "player:#{player_id}",
          {:warning_from_host, socket.assigns.current_player.nickname}
        )

        {:noreply,
         socket
         |> put_flash(:info, gettext("Warning sent to %{name}", name: player.nickname))}
    end
  end

  @impl true
  def handle_event("show_kick_modal", %{"player-id" => player_id}, socket) do
    case Player.get_player(player_id) do
      nil ->
        {:noreply, put_flash(socket, :error, gettext("Player not found"))}

      player ->
        {:noreply,
         socket
         |> assign(show_kick_modal: true, player_to_kick: player)}
    end
  end

  @impl true
  def handle_event("hide_kick_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(show_kick_modal: false, player_to_kick: nil)}
  end

  @impl true
  def handle_event("confirm_kick_player", _params, socket) do
    if socket.assigns[:player_to_kick] do
      case Player.kick_player_from_game(socket.assigns.player_to_kick, socket.assigns.current_player) do
        {:ok, kicked_player} ->
          # Broadcast kick to all players in the game
          Phoenix.PubSub.broadcast(
            CrimeToGo.PubSub,
            "game:#{socket.assigns.game.id}",
            {:player_kicked, kicked_player}
          )

          # Broadcast to the kicked player specifically
          Phoenix.PubSub.broadcast(
            CrimeToGo.PubSub,
            "player:#{kicked_player.id}",
            {:kicked_from_game, socket.assigns.current_player.nickname}
          )

          # Refresh players list
          players = Player.list_active_players_for_game(socket.assigns.game.id)

          {:noreply,
           socket
           |> assign(players: players, show_kick_modal: false, player_to_kick: nil)
           |> put_flash(:info, gettext("Player %{name} has been kicked from the game", name: kicked_player.nickname))}

        {:error, _reason} ->
          {:noreply, put_flash(socket, :error, gettext("Unable to kick player"))}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:player_status_changed, _player, _status}, socket) do
    # Refresh players list when player status changes
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:status_changed, _player, _status}, socket) do
    # Handle player-specific status changes (same as above)
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    # Forward chat messages to the chat component
    send_update(CrimeToGoWeb.ChatComponent, id: "dashboard-chat", new_message: message)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:game_ended, _game}, socket) do
    # Game was ended, redirect to home page and clear cookies
    {:noreply,
     socket
     |> push_event("clear_player_cookies", %{})
     |> put_flash(:info, gettext("The game has been ended by the host."))
     |> push_navigate(to: ~p"/")}
  end

  @impl true
  def handle_info({:player_promoted_to_host, _player}, socket) do
    # Refresh players list when someone becomes a host
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:player_demoted_from_host, _player}, socket) do
    # Refresh players list when someone loses host privileges
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:player_kicked, _player}, socket) do
    # Refresh players list when someone is kicked
    players = Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, assign(socket, players: players)}
  end

  @impl true
  def handle_info({:warning_from_host, host_name}, socket) do
    # This host received a warning from another host
    {:noreply,
     socket
     |> put_flash(:error, gettext("⚠️ WARNING from host %{host_name}: Please follow the game rules or you may be kicked!", host_name: host_name))}
  end

  @impl true
  def handle_info({:kicked_from_game, host_name}, socket) do
    # This host was kicked from the game by another host
    {:noreply,
     socket
     |> push_event("clear_player_cookies", %{})
     |> put_flash(:error, gettext("You have been kicked from the game by host %{host_name}.", host_name: host_name))
     |> push_navigate(to: ~p"/")}
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
