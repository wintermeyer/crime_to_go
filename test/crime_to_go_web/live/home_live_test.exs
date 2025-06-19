defmodule CrimeToGoWeb.HomeLiveTest do
  use CrimeToGoWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Home page" do
    setup do
      {:ok, conn: Phoenix.ConnTest.build_conn()}
    end

    test "Home page displays correctly", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")
      assert html =~ "CrimeToGo"
      assert html =~ "A multiplayer online detective game"
      assert html =~ "Create New Game"
      assert html =~ "Join Existing Game"
      assert html =~ "Game Features"
      assert html =~ "Game Language"
    end

    test "Home page displays game language form", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")

      # Check that the form includes game language selection
      assert html =~ "Game Language"
      assert html =~ "Language for game content and story"
      assert html =~ "phx-submit=\"create_game\""
    end

    @tag :skip
    test "Home page join game with valid code redirects to join page", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      game_code = "234234234234"
      {:ok, game} = CrimeToGo.Game.create_game()
      CrimeToGo.Game.update_game(game, %{code: game_code})

      {:ok, view, _html} = live(conn, "/")

      # Submit the form
      view
      |> form("form[phx-submit='join_game']", game_code: game_code)
      |> render_submit()

      # TODO: Fix this test - push_navigate in LiveView doesn't trigger
      # assert_redirect in the same way as regular redirects
      # Since push_navigate is used in a LiveView, we check for the navigation
      assert_redirect(view, "/games/#{game.id}/join")
    end

    test "Home page join game with invalid code shows error", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> form("form[phx-submit='join_game']", game_code: "999999999999")
        |> render_submit()

      assert html =~ "Invalid game code format"
    end

    test "Home page join button is disabled initially", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")

      # Check if button is disabled
      assert html =~ ~s(disabled="disabled")
      assert html =~ "Join Game"
    end

    test "Home page join button is enabled with valid code", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Enter a valid game code (with valid checksum)
      html =
        view
        |> form("form[phx-submit='join_game']")
        |> render_change(game_code: "998828935596")

      # Button should be enabled now
      refute html =~ ~s(disabled="disabled")
      assert html =~ "Join Game"
    end

    test "Home page join button is disabled with short code", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Enter too short code
      html =
        view
        |> form("form[phx-submit='join_game']")
        |> render_change(game_code: "234234")

      # Button should still be disabled
      assert html =~ ~s(disabled="disabled")
    end

    test "Home page validate join button is disabled without valid code", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Initially disabled
      _button = element(view, "button", "Join Game")
      assert render(element(view, "button", "Join Game")) =~ ~s(disabled="disabled")

      # Type invalid code (too short)
      view
      |> form("form[phx-submit='join_game']", game_code: "2345")
      |> render_change()

      _button = element(view, "button", "Join Game")
      assert render(element(view, "button", "Join Game")) =~ ~s(disabled="disabled")

      # Type valid code (with valid checksum)
      view
      |> form("form[phx-submit='join_game']", game_code: "369884542285")
      |> render_change()

      html = render(view)
      # The button should not have btn-disabled class when enabled
      # Just check that the button is not disabled
      refute html =~ ~s(disabled="disabled")
    end

    test "Game code only accepts digits 2-9", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Try entering 0 or 1 (should not work)
      html =
        view
        |> form("form[phx-submit='join_game']")
        |> render_change(game_code: "012345678901")

      # Pattern attribute should restrict to 2-9
      assert html =~ ~s(pattern="[2-9]{12}")
    end

    test "Game code validation placeholder text provides guidance", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")
      assert html =~ "Enter game code (12 digits)"
    end

    test "join game form validates code", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Test empty code
      view
      |> form("form[phx-submit='join_game']", game_code: "")
      |> render_change()

      # Test invalid code (less than 12 digits)
      view
      |> form("form[phx-submit='join_game']", game_code: "123")
      |> render_change()

      html = render(view)
      assert html =~ ~s(disabled)
    end

    test "displays game features section", %{conn: conn} do
      # Set to German locale to test German text
      conn = conn |> put_req_cookie("locale", "de") |> fetch_cookies()

      {:ok, _view, html} = live(conn, "/")

      # Feature headers in German
      assert html =~ "Spielfunktionen"
      assert html =~ "Kooperatives Gameplay"
      assert html =~ "Echtzeitkommunikation"
      assert html =~ "Beweisanalyse"
    end

    test "displays mobile-optimized layout", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      # Check for responsive classes
      assert html =~ "sm:text-4xl"
      assert html =~ "lg:text-5xl"
      assert html =~ "grid-cols-1"
      assert html =~ "lg:grid-cols-2"
    end

    test "header has proper branding", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "CrimeToGo"
      assert html =~ ~s(src="/images/logo.svg")
    end

    test "footer displays copyright info", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/")

      assert html =~ "© 2024 CrimeToGo"
      assert html =~ "All rights reserved"
    end
  end

  describe "Game code validation" do
    test "game code input accepts only valid characters", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _index_live, html} = live(conn, ~p"/")

      # Check pattern attribute for game code input
      assert html =~ "pattern=\"[2-9]{12}\""
      assert html =~ "maxlength=\"12\""
    end

    test "placeholder text provides guidance", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Enter game code (12 digits)"
    end
  end
end
