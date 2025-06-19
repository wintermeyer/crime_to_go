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
    
    {:ok,
     assign(socket,
       game_code: "",
       join_error: nil,
       form: to_form(%{}),
       create_form: to_form(create_changeset),
       current_locale: current_locale
     )}
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

  defp language_options do
    CrimeToGoWeb.LocaleHelpers.locale_names()
    |> Enum.map(fn {code, name} -> 
      {name, code}
    end)
    |> Enum.sort_by(fn {name, _code} -> name end)
  end
end
