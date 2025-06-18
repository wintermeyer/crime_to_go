defmodule CrimeToGoWeb.HomeLiveTest do
  use CrimeToGoWeb.ConnCase

  import Phoenix.LiveViewTest
  alias CrimeToGo.Game

  describe "Home page" do
    test "displays home page content", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "CrimeToGo"
      assert html =~ "multiplayer online detective game"
      assert html =~ "Create New Game"
      assert html =~ "Join Existing Game"
    end

    test "create new game redirects to join page", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      assert index_live
             |> element("button", "Create Game")
             |> render_click()

      # Should have created a game and redirected to join page
      games = Game.list_games()
      assert length(games) == 1
      game = List.first(games)

      assert_redirected(index_live, ~p"/games/#{game.id}/join")
    end

    test "join game with valid code redirects to join page", %{conn: conn} do
      # Create a game first
      {:ok, game} = Game.create_game(%{invitation_code: "test123"})

      {:ok, index_live, _html} = live(conn, ~p"/")

      # Enter game code and submit
      index_live
      |> form("form", %{game_code: game.game_code})
      |> render_submit()

      assert_redirected(index_live, ~p"/games/#{game.id}/join")
    end

    test "join game with invalid code shows error", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      # Enter invalid game code and submit
      index_live
      |> form("form", %{game_code: "123456789012"})
      |> render_submit()

      # Should show error message
      html = render(index_live)
      assert html =~ "Game code not found"
    end

    test "validate join updates game code", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/")

      # Type in game code input
      index_live
      |> form("form", %{game_code: "123456789"})
      |> render_change()

      # Check that the game code state is updated
      assert has_element?(index_live, "input[value='123456789']")
    end

    test "join button is disabled when game code is not 12 digits", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      # Button should be disabled by default (empty game code)
      assert html =~ "disabled"
    end

    test "displays game features section", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Game Features"
      assert html =~ "Collaborative Gameplay"
      assert html =~ "Real-time Communication"
      assert html =~ "Evidence Analysis"
    end

    test "responsive design elements are present", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      # Check for mobile-first responsive classes
      assert html =~ "md:grid-cols-2"
      assert html =~ "md:grid-cols-3"
      assert html =~ "max-w-4xl"
    end

    test "dark mode classes are present", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      # Check for dark mode classes
      assert html =~ "dark:from-gray-900"
      assert html =~ "dark:text-white"
      assert html =~ "dark:bg-gray-800"
    end
  end

  describe "Game code validation" do
    test "game code input accepts only valid characters", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      # Check pattern attribute for game code input
      assert html =~ "pattern=\"[2-9]{12}\""
      assert html =~ "maxlength=\"12\""
    end

    test "placeholder text provides guidance", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/")

      assert html =~ "Enter game code (12 digits)"
    end
  end
end
