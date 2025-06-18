defmodule CrimeToGoWeb.PageControllerTest do
  use CrimeToGoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "CrimeToGo"
    assert html_response(conn, 200) =~ "multiplayer online detective game"
    assert html_response(conn, 200) =~ "Create New Game"
    assert html_response(conn, 200) =~ "Join Existing Game"
  end
end
