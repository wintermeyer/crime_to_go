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
end
