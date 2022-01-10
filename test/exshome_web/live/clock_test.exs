defmodule ExshomeWeb.Live.ClockTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Service.ClockService
  alias ExshomeWeb.ClockView
  import Phoenix.LiveViewTest

  setup do
    ExshomeTest.TestRegistry.start_service(ClockService)
  end

  test "renders a current time", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.clock_index_path(conn, :index))
    current_time = ClockService.get_value()
    ClockService.broadcast(current_time)
    render(view) =~ ClockView.format_date(current_time)
    render(view) =~ ClockView.format_time(current_time)
  end
end
