defmodule CrimeToGoWeb.PlayerLive.JoinTest do
  use CrimeToGoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias CrimeToGo.Game

  setup do
    {:ok, game} = Game.create_game(%{invitation_code: "test123"})
    %{game: game}
  end

  test "join form disables button until valid, enables and submits when valid", %{
    conn: conn,
    game: game
  } do
    {:ok, view, _html} = live(conn, "/games/#{game.id}/join")

    # Button should be disabled initially
    assert render(view) =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in nickname only
    html =
      view |> form("form[phx-submit='join']", player: %{nickname: "Sherlock"}) |> render_change()

    assert html =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in avatar only
    html =
      view
      |> form("form[phx-submit='join']", player: %{avatar_file_name: "adventurer_avatar_01.webp"})
      |> render_change()

    assert html =~ ~r/<button[^>]*disabled[^>]*>/

    # Fill in both nickname and avatar (simulate user input)
    html =
      view
      |> form("form[phx-submit='join']",
        player: %{nickname: "Sherlock", avatar_file_name: "adventurer_avatar_01.webp"}
      )
      |> render_change()

    tree = Floki.parse_document!(html)
    # Find the button that contains "Join Game as Detective" text
    buttons = Floki.find(tree, "button[type=submit]")

    join_button =
      Enum.find(buttons, fn button ->
        Floki.text(button) =~ "Join Game as Detective"
      end)

    refute Floki.attribute(join_button, "disabled") != []

    # Submit the form
    view
    |> form("form[phx-submit='join']",
      player: %{nickname: "Sherlock", avatar_file_name: "adventurer_avatar_01.webp"}
    )
    |> render_submit()
  end
end
