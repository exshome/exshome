defmodule ExshomeWebTest.Live.HomePageTest do
  use ExshomeWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  test "GET /", %{conn: conn} do
    get(conn, "/")
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Exshome"
  end
end
