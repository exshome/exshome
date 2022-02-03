defmodule ExshomeWebTest.Live.HomePageTest do
  alias Exshome.Service.ClockService
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeWeb.Live.ServicePageLive
  import Phoenix.LiveViewTest

  setup do
    ExshomeTest.TestRegistry.start_service(ClockService)
  end

  test "Home page works", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Exshome"
  end

  test "We can navigate to a service page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    for service_page <- ServicePageLive.service_pages() do
      page_path = service_page.path(conn, :index)
      element(view, ~s/[href="#{page_path}"]/) |> render_click()
      assert_redirect(view, page_path)
    end
  end
end
