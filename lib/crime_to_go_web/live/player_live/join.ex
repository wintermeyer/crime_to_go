defmodule CrimeToGoWeb.PlayerLive.Join do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.{Game, Player, Chat}
  alias CrimeToGo.Shared.Constants

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    handle_resource_not_found(socket, fn ->
      game = Game.get_game!(game_id)

      # Check if player already has a cookie for this game
      cookie_name = "player_#{game_id}"
      existing_player = check_existing_player(socket, cookie_name, game_id)

      if existing_player do
        # Player already joined this game - redirect to appropriate page
        redirect_path =
          if existing_player.game_host do
            ~p"/games/#{game_id}/host_dashboard"
          else
            ~p"/games/#{game_id}/lobby"
          end

        {:ok,
         socket
         |> put_flash(:info, gettext("You have already joined this game"))
         |> push_navigate(to: redirect_path)}
      else
        case validate_game_state(
               socket,
               game,
               "pre_game",
               gettext("This game is no longer accepting new players")
             ) do
          {:ok, socket} ->
            existing_players = Player.list_players_for_game(game_id)
            default_nickname = generate_default_nickname(existing_players, game.lang)

            # Find first available avatar
            default_avatar = find_first_available_avatar(game_id)

            changeset =
              Player.change_player(%Player.Player{game_id: game_id}, %{
                "nickname" => default_nickname,
                "avatar_file_name" => default_avatar
              })
              |> Map.put(:action, :validate)

            # Get taken avatars once to avoid multiple queries
            taken_avatars = get_taken_avatars(existing_players)

            # Get a random selection of available avatars, including the default one
            random_avatars =
              get_random_available_avatars_optimized(taken_avatars, 12, default_avatar)

            # Subscribe to game updates for real-time player list updates
            if connected?(socket) do
              Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
            end

            {:ok,
             assign(socket,
               game: game,
               changeset: changeset,
               form: to_form(changeset),
               existing_players: existing_players,
               random_avatars: random_avatars,
               taken_avatars: taken_avatars,
               form_params: %{
                 "nickname" => default_nickname,
                 "avatar_file_name" => default_avatar
               }
             )}

          error_result ->
            error_result
        end
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
      |> Map.put("status", "online")
      |> Map.put("last_seen_at", DateTime.utc_now())

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

            # Redirect host to host dashboard, other players to lobby
            redirect_path =
              if is_host do
                ~p"/games/#{game.id}/host_dashboard"
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
  def handle_event("shuffle_avatars", _params, socket) do
    # Get the currently selected avatar from form params
    current_avatar = socket.assigns.form_params["avatar_file_name"]

    # Use the pre-loaded taken avatars to avoid database queries
    random_avatars =
      get_random_available_avatars_optimized(socket.assigns.taken_avatars, 12, current_avatar)

    {:noreply, assign(socket, random_avatars: random_avatars)}
  end

  @impl true
  def handle_event("select_avatar", %{"avatar" => avatar_filename}, socket) do
    updated_params = Map.put(socket.assigns.form_params, "avatar_file_name", avatar_filename)

    # Include game_id in the changeset params
    changeset_params = Map.put(updated_params, "game_id", socket.assigns.game.id)

    changeset =
      %Player.Player{}
      |> Player.Player.changeset(changeset_params)
      |> validate_nickname_availability(socket.assigns.game.id)
      |> Map.put(:action, :validate)

    # If the selected avatar is not in the current random list, add it
    random_avatars =
      if avatar_filename in socket.assigns.random_avatars do
        socket.assigns.random_avatars
      else
        [avatar_filename | socket.assigns.random_avatars] |> Enum.take(12)
      end

    {:noreply,
     assign(socket,
       changeset: changeset,
       form: to_form(changeset),
       form_params: updated_params,
       random_avatars: random_avatars
     )}
  end

  @impl true
  def handle_info({:player_joined, _player}, socket) do
    # Refresh players list when a new player joins
    existing_players = Player.list_players_for_game(socket.assigns.game.id)
    taken_avatars = get_taken_avatars(existing_players)
    {:noreply, assign(socket, existing_players: existing_players, taken_avatars: taken_avatars)}
  end

  @impl true
  def handle_info({:player_status_changed, _player, _status}, socket) do
    # Refresh players list when player status changes
    existing_players = Player.list_players_for_game(socket.assigns.game.id)
    taken_avatars = get_taken_avatars(existing_players)
    {:noreply, assign(socket, existing_players: existing_players, taken_avatars: taken_avatars)}
  end

  defp available_avatars do
    Constants.available_avatars()
  end

  defp format_avatar_name(avatar_filename) do
    avatar_filename
    |> String.replace("adventurer_avatar_", "")
    |> String.replace(".webp", "")
    |> String.to_integer()
    |> then(&gettext("Avatar %{number}", number: &1))
  end

  defp generate_default_nickname(existing_players, game_lang) do
    # Set the locale temporarily to generate the nickname in the correct language
    current_locale = Gettext.get_locale(CrimeToGoWeb.Gettext)
    Gettext.put_locale(CrimeToGoWeb.Gettext, game_lang)

    # Count all existing players and add 1 for the new player
    next_number = length(existing_players) + 1

    # Generate the nickname using gettext interpolation (e.g., "Detective1", "Detektiv1")
    nickname = gettext("Detective%{number}", number: next_number)

    # Check if this nickname is already taken (case-insensitive)
    existing_nicknames =
      existing_players
      |> Enum.map(&String.downcase(&1.nickname))
      |> MapSet.new()

    final_nickname =
      if MapSet.member?(existing_nicknames, String.downcase(nickname)) do
        # If somehow the generated nickname is taken, find the next available number
        Stream.iterate(next_number + 1, &(&1 + 1))
        |> Enum.find(fn i ->
          candidate = gettext("Detective%{number}", number: i)
          not MapSet.member?(existing_nicknames, String.downcase(candidate))
        end)
        |> then(&gettext("Detective%{number}", number: &1))
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
        if Player.nickname_available_case_insensitive?(game_id, nickname) do
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

  # Helper function to check if player already exists for this game in cookies
  defp check_existing_player(socket, cookie_name, game_id) do
    case get_connect_params(socket) do
      %{} = connect_params ->
        player_id = Map.get(connect_params, cookie_name)

        if player_id do
          # Verify the player exists and belongs to this game
          players = Player.list_players_for_game(game_id)
          Enum.find(players, &(&1.id == player_id))
        else
          nil
        end

      _ ->
        nil
    end
  end

  defp find_first_available_avatar(game_id) do
    # Get all taken avatars in one query
    taken_avatars =
      Player.list_players_for_game(game_id)
      |> get_taken_avatars()

    available_avatars()
    |> Enum.find(fn avatar -> avatar not in taken_avatars end)
  end

  defp get_taken_avatars(players) do
    players
    |> Enum.map(& &1.avatar_file_name)
    |> Enum.reject(&is_nil/1)
    |> MapSet.new()
  end

  defp get_random_available_avatars_optimized(taken_avatars, count, current_avatar) do
    # Get all truly available avatars (not taken by other players)
    available =
      available_avatars()
      |> Enum.filter(fn avatar -> avatar not in taken_avatars end)

    if current_avatar && current_avatar not in available do
      # If current avatar is selected but not in available list, include it
      # This ensures the user can keep their current selection
      ([current_avatar] ++ available)
      |> Enum.shuffle()
      |> Enum.take(count)
    else
      # Normal case: just shuffle available avatars
      available
      |> Enum.shuffle()
      |> Enum.take(count)
      |> then(fn list ->
        # Ensure current avatar is in the list if it exists
        if current_avatar && current_avatar not in list && current_avatar not in taken_avatars do
          [current_avatar | Enum.take(list, count - 1)]
        else
          list
        end
      end)
    end
  end
end
