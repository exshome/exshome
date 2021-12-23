defmodule ExshomeWeb.PageControllerTest do
  use ExshomeWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Exshome"
  end
end
