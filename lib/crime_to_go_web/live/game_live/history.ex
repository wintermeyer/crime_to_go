defmodule CrimeToGoWeb.GameLive.History do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.{Game, Player}
  require Logger

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Game.get_game!(game_id)
    
    # During initial HTTP mount, defer player resolution until WebSocket connection
    if connected?(socket) do
      # WebSocket connected - player cookies are available
      players = Player.list_active_players_for_game(game_id)
      cookie_name = "player_#{game_id}"
      current_player = get_player_from_cookies(socket, cookie_name, players)

      # If no valid player found, redirect to join page
      if is_nil(current_player) do
        {:ok,
         socket
         |> put_flash(:info, gettext("Please join the game first"))
         |> push_navigate(to: "/games/#{game_id}/join")}
      else
        # If current player is not a host, redirect to lobby
        if not current_player.game_host do
          {:ok,
           socket
           |> put_flash(:error, gettext("Only hosts can view game history"))
           |> push_navigate(to: "/games/#{game_id}/lobby")}
        else
          # Host can access this page
          # Subscribe to game updates for real-time log entries
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")

          # Get log entries for this game
          log_entries = Game.list_log_entries_for_game(game_id)

          {:ok,
           assign(socket,
             game: game,
             current_player: current_player,
             log_entries: log_entries,
             show_end_game_modal: false,
             new_entry_ids: MapSet.new()
           )}
        end
      end
    else
      # Initial HTTP mount - just load the page skeleton
      {:ok,
       assign(socket,
         game: game,
         log_entries: [],
         show_end_game_modal: false,
         new_entry_ids: MapSet.new()
       )}
    end
  rescue
    Ecto.NoResultsError ->
      {:ok,
       socket
       |> put_flash(:error, gettext("Game not found"))
       |> push_navigate(to: "/")}
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
  def handle_info({:player_joined, _player}, socket) do
    # Player joins are logged automatically and will trigger :log_entry_created
    # No need to manually refresh here
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_status_changed, _player, _status}, socket) do
    # Status changes are logged automatically and will trigger :log_entry_created
    # No need to manually refresh here
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
    # Promotions are logged automatically and will trigger :log_entry_created
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_demoted_from_host, _player}, socket) do
    # Demotions are logged automatically and will trigger :log_entry_created
    {:noreply, socket}
  end

  @impl true
  def handle_info({:player_kicked, _player}, socket) do
    # Kicks are logged automatically and will trigger :log_entry_created
    {:noreply, socket}
  end

  @impl true
  def handle_info({:warning_from_host, host_name}, socket) do
    # This host received a warning from another host (shouldn't happen but handle it)
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
  def handle_info({:log_entry_created, log_entry}, socket) do
    # Real-time update when any log entry is created
    log_entries = Game.list_log_entries_for_game(socket.assigns.game.id)
    
    # Mark this entry as new for highlighting  
    new_entry_ids = MapSet.put(socket.assigns.new_entry_ids, log_entry.id)
    
    # Update socket with new log entries
    socket = assign(socket, log_entries: log_entries, new_entry_ids: new_entry_ids)
    
    # Schedule highlight removal
    Process.send_after(self(), {:remove_highlight, log_entry.id}, 3000)
    
    {:noreply, socket}
  end

  @impl true
  def handle_info({:remove_highlight, entry_id}, socket) do
    # Remove the entry from the highlighted set
    new_entry_ids = MapSet.delete(socket.assigns.new_entry_ids, entry_id)
    {:noreply, assign(socket, new_entry_ids: new_entry_ids)}
  end

  # Function to format log entry events for display
  def format_event_type(event) do
    case event do
      "player_joined" -> gettext("Player Joined")
      "player_offline" -> gettext("Player Offline")
      "player_online" -> gettext("Player Online")
      "player_warned" -> gettext("Player Warned")
      "player_kicked" -> gettext("Player Kicked")
      "player_promoted_to_host" -> gettext("Promoted to Host")
      "player_demoted_from_host" -> gettext("Demoted from Host")
      _ -> String.replace(event, "_", " ") |> String.capitalize()
    end
  end

  # Function to get appropriate icon for each event type
  def event_icon(event) do
    case event do
      "player_joined" -> "hero-user-plus"
      "player_offline" -> "hero-arrow-right-start-on-rectangle"
      "player_online" -> "hero-arrow-left-end-on-rectangle"
      "player_warned" -> "hero-exclamation-triangle"
      "player_kicked" -> "hero-x-circle"
      "player_promoted_to_host" -> "hero-star"
      "player_demoted_from_host" -> "hero-star-outline"
      _ -> "hero-information-circle"
    end
  end

  # Function to get appropriate color class for each event type
  def event_color(event) do
    case event do
      "player_joined" -> "text-success"
      "player_offline" -> "text-warning"
      "player_online" -> "text-success"
      "player_warned" -> "text-warning"
      "player_kicked" -> "text-error"
      "player_promoted_to_host" -> "text-info"
      "player_demoted_from_host" -> "text-base-content"
      _ -> "text-base-content"
    end
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



  # Check if a log entry is newly created
  def is_new_entry?(log_entry, new_entry_ids) do
    MapSet.member?(new_entry_ids, log_entry.id)
  end
end