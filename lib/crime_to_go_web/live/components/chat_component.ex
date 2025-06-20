defmodule CrimeToGoWeb.ChatComponent do
  use CrimeToGoWeb, :live_component

  alias CrimeToGo.Chat
  alias CrimeToGoWeb.ChatFormatter

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full" phx-hook="ChatAutoScroll" id={"#{@id}-chat-container"}>
      <!-- Chat messages area -->
      <div
        id={"#{@id}-messages-container"}
        class="flex-1 overflow-y-auto p-4 space-y-3 bg-base-50"
        phx-update="stream"
      >
        <div id={"#{@id}-messages"} phx-update="stream">
          <%= for {dom_id, message} <- @streams.messages do %>
            <div
              id={dom_id}
              class={[
                "chat",
                if(message.player_id == @current_player.id, do: "chat-end", else: "chat-start")
              ]}
            >
              <div class="chat-image avatar">
                <div class="w-6 h-6 rounded-full">
                  <img
                    src={~p"/images/avatars/#{message.player.avatar_file_name}"}
                    alt={message.player.nickname}
                    class="rounded-full"
                  />
                </div>
              </div>
              <div class="chat-header text-xs opacity-60 mb-1">
                {message.player.nickname}
                <time class="text-xs opacity-50 ml-1">
                  {format_message_time(message.inserted_at)}
                </time>
              </div>
              <div class={[
                "chat-bubble text-sm max-w-xs",
                if(message.player_id == @current_player.id,
                  do: "chat-bubble-primary",
                  else: "chat-bubble-secondary"
                )
              ]}>
                {ChatFormatter.format_message(message.content)}
              </div>
            </div>
          <% end %>
        </div>
        
        <%= if map_size(@streams.messages) == 0 do %>
          <div class="text-center py-8">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-8 w-8 mx-auto text-base-300 mb-2"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"
              />
            </svg>
            <p class="text-base-content/60 text-xs">
              {gettext("No messages yet")}
            </p>
          </div>
        <% end %>
      </div>

      <!-- Message input -->
      <div class="border-t border-base-300 p-3 bg-base-100 flex-shrink-0">
        <.form
          for={@form}
          phx-submit="send_message"
          phx-change="validate_message"
          phx-target={@myself}
          class="space-y-2"
        >
          <div class="flex gap-2">
            <.input
              field={@form[:content]}
              type="text"
              placeholder={gettext("Type a message...")}
              class="flex-1 input-sm"
              maxlength="1000"
              autocomplete="off"
            />
            <button
              type="submit"
              disabled={not @message_changeset.valid?}
              class="btn btn-primary btn-sm btn-square disabled:btn-disabled"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"
                />
              </svg>
            </button>
          </div>
          <div class="text-xs text-base-content/50 px-1">
            {gettext("Auto links + Markdown: *italic*, **bold**, [link](url)")}
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, socket}
  end

  @impl true
  def update(%{new_message: message} = _assigns, socket) do
    # Handle new message forwarded from parent LiveView
    {:ok, stream_insert(socket, :messages, message)}
  end

  @impl true
  def update(%{chat_room: chat_room, current_player: _current_player} = assigns, socket) do
    # Load messages for this chat room
    messages = Chat.list_chat_messages_for_room(chat_room.id)
    
    # Create changeset for new message
    message_changeset = Chat.change_chat_message(%Chat.ChatMessage{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       message_changeset: message_changeset,
       form: to_form(message_changeset)
     )
     |> stream(:messages, messages)}
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
    # Include required fields for validation
    message_params_with_required = 
      message_params
      |> Map.put("chat_room_id", socket.assigns.chat_room.id)
      |> Map.put("player_id", socket.assigns.current_player.id)

    changeset =
      %Chat.ChatMessage{}
      |> Chat.ChatMessage.changeset(message_params_with_required)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, message_changeset: changeset, form: to_form(changeset))}
  end

  # Handle new message broadcasts
  def handle_info({:new_message, message}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
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