defmodule CrimeToGoWeb.PlayerLive.Join do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Player
  alias CrimeToGo.Chat

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    case Game.get_game!(game_id) do
      %{state: "pre_game"} = game ->
        changeset =
          Player.change_player(%Player.Player{game_id: game_id})
          |> Map.put(:action, :validate)

        {:ok,
         assign(socket,
           game: game,
           changeset: changeset,
           form: to_form(changeset),
           existing_players: Player.list_players_for_game(game_id),
           form_params: %{}
         )}

      _game ->
        {:ok,
         socket
         |> put_flash(:error, gettext("This game is no longer accepting new players"))
         |> push_navigate(to: ~p"/")}
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
  def handle_event("validate", %{"player" => player_params}, socket) do
    merged_params = Map.merge(socket.assigns.form_params, player_params)
    merged_params = Map.put(merged_params, "game_id", socket.assigns.game.id)

    changeset =
      %Player.Player{}
      |> Player.Player.changeset(merged_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket, changeset: changeset, form: to_form(changeset), form_params: merged_params)}
  end

  @impl true
  def handle_event("join", %{"player" => player_params}, socket) do
    game = socket.assigns.game

    # Check if this is the first player (will be the host)
    existing_players = Player.list_players_for_game(game.id)
    is_host = Enum.empty?(existing_players)

    player_params =
      player_params
      |> Map.put("game_id", game.id)
      |> Map.put("game_host", is_host)

    case Player.create_player(player_params) do
      {:ok, player} ->
        # Add player to public chat room
        public_chat_room = Chat.get_public_chat_room(game.id)

        if public_chat_room do
          Chat.add_member_to_chat_room(public_chat_room, player)
        end

        # Broadcast that a player joined
        Phoenix.PubSub.broadcast(CrimeToGo.PubSub, "game:#{game.id}", {:player_joined, player})

        # Redirect host to game show page, other players to lobby
        redirect_path =
          if is_host do
            ~p"/games/#{game.id}"
          else
            ~p"/games/#{game.id}/lobby"
          end

        {:noreply,
         socket
         |> put_flash(
           :info,
           if(is_host,
             do: gettext("Welcome! You are the game host."),
             else: gettext("Successfully joined the game!")
           )
         )
         |> push_navigate(to: redirect_path)}

      {:error, changeset} ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("select_avatar", %{"avatar" => avatar_filename}, socket) do
    changeset =
      socket.assigns.changeset
      |> Player.Player.changeset(%{"avatar_file_name" => avatar_filename})

    {:noreply,
     assign(socket,
       changeset: changeset,
       form: to_form(changeset)
     )}
  end

  # Returns the list of all adventurer avatar filenames that exist in
  # priv/static/images/avatars. These were generated as
  # "adventurer_avatar_01.webp" ... "adventurer_avatar_50.webp".
  #
  # NB: If you ever change the number of generated avatars just update the
  # range below – they follow the same naming scheme.
  defp available_avatars do
    1..50
    |> Enum.map(fn i ->
      i |> Integer.to_string() |> String.pad_leading(2, "0")
    end)
    |> Enum.map(&"adventurer_avatar_#{&1}.webp")
  end

  defp avatar_available?(game_id, avatar_filename) do
    Player.avatar_available?(game_id, avatar_filename)
  end

  defp format_avatar_name(avatar_filename) do
    avatar_filename
    |> String.replace("adventurer_avatar_", "")
    |> String.replace(".webp", "")
    |> String.to_integer()
    |> then(&gettext("Avatar %{number}", number: &1))
  end
end
