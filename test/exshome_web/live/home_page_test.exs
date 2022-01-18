defmodule ExshomeWebTest.Live.HomePageTest do
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeWeb.Live.ServicePage.Clock

  import Phoenix.LiveViewTest

  test "Home page works", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Exshome"
  end

  test "We can navigate to a service page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    clock_path = Clock.path(conn, :index)
    element(view, ~s/[href="#{clock_path}"]/) |> render_click()
    assert_patch(view, clock_path)
  end
end
