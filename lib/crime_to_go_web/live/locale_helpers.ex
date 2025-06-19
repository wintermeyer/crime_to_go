defmodule CrimeToGoWeb.LocaleHelpers do
  @moduledoc """
  Helper functions for locale management in LiveViews.
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

  def locale_names do
    %{
      "de" => "Deutsch",
      "en" => "English",
      "fr" => "Français",
      "es" => "Español",
      "tr" => "Türkçe",
      "ru" => "Русский",
      "uk" => "Українська"
    }
  end

  def current_locale_name(locale), do: Map.get(locale_names(), locale, "English")

  def locale_flag(locale) do
    case locale do
      "de" -> "🇩🇪"
      "en" -> "🇬🇧"
      "fr" -> "🇫🇷"
      "es" -> "🇪🇸"
      "tr" -> "🇹🇷"
      "ru" -> "🇷🇺"
      "uk" -> "🇺🇦"
      _ -> "🌐"
    end
  end
end
