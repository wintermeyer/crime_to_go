defmodule CrimeToGoWeb.LocaleHelpers do
  @moduledoc """
  Helper functions for locale management in LiveViews.

  This module provides utilities for handling internationalization across
  the application, including locale detection, validation, and display helpers.
  It integrates with the Plug.Locale plug to maintain consistent locale
  handling throughout the user session.
  """

  alias CrimeToGoWeb.Plugs.Locale
  alias CrimeToGo.Player

  def on_mount(:default, params, session, socket) do
    locale = Map.get(session, "locale", Locale.default_locale())

    socket =
      if locale in Locale.supported_locales() do
        Gettext.put_locale(CrimeToGoWeb.Gettext, locale)
        Phoenix.Component.assign(socket, locale: locale)
      else
        Gettext.put_locale(CrimeToGoWeb.Gettext, Locale.default_locale())
        Phoenix.Component.assign(socket, locale: Locale.default_locale())
      end

    # Check for current player based on route params and cookies
    socket = assign_current_player(socket, params)

    {:cont, socket}
  end

  def on_mount(:player_status_tracking, _params, _session, socket) do
    {:cont, socket}
  end

  defp assign_current_player(socket, params) do
    # Try to get game_id from params
    game_id = params["game_id"] || params["id"]

    if game_id && Phoenix.LiveView.connected?(socket) do
      cookie_name = "player_#{game_id}"

      case Phoenix.LiveView.get_connect_params(socket) do
        %{} = connect_params ->
          player_id = Map.get(connect_params, cookie_name)

          if player_id do
            # Verify the player exists and belongs to this game
            players = Player.list_active_players_for_game(game_id)
            current_player = Enum.find(players, &(&1.id == player_id))

            if current_player do
              # Set player as online when they connect
              {:ok, updated_player} = Player.set_player_online(current_player)

              # Subscribe to player status updates
              Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "player:#{updated_player.id}")
              Phoenix.PubSub.subscribe(CrimeToGo.PubSub, "game:#{game_id}")

              # Track this player for cleanup on disconnect
              Process.put(:current_player_id, updated_player.id)

              Phoenix.Component.assign(socket, current_player: updated_player)
            else
              Phoenix.Component.assign(socket, current_player: nil)
            end
          else
            Phoenix.Component.assign(socket, current_player: nil)
          end

        _ ->
          Phoenix.Component.assign(socket, current_player: nil)
      end
    else
      Phoenix.Component.assign(socket, current_player: nil)
    end
  end

  @doc """
  Returns a map of locale codes to their native language names.

  This provides user-friendly display names for each supported language,
  shown in the language's native script for better UX.
  """
  @spec locale_names() :: %{String.t() => String.t()}
  def locale_names do
    %{
      "de" => "Deutsch",
      "en" => "English",
      "fr" => "Français",
      "es" => "Español",
      "it" => "Italiano",
      "tr" => "Türkçe",
      "ru" => "Русский",
      "uk" => "Українська"
    }
  end

  @doc """
  Gets the display name for a given locale code.

  ## Examples

      iex> current_locale_name("de")
      "Deutsch"
      
      iex> current_locale_name("invalid")
      "English"
  """
  @spec current_locale_name(String.t()) :: String.t()
  def current_locale_name(locale), do: Map.get(locale_names(), locale, "English")

  @doc """
  Gets the flag emoji for a given locale code.

  Returns a default globe emoji for unknown locales.

  ## Examples

      iex> locale_flag("de")
      "🇩🇪"
      
      iex> locale_flag("unknown")
      "🌐"
  """
  @spec locale_flag(String.t()) :: String.t()
  def locale_flag(locale) do
    case locale do
      "de" -> "🇩🇪"
      "en" -> "🇬🇧"
      "fr" -> "🇫🇷"
      "es" -> "🇪🇸"
      "it" -> "🇮🇹"
      "tr" -> "🇹🇷"
      "ru" -> "🇷🇺"
      "uk" -> "🇺🇦"
      _ -> "🌐"
    end
  end
end
