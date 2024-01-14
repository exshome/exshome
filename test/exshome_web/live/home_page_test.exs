defmodule ExshomeWebTest.Live.HomePageTest do
  use ExshomeWebTest.ConnCase, async: true
  alias ExshomeWeb.App
  import Phoenix.LiveViewTest

  test "home page works", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Exshome"
  end

  test "we can navigate to an app page", %{conn: conn} do
    for app <- App.apps() do
      home_path = Routes.home_path(conn, :index)
      {:ok, view, _html} = live(conn, home_path)

      page_path =
        app
        |> App.router_config_by_app()
        |> Keyword.fetch!(:main_path)

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
