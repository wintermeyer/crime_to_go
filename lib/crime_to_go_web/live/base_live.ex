defmodule CrimeToGoWeb.BaseLive do
  @moduledoc """
  Base LiveView module that provides common functionality for all LiveViews.

  This module contains shared patterns, error handling, and utilities that
  are commonly needed across LiveView modules, promoting consistency and
  reducing code duplication.
  """

  use CrimeToGoWeb, :verified_routes

  defmacro __using__(_opts) do
    quote do
      import CrimeToGoWeb.LocaleHelpers
      import CrimeToGoWeb.BaseLive
      use CrimeToGoWeb, :verified_routes
    end
  end

  @doc """
  Handles common Ecto.NoResultsError pattern for game/resource not found.

  ## Examples

      def mount(%{"game_id" => game_id}, _session, socket) do
        handle_resource_not_found(socket, fn ->
          game = CrimeToGo.Game.get_game!(game_id)
          {:ok, assign(socket, game: game)}
        end)
      end
  """
  def handle_resource_not_found(socket, fun) do
    try do
      fun.()
    rescue
      Ecto.NoResultsError ->
        {:ok,
         socket
         |> Phoenix.LiveView.put_flash(:error, "Resource not found")
         |> Phoenix.LiveView.push_navigate(to: "/")}
    end
  end

  @doc """
  Handles common pattern for validating game state and redirecting if invalid.

  ## Examples

      validate_game_state(socket, game, "pre_game", "Game is no longer accepting players")
  """
  def validate_game_state(socket, game, expected_state, error_message) do
    if game.state == expected_state do
      {:ok, socket}
    else
      {:ok,
       socket
       |> Phoenix.LiveView.put_flash(:error, error_message)
       |> Phoenix.LiveView.push_navigate(to: ~p"/")}
    end
  end

  @doc """
  Broadcasts an event and handles any errors gracefully.

  ## Examples

      safe_broadcast("game:123", {:player_joined, player})
  """
  def safe_broadcast(topic, message) do
    CrimeToGo.Shared.broadcast_event(topic, message)
  end

  @doc """
  Common pattern for handling changeset validation in LiveViews.

  ## Examples

      handle_changeset_validation(socket, changeset, params)
  """
  def handle_changeset_validation(socket, changeset, params) do
    updated_changeset =
      changeset
      |> Map.put(:action, :validate)

    {:noreply,
     Phoenix.Component.assign(socket,
       changeset: updated_changeset,
       form: Phoenix.Component.to_form(updated_changeset),
       form_params: params
     )}
  end

  @doc """
  Shows the end game confirmation modal.
  Only available to game hosts.
  """
  def handle_show_end_game_modal(socket) do
    current_player = socket.assigns[:current_player]
    
    if current_player && current_player.game_host do
      {:noreply, Phoenix.Component.assign(socket, show_end_game_modal: true)}
    else
      {:noreply, 
       socket
       |> Phoenix.LiveView.put_flash(:error, "Only the game host can end the game")
      }
    end
  end

  @doc """
  Hides the end game confirmation modal.
  """
  def handle_hide_end_game_modal(socket) do
    {:noreply, Phoenix.Component.assign(socket, show_end_game_modal: false)}
  end

  @doc """
  Confirms ending the game and performs all necessary cleanup.
  """
  def handle_confirm_end_game(socket) do
    current_player = socket.assigns[:current_player]
    game = socket.assigns[:game]
    
    if current_player && current_player.game_host && game do
      case CrimeToGo.Game.end_game(game) do
        {:ok, updated_game} ->
          # Broadcast to all players that the game has ended
          safe_broadcast("game:#{game.id}", {:game_ended, updated_game})
          
          # Clear all player cookies via JavaScript
          socket_with_cleanup = 
            socket
            |> Phoenix.LiveView.push_event("clear_player_cookies", %{})
            |> Phoenix.LiveView.put_flash(:info, "Game ended successfully. All players have been notified.")
            |> Phoenix.LiveView.push_navigate(to: ~p"/")
          
          {:noreply, socket_with_cleanup}
          
        {:error, _changeset} ->
          {:noreply,
           socket
           |> Phoenix.Component.assign(show_end_game_modal: false)
           |> Phoenix.LiveView.put_flash(:error, "Unable to end game. Please try again.")
          }
      end
    else
      {:noreply,
       socket
       |> Phoenix.Component.assign(show_end_game_modal: false)
       |> Phoenix.LiveView.put_flash(:error, "Only the game host can end the game")
      }
    end
  end

  # ============================================================================
  # PLAYER & GAME AUTHENTICATION HELPERS
  # ============================================================================

  @doc """
  Gets the current player for a game from cookies.
  
  ## Examples
  
      current_player = get_current_player_for_game(socket, game_id)
      if current_player do
        # Player is authenticated
      else
        # Redirect to join page
      end
  """
  def get_current_player_for_game(socket, game_id) do
    cookie_name = "player_#{game_id}"
    players = CrimeToGo.Player.list_active_players_for_game(game_id)
    
    case Phoenix.LiveView.get_connect_params(socket) do
      %{} = connect_params ->
        player_id = Map.get(connect_params, cookie_name)
        if player_id, do: Enum.find(players, &(&1.id == player_id))
      _ ->
        nil
    end
  end

  @doc """
  Requires that a player is authenticated for a game.
  If not authenticated, redirects to the join page.
  
  ## Examples
  
      case require_player_authentication(socket, game_id) do
        {:ok, socket, current_player} -> 
          # Continue with authenticated player
        {:redirect, socket} -> 
          # Handle redirect in mount return
      end
  """
  def require_player_authentication(socket, game_id, redirect_message \\ nil) do
    message = redirect_message || "Please join the game first"
    
    case get_current_player_for_game(socket, game_id) do
      nil ->
        redirect_socket = 
          socket
          |> Phoenix.LiveView.put_flash(:info, message)
          |> Phoenix.LiveView.push_navigate(to: ~p"/games/#{game_id}/join")
        {:redirect, redirect_socket}
      
      current_player ->
        {:ok, socket, current_player}
    end
  end

  @doc """
  Requires that the current player has host permissions.
  If not a host, redirects to the lobby.
  """
  def require_host_permissions(socket, current_player, game_id, error_message \\ nil) do
    message = error_message || "Only hosts can access this page"
    
    if current_player && current_player.game_host do
      {:ok, socket}
    else
      redirect_socket = 
        socket
        |> Phoenix.LiveView.put_flash(:error, message)
        |> Phoenix.LiveView.push_navigate(to: ~p"/games/#{game_id}/lobby")
      {:redirect, redirect_socket}
    end
  end

  @doc """
  Common mount pattern for game-related LiveViews.
  
  Handles:
  - Game loading with error handling
  - Player authentication 
  - Optional host permission checking
  - PubSub subscriptions
  
  ## Examples
  
      def mount(%{"id" => game_id}, _session, socket) do
        mount_game_liveview(socket, game_id, require_host: true)
      end
  """
  def mount_game_liveview(socket, game_id, opts \\ []) do
    require_host = Keyword.get(opts, :require_host, false)
    
    handle_resource_not_found(socket, fn ->
      game = CrimeToGo.Game.get_game!(game_id)
      
      if Phoenix.LiveView.connected?(socket) do
        # WebSocket connected - handle authentication and subscriptions
        case require_player_authentication(socket, game_id) do
          {:redirect, redirect_socket} ->
            {:ok, redirect_socket}
          
          {:ok, socket, current_player} ->
            # Check host permissions if required
            case require_host_check(socket, current_player, game_id, require_host) do
              {:redirect, redirect_socket} ->
                {:ok, redirect_socket}
              
              {:ok, socket} ->
                # Set up subscriptions and assign data
                socket = 
                  socket
                  |> subscribe_to_game_events(game_id, current_player.id)
                  |> Phoenix.Component.assign(
                    game: game,
                    current_player: current_player
                  )
                
                {:ok, socket}
            end
        end
      else
        # Initial HTTP mount - just load skeleton
        {:ok, Phoenix.Component.assign(socket, game: game)}
      end
    end)
  end

  # ============================================================================
  # PUBSUB HELPERS
  # ============================================================================

  @doc """
  Subscribes to common game and player events.
  """
  def subscribe_to_game_events(socket, game_id, player_id) do
    if Phoenix.LiveView.connected?(socket) do
      Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")
      Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "player:#{player_id}")
    end
    socket
  end

  @doc """
  Subscribes to chat room events for a game.
  """
  def subscribe_to_chat_events(socket, game_id, current_player) do
    if Phoenix.LiveView.connected?(socket) do
      public_chat_room = CrimeToGo.Chat.get_public_chat_room(game_id)
      
      if public_chat_room && current_player do
        # Ensure player is a member of the chat room
        unless CrimeToGo.Chat.member_of_chat_room?(public_chat_room.id, current_player.id) do
          CrimeToGo.Chat.add_member_to_chat_room(public_chat_room, current_player)
        end
        
        Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "chat_room:#{public_chat_room.id}")
        
        socket
        |> Phoenix.Component.assign(public_chat_room: public_chat_room)
      else
        socket
      end
    else
      socket
    end
  end

  @doc """
  Refreshes the player list for a game.
  Common pattern used in handle_info callbacks.
  """
  def refresh_player_list(socket) do
    players = CrimeToGo.Player.list_active_players_for_game(socket.assigns.game.id)
    {:noreply, Phoenix.Component.assign(socket, players: players)}
  end

  # ============================================================================
  # MACROS FOR COMMON HANDLE_INFO PATTERNS
  # ============================================================================

  @doc """
  Generates common handle_info patterns for player list updates.
  
  ## Usage
  
      use CrimeToGoWeb.BaseLive
      handle_player_list_updates()
  """
  defmacro handle_player_list_updates do
    quote do
      def handle_info({:player_joined, _player}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end

      def handle_info({:player_status_changed, _player, _status}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end

      def handle_info({:status_changed, _player, _status}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end
    end
  end

  @doc """
  Generates common handle_info patterns for game ending and player kicks.
  
  ## Usage
  
      use CrimeToGoWeb.BaseLive
      handle_game_ending_events()
  """
  defmacro handle_game_ending_events do
    quote do
      def handle_info({:game_ended, _game}, socket) do
        {:noreply,
         socket
         |> Phoenix.LiveView.push_event("clear_player_cookies", %{})
         |> Phoenix.LiveView.put_flash(:info, "The game has been ended by the host.")
         |> Phoenix.LiveView.push_navigate(to: ~p"/")}
      end

      def handle_info({:kicked_from_game, host_name}, socket) do
        {:noreply,
         socket
         |> Phoenix.LiveView.push_event("clear_player_cookies", %{})
         |> Phoenix.LiveView.put_flash(:error, "You have been kicked from the game by host #{host_name}.")
         |> Phoenix.LiveView.push_navigate(to: ~p"/")}
      end

      def handle_info({:warning_from_host, host_name}, socket) do
        {:noreply,
         socket
         |> Phoenix.LiveView.put_flash(:error, "⚠️ WARNING from host #{host_name}: Please follow the game rules or you may be kicked!")}
      end
    end
  end

  @doc """
  Generates common handle_info patterns for promotion/demotion events.
  
  ## Usage
  
      use CrimeToGoWeb.BaseLive  
      handle_host_promotion_events()
  """
  defmacro handle_host_promotion_events do
    quote do
      def handle_info({:player_promoted_to_host, _player}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end

      def handle_info({:player_demoted_from_host, _player}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end

      def handle_info({:player_kicked, _player}, socket) do
        CrimeToGoWeb.BaseLive.refresh_player_list(socket)
      end
    end
  end

  @doc """
  Generates terminate callback that sets player offline.
  
  ## Usage
  
      use CrimeToGoWeb.BaseLive
      handle_player_offline_on_terminate()
  """
  defmacro handle_player_offline_on_terminate do
    quote do
      @impl true
      def terminate(_reason, socket) do
        case socket.assigns[:current_player] do
          nil -> :ok
          current_player -> CrimeToGo.Player.set_player_offline(current_player)
        end
        :ok
      end
    end
  end

  # ============================================================================
  # PRIVATE HELPERS
  # ============================================================================

  defp require_host_check(socket, current_player, game_id, true) do
    require_host_permissions(socket, current_player, game_id)
  end

  defp require_host_check(socket, _current_player, _game_id, false) do
    {:ok, socket}
  end
end
