defmodule ExshomeWebTest.Live.Service.ClockTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Variable.Builtin.LocalTime
  alias ExshomeWeb.ClockView
  alias ExshomeWeb.Live.ServicePage.Clock

  test "renders a current time", %{conn: conn} do
    view = live_with_dependencies(conn, Clock, :index)
    current_time = DateTime.utc_now()
    ExshomeTest.TestRegistry.broadcast_dependency(LocalTime, current_time)
    assert render(view) =~ ClockView.format_date(current_time)
    assert render(view) =~ ClockView.format_time(current_time)
  end
end
