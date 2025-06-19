defmodule CrimeToGoWeb.Plugs.Locale do
  @moduledoc """
  Plug to handle locale detection and switching.

  Supports: German (default), English, French, Spanish, Turkish, Russian, Ukrainian
  """
  import Plug.Conn

  @supported_locales ~w(de en fr es tr ru uk)
  @default_locale "en"

  def init(opts), do: opts

  def call(conn, _opts) do
    locale =
      get_locale_from_cookie(conn) || get_locale_from_session(conn) ||
        get_locale_from_accept_language(conn) || @default_locale

    Gettext.put_locale(CrimeToGoWeb.Gettext, locale)

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
  end

  defp get_locale_from_cookie(conn) do
    conn
    |> fetch_cookies()
    |> Map.get(:cookies, %{})
    |> Map.get("locale")
    |> case do
      locale when locale in @supported_locales -> locale
      _ -> nil
    end
  end

  defp get_locale_from_session(conn) do
    locale = get_session(conn, :locale)
    if locale in @supported_locales, do: locale, else: nil
  end

  defp get_locale_from_accept_language(conn) do
    case get_req_header(conn, "accept-language") do
      [accept_language | _] ->
        accept_language
        |> String.split(",")
        |> Enum.map(&parse_language_tag/1)
        |> Enum.sort_by(fn {_tag, q} -> q end, :desc)
        |> Enum.find_value(fn {tag, _q} ->
          locale = String.downcase(String.slice(tag, 0, 2))
          if locale in @supported_locales, do: locale, else: nil
        end)

      _ ->
        nil
    end
  end

  defp parse_language_tag(tag) do
    case String.split(tag, ";q=") do
      [tag] -> {String.trim(tag), 1.0}
      [tag, q] -> {String.trim(tag), parse_quality(q)}
    end
  end

  defp parse_quality(q) do
    case Float.parse(q) do
      {quality, _} -> quality
      :error -> 1.0
    end
  end

  def put_locale(conn, locale) when locale in @supported_locales do
    Gettext.put_locale(CrimeToGoWeb.Gettext, locale)

    conn
    |> put_session(:locale, locale)
    |> assign(:locale, locale)
    # 1 year
    |> put_resp_cookie("locale", locale, max_age: 31_536_000)
  end

  def put_locale(conn, _), do: conn

  def supported_locales, do: @supported_locales
  def default_locale, do: @default_locale
end
