defmodule CrimeToGoWeb.LocaleHelpers do
  @moduledoc """
  Helper functions for locale management in LiveViews.

  This module provides utilities for handling internationalization across
  the application, including locale detection, validation, and display helpers.
  It integrates with the Plug.Locale plug to maintain consistent locale
  handling throughout the user session.
  """

  alias CrimeToGoWeb.Plugs.Locale

  def on_mount(:default, _params, session, socket) do
    locale = Map.get(session, "locale", Locale.default_locale())

    if locale in Locale.supported_locales() do
      Gettext.put_locale(CrimeToGoWeb.Gettext, locale)
      {:cont, Phoenix.Component.assign(socket, locale: locale)}
    else
      Gettext.put_locale(CrimeToGoWeb.Gettext, Locale.default_locale())
      {:cont, Phoenix.Component.assign(socket, locale: Locale.default_locale())}
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
