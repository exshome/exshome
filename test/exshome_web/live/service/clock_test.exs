defmodule ExshomeWebTest.Live.Service.ClockTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Service.ClockService
  alias ExshomeWeb.ClockView
  alias ExshomeWeb.Live.ServicePage
  import Phoenix.LiveViewTest

  setup do
    ExshomeTest.TestRegistry.start_service(ClockService)
  end

  test "renders a current time", %{conn: conn} do
    {:ok, view, _html} = live(conn, ServicePage.Clock.path(conn, :index))
    current_time = ClockService.get_value()
    ClockService.broadcast(current_time)
    render(view) =~ ClockView.format_date(current_time)
    render(view) =~ ClockView.format_time(current_time)
  end
end
