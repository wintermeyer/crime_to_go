defmodule CrimeToGoWeb.HomeLive.Index do
  use CrimeToGoWeb, :live_view
  use CrimeToGoWeb.BaseLive

  alias CrimeToGo.Game
  alias CrimeToGo.Chat

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       game_code: "",
       join_error: nil,
       form: to_form(%{})
     )}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_game", _params, socket) do
    case Game.create_game() do
      {:ok, game} ->
        # Create a public chat room for the game
        {:ok, _chat_room} = Chat.create_public_chat_room(game)

        {:noreply, push_navigate(socket, to: ~p"/games/#{game.id}/join")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, gettext("Failed to create game. Please try again."))}
    end
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
end
