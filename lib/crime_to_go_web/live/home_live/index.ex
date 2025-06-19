defmodule CrimeToGoWeb.HomeLive.Index do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Chat
  alias CrimeToGoWeb.Plugs.Locale

  @impl true
  def mount(_params, _session, socket) do
    current_locale = socket.assigns[:locale] || Locale.default_locale()
    create_changeset = Game.change_game(%Game.Game{}, %{"lang" => current_locale})

    # Initialize with empty games - will load after connection
    socket = 
      assign(socket,
        game_code: "",
        join_error: nil,
        form: to_form(%{}),
        create_form: to_form(create_changeset),
        current_locale: current_locale,
        my_games: [],
        show_my_games: false
      )

    # Load games after LiveView connects (when cookies are available)
    if connected?(socket) do
      {my_hosted_games, my_player_games, player_cookies} = get_my_games_with_cookies(socket)
      
      {:ok, assign(socket, 
        my_games: my_hosted_games, 
        show_my_games: length(my_hosted_games) > 0,
        my_player_games: my_player_games,
        show_my_player_games: length(my_player_games) > 0,
        player_cookies: player_cookies
      )}
    else
      {:ok, assign(socket, player_cookies: %{}, my_player_games: [], show_my_player_games: false)}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", %{"game" => game_params}, socket) do
    case Game.create_game(game_params) do
      {:ok, game} ->
        # Create a public chat room for the game
        {:ok, _chat_room} = Chat.create_public_chat_room(game)

        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/join")}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Failed to create game. Please try again."))
         |> assign(create_form: to_form(changeset))}
    end
  end

  @impl true
  def handle_event("validate_create", %{"game" => game_params}, socket) do
    changeset =
      %Game.Game{}
      |> Game.change_game(game_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, create_form: to_form(changeset))}
  end

  @impl true
  def handle_event("join_game", %{"game_code" => game_code}, socket) do
    case Game.get_game_by_code(game_code) do
      nil ->
        {:noreply, assign(socket, join_error: gettext("Game code not found"))}

      game ->
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/join")}
    end
  end

  @impl true
  def handle_event("validate_join", %{"game_code" => game_code}, socket) do
    {:noreply, assign(socket, game_code: game_code, join_error: nil)}
  end

  @impl true
  def handle_event("rejoin_my_game", %{"game_id" => game_id}, socket) do
    # Verify this is actually a game where the user is the host
    my_games = socket.assigns.my_games
    game = Enum.find(my_games, &(&1.id == game_id))

    if game do
      # Get the current player from stored cookies
      cookie_name = "player_#{game_id}"
      player_cookies = socket.assigns.player_cookies
      player_id = Map.get(player_cookies, cookie_name)
      current_player = if player_id, do: Enum.find(game.players, &(&1.id == player_id))

      if current_player do
        # Redirect directly to appropriate game page (host goes to show, others to lobby)
        redirect_path =
          if current_player.game_host do
            ~p"/games/#{game.id}"
          else
            ~p"/games/#{game.id}/lobby"
          end

        {:noreply, push_navigate(socket, to: redirect_path)}
      else
        # Cookie exists but player not found - redirect to join to recreate player
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/join")}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("You can only rejoin games you created"))}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, gettext("Game not found"))}
  end

  @impl true
  def handle_event("rejoin_player_game", %{"game_id" => game_id}, socket) do
    # Verify this is actually a game where the user is a player
    my_player_games = socket.assigns.my_player_games
    game = Enum.find(my_player_games, &(&1.id == game_id))

    if game do
      # Get the current player from stored cookies
      cookie_name = "player_#{game_id}"
      player_cookies = socket.assigns.player_cookies
      player_id = Map.get(player_cookies, cookie_name)
      current_player = if player_id, do: Enum.find(game.players, &(&1.id == player_id))

      if current_player do
        # Regular players always go to lobby
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/lobby")}
      else
        # Cookie exists but player not found - redirect to join to recreate player
        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/join")}
      end
    else
      {:noreply, put_flash(socket, :error, gettext("You can only rejoin games you are part of"))}
    end
  rescue
    Ecto.NoResultsError ->
      {:noreply, put_flash(socket, :error, gettext("Game not found"))}
  end


  defp language_options do
    CrimeToGoWeb.LocaleHelpers.locale_names()
    |> Enum.map(fn {code, name} ->
      {name, code}
    end)
    |> Enum.sort_by(fn {name, _code} -> name end)
  end

  # Helper function to get games where the user is either host or player based on cookies
  # Returns {hosted_games, player_games, player_cookies}
  defp get_my_games_with_cookies(socket) do
    case get_connect_params(socket) do
      %{} = connect_params ->
        # Find all player cookies (they start with "player_")
        player_cookies =
          connect_params
          |> Enum.filter(fn {key, _value} -> String.starts_with?(key, "player_") end)
          |> Enum.map(fn {key, player_id} ->
            game_id = String.replace_prefix(key, "player_", "")
            {"player_#{game_id}", player_id}
          end)
          |> Enum.into(%{})

        # For each cookie, check if the player exists in a pending game
        {hosted_games, player_games} = player_cookies
        |> Enum.map(fn {cookie_name, player_id} ->
          game_id = String.replace_prefix(cookie_name, "player_", "")
          try do
            game = Game.get_game_with_players!(game_id)
            player = Enum.find(game.players, &(&1.id == player_id))

            # Only include if player exists, is valid, and game is pending
            if player && game.state == "pre_game" do
              {game, player}
            else
              nil
            end
          rescue
            Ecto.NoResultsError -> 
              # Game no longer exists - stale cookie
              nil
          end
        end)
        |> Enum.filter(& &1)
        |> Enum.split_with(fn {_game, player} -> player.game_host end)

        # Extract just the games from the tuples
        hosted_games = hosted_games |> Enum.map(fn {game, _player} -> game end)
        player_games = player_games |> Enum.map(fn {game, _player} -> game end)

        {hosted_games, player_games, player_cookies}

      _ ->
        {[], [], %{}}
    end
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        gettext("just now")

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        ngettext("%{count} minute ago", "%{count} minutes ago", minutes, count: minutes)

      diff_seconds < 86400 ->
        hours = div(diff_seconds, 3600)
        ngettext("%{count} hour ago", "%{count} hours ago", hours, count: hours)

      true ->
        days = div(diff_seconds, 86400)
        ngettext("%{count} day ago", "%{count} days ago", days, count: days)
    end
  end
end
