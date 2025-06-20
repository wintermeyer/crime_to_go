defmodule CrimeToGoWeb.ChatLive.Room do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.{Chat, Game, Player}

  @impl true
  def mount(%{"game_id" => game_id} = params, _session, socket) do
    handle_resource_not_found(socket, fn ->
      game = Game.get_game!(game_id)
      
      # Check if this user has a player cookie for this game
      cookie_name = "player_#{game_id}"
      current_player = get_player_from_cookies(socket, cookie_name, game_id)

      # If no valid player found, redirect to join page
      if is_nil(current_player) do
        {:ok,
         socket
         |> put_flash(:info, gettext("Please join the game first"))
         |> push_navigate(to: ~p"/games/#{game_id}/join")}
      else
        # Get or determine the chat room
        {chat_room, room_type} = get_chat_room(game, params)
        
        # Verify player is a member of this chat room
        unless Chat.member_of_chat_room?(chat_room.id, current_player.id) do
          # If it's the public room, add them automatically
          if chat_room.room_type == "public" do
            Chat.add_member_to_chat_room(chat_room, current_player)
          else
            # For private rooms, redirect if not a member
            {:ok,
             socket
             |> put_flash(:error, gettext("You don't have access to this chat room"))
             |> push_navigate(to: ~p"/games/#{game_id}/lobby")}
          end
        end

        if connected?(socket) do
          # Subscribe to chat room updates
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "chat_room:#{chat_room.id}")
          # Subscribe to game updates for player status
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
          # Subscribe to player-specific updates
          Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "player:#{current_player.id}")
        end

        # Load messages and members
        messages = Chat.list_chat_messages_for_room(chat_room.id)
        members = Chat.list_chat_room_members(chat_room.id)
        
        # Create changeset for new message
        message_changeset = Chat.change_chat_message(%Chat.ChatMessage{})

        {:ok,
         socket
         |> assign(
           game: game,
           chat_room: chat_room,
           room_type: room_type,
           current_player: current_player,
           members: members,
           message_changeset: message_changeset,
           form: to_form(message_changeset)
         )
         |> stream(:messages, messages)}
      end
    end)
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
  def handle_event("send_message", %{"chat_message" => message_params}, socket) do
    message_params = 
      message_params
      |> Map.put("chat_room_id", socket.assigns.chat_room.id)
      |> Map.put("player_id", socket.assigns.current_player.id)

    case Chat.create_chat_message(message_params) do
      {:ok, message} ->
        # Broadcast the new message to all room subscribers
        message_with_player = %{message | player: socket.assigns.current_player}
        Phoenix.PubSub.broadcast(
          CrimeToGo.PubSub,
          "chat_room:#{socket.assigns.chat_room.id}",
          {:new_message, message_with_player}
        )
        
        # Reset the form
        changeset = Chat.change_chat_message(%Chat.ChatMessage{})
        {:noreply, assign(socket, message_changeset: changeset, form: to_form(changeset))}

      {:error, changeset} ->
        {:noreply, assign(socket, message_changeset: changeset, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_message", %{"chat_message" => message_params}, socket) do
    changeset =
      %Chat.ChatMessage{}
      |> Chat.ChatMessage.changeset(message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, message_changeset: changeset, form: to_form(changeset))}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh members list when someone joins the game
    members = Chat.list_chat_room_members(socket.assigns.chat_room.id)
    {:noreply, assign(socket, members: members)}
  end

  @impl true
  def handle_info({:player_status_changed, _player, _status}, socket) do
    # Refresh members list when player status changes
    members = Chat.list_chat_room_members(socket.assigns.chat_room.id)
    {:noreply, assign(socket, members: members)}
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
  def handle_info({:warning_from_host, host_name}, socket) do
    # Player received a warning from a host
    {:noreply,
     socket
     |> put_flash(:error, gettext("⚠️ WARNING from host %{host_name}: Please follow the game rules or you may be kicked!", host_name: host_name))}
  end

  @impl true
  def handle_info({:kicked_from_game, host_name}, socket) do
    # Player was kicked from the game
    {:noreply,
     socket
     |> push_event("clear_player_cookies", %{})
     |> put_flash(:error, gettext("You have been kicked from the game by host %{host_name}.", host_name: host_name))
     |> push_navigate(to: ~p"/")}
  end

  # Helper function to get player from cookies
  defp get_player_from_cookies(socket, cookie_name, game_id) do
    case get_connect_params(socket) do
      %{} = connect_params ->
        player_id = Map.get(connect_params, cookie_name)
        
        if player_id do
          # Verify the player exists and belongs to this game
          players = Player.list_active_players_for_game(game_id)
          Enum.find(players, &(&1.id == player_id))
        else
          nil
        end

      _ ->
        nil
    end
  end

  # Helper function to get the appropriate chat room
  defp get_chat_room(game, %{"live_action" => :all}) do
    # For /chat/all route, get the public chat room
    public_room = Chat.get_public_chat_room(game.id)
    {public_room, :all}
  end
  
  defp get_chat_room(game, %{"id" => room_id}) do
    # For specific room ID
    chat_room = Chat.get_chat_room!(room_id)
    # Verify the room belongs to this game
    if chat_room.game_id != game.id do
      raise Ecto.NoResultsError, queryable: Chat.ChatRoom
    end
    {chat_room, :specific}
  end

  # Helper function to format message timestamps
  defp format_message_time(datetime) do
    now = DateTime.utc_now()
    diff_minutes = DateTime.diff(now, datetime, :minute)
    
    cond do
      diff_minutes < 1 -> gettext("now")
      diff_minutes < 60 -> gettext("%{minutes}m", minutes: diff_minutes)
      diff_minutes < 1440 -> gettext("%{hours}h", hours: div(diff_minutes, 60))
      true -> Calendar.strftime(datetime, "%m/%d %H:%M")
    end
  end
end
