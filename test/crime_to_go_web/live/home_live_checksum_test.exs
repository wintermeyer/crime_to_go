defmodule CrimeToGoWeb.HomeLiveChecksumTest do
  use CrimeToGoWeb.ConnCase

  import Phoenix.LiveViewTest
  alias CrimeToGo.{Game, Chat}
  alias CrimeToGo.Shared.GameCode

  describe "game code validation with checksum" do
    test "invalid checksum shows format error without database lookup", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Use a code with invalid checksum (12 digits, valid digits, but wrong checksum)
      # This will fail checksum validation
      invalid_code = "234565432345"

      html =
        view
        |> form("form[phx-submit='join_game']", game_code: invalid_code)
        |> render_submit()

      assert html =~ "Invalid game code format"
    end

    test "valid checksum but non-existent game shows not found error", %{conn: conn} do
      # Set to English locale  
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Generate a valid game code that doesn't exist in database
      valid_but_nonexistent_code = GameCode.generate()

      html =
        view
        |> form("form[phx-submit='join_game']", game_code: valid_but_nonexistent_code)
        |> render_submit()

      # This should pass checksum validation but fail database lookup
      assert html =~ "Game code not found"
    end

    test "valid checksum with existing game redirects correctly", %{conn: conn} do
      # Create a game first
      {:ok, game} = Game.create_game(%{"lang" => "en"})
      {:ok, _chat_room} = Chat.create_public_chat_room(game)

      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Submit the form and expect a redirect
      result =
        view
        |> form("form[phx-submit='join_game']", game_code: game.game_code)
        |> render_submit()

      # Should redirect to the join page
      assert {:error, {:live_redirect, %{to: redirect_path}}} = result
      assert String.starts_with?(redirect_path, "/games/")
      assert String.ends_with?(redirect_path, "/join")
    end

    test "validation during typing shows format error for complete invalid codes", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Type an invalid code (contains excluded digits)
      html =
        view
        # Contains 0, 1
        |> form("form[phx-change='validate_join']", game_code: "012345678901")
        |> render_change()

      assert html =~ "Invalid game code format"
    end

    test "validation during typing doesn't show error for incomplete codes", %{conn: conn} do
      # Set to English locale
      conn = conn |> put_req_cookie("locale", "en") |> fetch_cookies()

      {:ok, view, _html} = live(conn, "/")

      # Type a partial code (less than 12 digits)
      html =
        view
        |> form("form[phx-change='validate_join']", game_code: "12345")
        |> render_change()

      # Should not show error while user is still typing
      refute html =~ "Invalid game code format"
    end
  end
end
