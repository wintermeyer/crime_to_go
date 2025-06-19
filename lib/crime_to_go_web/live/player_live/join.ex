defmodule CrimeToGoWeb.PlayerLive.Join do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.{Game, Player, Chat}
  alias CrimeToGo.Shared.Constants

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    handle_resource_not_found(socket, fn ->
      game = Game.get_game!(game_id)

      case validate_game_state(
             socket,
             game,
             "pre_game",
             gettext("This game is no longer accepting new players")
           ) do
        {:ok, socket} ->
          existing_players = Player.list_players_for_game(game_id)
          default_nickname = generate_default_nickname(existing_players, game.lang)

          changeset =
            Player.change_player(%Player.Player{game_id: game_id}, %{
              "nickname" => default_nickname
            })
            |> Map.put(:action, :validate)

          {:ok,
           assign(socket,
             game: game,
             changeset: changeset,
             form: to_form(changeset),
             existing_players: existing_players,
             form_params: %{"nickname" => default_nickname}
           )}

        error_result ->
          error_result
      end
    end)
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
      |> validate_nickname_availability(socket.assigns.game.id)
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

    # Validate nickname availability before creating player
    changeset =
      %Player.Player{}
      |> Player.Player.changeset(player_params)
      |> validate_nickname_availability(game.id)

    case changeset.valid? do
      false ->
        {:noreply, assign(socket, changeset: changeset, form: to_form(changeset))}

      true ->
        case Player.create_player(player_params) do
          {:ok, player} ->
            # Add player to public chat room
            public_chat_room = Chat.get_public_chat_room(game.id)

            if public_chat_room do
              Chat.add_member_to_chat_room(public_chat_room, player)
            end

            # Broadcast that a player joined
            safe_broadcast("game:#{game.id}", {:player_joined, player})

            # Set player cookie for this game using JavaScript
            cookie_name = "player_#{game.id}"
            cookie_value = player.id

            # Redirect host to game show page, other players to lobby
            redirect_path =
              if is_host do
                ~p"/games/#{game.id}"
              else
                ~p"/games/#{game.id}/lobby"
              end

            {:noreply,
             socket
             |> push_event("set_cookie", %{
               name: cookie_name,
               value: cookie_value,
               max_age: 24 * 60 * 60
             })
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

  defp available_avatars do
    Constants.available_avatars()
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

  defp generate_default_nickname(existing_players, game_lang) do
    # Count all existing players and add 1 for the new player
    next_number = length(existing_players) + 1

    # Get the current locale to temporarily switch for translation
    current_locale = Gettext.get_locale(CrimeToGoWeb.Gettext)

    # Temporarily set locale to the game's language for translation
    Gettext.put_locale(CrimeToGoWeb.Gettext, game_lang)

    # Generate the nickname using the game's language
    nickname = gettext("Detective #%{number}", number: next_number)

    # Check if this nickname is already taken (in case of custom detective names)
    existing_nicknames =
      existing_players
      |> Enum.map(& &1.nickname)
      |> MapSet.new()

    final_nickname =
      if MapSet.member?(existing_nicknames, nickname) do
        # If somehow the generated nickname is taken, find the next available number
        Stream.iterate(next_number + 1, &(&1 + 1))
        |> Enum.find(fn i ->
          candidate = gettext("Detective #%{number}", number: i)
          not MapSet.member?(existing_nicknames, candidate)
        end)
        |> then(&gettext("Detective #%{number}", number: &1))
      else
        nickname
      end

    # Restore the original locale
    Gettext.put_locale(CrimeToGoWeb.Gettext, current_locale)

    final_nickname
  end

  defp validate_nickname_availability(changeset, game_id) do
    case Ecto.Changeset.get_field(changeset, :nickname) do
      nil ->
        changeset

      nickname ->
        if Player.nickname_available?(game_id, nickname) do
          changeset
        else
          Ecto.Changeset.add_error(
            changeset,
            :nickname,
            gettext("This detective name is already taken")
          )
        end
    end
  end
end
