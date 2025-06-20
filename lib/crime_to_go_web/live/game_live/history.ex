defmodule CrimeToGoWeb.GameLive.History do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  require Logger

  # Use BaseLive macros for common patterns
  handle_game_ending_events()
  handle_player_offline_on_terminate()

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    case mount_game_liveview(socket, game_id, require_host: true) do
      {:ok, %{assigns: %{current_player: _current_player}} = socket} ->
        # Successfully mounted with host permissions
        # Get log entries for this game
        log_entries = Game.list_log_entries_for_game(game_id)

        {:ok,
         assign(socket,
           log_entries: log_entries,
           show_end_game_modal: false,
           new_entry_ids: MapSet.new()
         )}
      
      {:ok, redirect_socket} ->
        # Redirected due to auth/permission issues
        {:ok, redirect_socket}
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


  # All standard player status events are logged automatically and will trigger :log_entry_created
  # No need to manually handle them here since we only care about log entries, not player lists

  @impl true
  def handle_info({:player_joined, _player}, socket), do: {:noreply, socket}
  @impl true  
  def handle_info({:player_status_changed, _player, _status}, socket), do: {:noreply, socket}
  @impl true
  def handle_info({:player_promoted_to_host, _player}, socket), do: {:noreply, socket}
  @impl true
  def handle_info({:player_demoted_from_host, _player}, socket), do: {:noreply, socket}
  @impl true
  def handle_info({:player_kicked, _player}, socket), do: {:noreply, socket}

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




  # Check if a log entry is newly created
  def is_new_entry?(log_entry, new_entry_ids) do
    MapSet.member?(new_entry_ids, log_entry.id)
  end
end