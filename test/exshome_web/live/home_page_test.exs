defmodule ExshomeWebTest.Live.HomePageTest do
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeWeb.Live.ServicePageLive
  import Phoenix.LiveViewTest

  test "Home page works", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Exshome"
  end

  test "We can navigate to a service page", %{conn: conn} do
    for service_page <- ServicePageLive.service_pages() do
      home_path = Routes.home_path(conn, :index)
      {:ok, view, _html} = live(conn, home_path)

      page_path = service_page.path(conn, :index)

      {:ok, view, _html} =
        view
        |> element(~s/[href="#{page_path}"]/)
        |> render_click()
        |> follow_redirect(conn)

      {:ok, _view, _html} =
        view
        |> element(~s/header [href="#{home_path}"]/)
        |> render_click()
        |> follow_redirect(conn)
    end
  end
end
