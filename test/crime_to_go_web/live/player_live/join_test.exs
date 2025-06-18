defmodule CrimeToGoWeb.PlayerLive.JoinTest do
  use CrimeToGoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias CrimeToGo.{Game, Player}

  setup do
    {:ok, game} = Game.create_game(%{invitation_code: "test123"})
    %{game: game}
  end

  test "join form disables button until valid, enables and submits when valid", %{conn: conn, game: game} do
    {:ok, view, html} = live(conn, "/games/#{game.id}/join")
    IO.puts(html)
    render(view)

    # Button should be disabled initially
    assert render(view) =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in nickname only
    html = view |> form("form", player: %{nickname: "Sherlock"}) |> render_change()
    assert html =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in avatar only
    html = view |> form("form", player: %{avatar_file_name: "adventurer_avatar_01.webp"}) |> render_change()
    assert html =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in both nickname and avatar (simulate user input)
    html = view |> form("form", player: %{nickname: "Sherlock", avatar_file_name: "adventurer_avatar_01.webp"}) |> render_change()
    tree = Floki.parse_document!(html)
    [button] = Floki.find(tree, "button[type=submit]")
    refute Floki.attribute(button, "disabled") != []

    # Submit the form
    view |> form("form", player: %{nickname: "Sherlock", avatar_file_name: "adventurer_avatar_01.webp"}) |> render_submit()
  end
end 