defmodule CrimeToGoWeb.GameLive.Show do
  @moduledoc """
  LiveView for the main game dashboard shown to all players during an active game.
  Displays the game chat, player list, and countdown timer.
  """
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Chat
  alias CrimeToGo.Player
  alias CrimeToGo.Shared

  @impl true
  def mount(%{"id" => game_id}, _session, socket) do
    game = Game.get_game_with_players!(game_id)
    
    # Check if player has access to this game
    cookie_name = "player_#{game_id}"
    players = game.players
    current_player = get_player_from_cookies(socket, cookie_name, players)
    
    # If no valid player found, redirect to join page
    if is_nil(current_player) do
      {:ok,
       socket
       |> put_flash(:info, gettext("Please join the game first"))
       |> push_navigate(to: ~p"/games/#{game_id}/join")}
    else
      if connected?(socket) do
        # Subscribe to game updates
        Shared.subscribe("game:#{game_id}")
        
        # Subscribe to all chat room
        all_chat_room = Chat.get_room_by_name!(game_id, "all")
        Shared.subscribe("chat_room:#{all_chat_room.id}")
      end

      # Get initial countdown if game is active
      countdown_seconds = 
        case game.state do
          "active" ->
            case Game.CountdownServer.get_remaining_time(game_id) do
              {:ok, seconds} -> seconds
              _ -> nil
            end
          _ -> nil
        end

      {:ok,
       socket
       |> assign(:page_title, gettext("Game"))
       |> assign(:game, game)
       |> assign(:current_player, current_player)
       |> assign(:countdown_seconds, countdown_seconds)
       |> assign_chat_data(game_id)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    case Chat.create_chat_message(%{
      content: content,
      chat_room_id: socket.assigns.all_chat_room.id,
      player_id: socket.assigns.current_player.id
    }) do
      {:ok, _message} ->
        {:noreply, 
         socket
         |> assign(:message_form, to_form(Chat.change_chat_message(%Chat.ChatMessage{})))}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to send message"))}
    end
  end

  @impl true
  def handle_info({:game_preparing, game}, socket) do
    {:noreply, 
     socket
     |> assign(:game, game)
     |> put_flash(:info, gettext("Game is preparing... Get ready!"))}
  end

  def handle_info({:game_started, game}, socket) do
    # Get initial countdown
    countdown_seconds = 
      case Game.CountdownServer.get_remaining_time(game.id) do
        {:ok, seconds} -> seconds
        _ -> 30 * 60  # Default to 30 minutes
      end

    {:noreply, 
     socket
     |> assign(:game, game)
     |> assign(:countdown_seconds, countdown_seconds)
     |> put_flash(:info, gettext("Game has started!"))}
  end

  def handle_info({:countdown_update, remaining_seconds}, socket) do
    {:noreply, assign(socket, :countdown_seconds, remaining_seconds)}
  end

  def handle_info({:game_ended, game}, socket) do
    {:noreply, 
     socket
     |> assign(:game, game)
     |> assign(:countdown_seconds, 0)
     |> put_flash(:info, gettext("Game has ended!"))}
  end

  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, fn messages -> [message | messages] end)}
  end

  def handle_info({:player_joined, _player}, socket) do
    # Reload players
    game = Game.get_game_with_players!(socket.assigns.game.id)
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info({:player_status_changed, _player}, socket) do
    # Reload players
    game = Game.get_game_with_players!(socket.assigns.game.id)
    {:noreply, assign(socket, :game, game)}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp assign_chat_data(socket, game_id) do
    all_chat_room = Chat.get_room_by_name!(game_id, "all")
    messages = Chat.list_messages_for_room(all_chat_room.id, 50)
    message_form = to_form(Chat.change_chat_message(%Chat.ChatMessage{}))

    socket
    |> assign(:all_chat_room, all_chat_room)
    |> assign(:messages, messages)
    |> assign(:message_form, message_form)
  end


  defp format_countdown(nil), do: "--:--"
  defp format_countdown(seconds) when seconds <= 0, do: "00:00"
  defp format_countdown(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    :io_lib.format("~2..0B:~2..0B", [minutes, secs]) |> to_string()
  end
end