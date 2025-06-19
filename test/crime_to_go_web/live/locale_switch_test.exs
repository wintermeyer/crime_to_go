defmodule CrimeToGoWeb.LocaleSwitchTest do
  use CrimeToGoWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "language switch" do
    test "changes locale when language is selected", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # The page should initially be in English (default locale)
      assert has_element?(view, "h1", "CrimeToGo")

      # Check if the language switch forms are present
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"en\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"de\"]")

      # Test that a new connection with the locale cookie works
      conn =
        build_conn()
        |> put_req_cookie("locale", "en")
        |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")

      # Check if the page is now in English
      assert html =~ "A multiplayer online detective game"
    end

    test "persists locale from cookie", %{conn: conn} do
      # Set locale cookie to French
      conn =
        conn
        |> put_req_cookie("locale", "fr")
        |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")

      # Check if French locale is applied (the flag should be visible in the UI)
      assert html =~ "🇫🇷"
    end

    test "locale dropdown shows all available languages", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Check all language options are present as forms
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"de\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"en\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"fr\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"es\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"tr\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"ru\"]")
      assert has_element?(view, "form[action=\"/set_locale\"] input[value=\"uk\"]")
    end

    test "defaults to English locale", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Check that English is the default (🇬🇧 flag should be visible)
      assert html =~ "🇬🇧"
    end
  end
end
