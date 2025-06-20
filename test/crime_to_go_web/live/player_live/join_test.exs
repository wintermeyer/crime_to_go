defmodule CrimeToGoWeb.PlayerLive.JoinTest do
  use CrimeToGoWeb.ConnCase
  import Phoenix.LiveViewTest

  alias CrimeToGo.Game

  setup do
    {:ok, game} = Game.create_game(%{invitation_code: "test123"})
    %{game: game}
  end

  test "join form has pre-selected nickname and avatar, can be submitted immediately", %{
    conn: conn,
    game: game
  } do
    {:ok, view, html} = live(conn, "/games/#{game.id}/join")

    # Should have pre-selected nickname
    assert html =~ "Detective1"

    # Should have pre-selected avatar shown
    assert html =~ "Your Avatar"
    assert html =~ "Pre-selected - click another below to change"

    # Button should be enabled (not disabled) because nickname and avatar are pre-selected
    tree = Floki.parse_document!(html)
    buttons = Floki.find(tree, "button[type=submit]")

    join_button =
      Enum.find(buttons, fn button ->
        Floki.text(button) =~ "Start Playing Now!"
      end)

    # Button should not have disabled attribute
    refute Floki.attribute(join_button, "disabled") != []

    # Can change avatar by clicking
    view
    |> render_click("select_avatar", %{"avatar" => "adventurer_avatar_02.webp"})

    # Can change nickname
    view |> form("form[phx-submit='join']", player: %{nickname: "Sherlock"}) |> render_change()

    # Submit the form (should work with pre-selected values)
    view
    |> form("form[phx-submit='join']",
      player: %{nickname: "Detective1"}
    )
    |> render_submit()
  end
end
