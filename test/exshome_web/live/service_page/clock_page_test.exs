defmodule ExshomeWebTest.Live.ServicePage.ClockPageTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.App.Clock
  alias Exshome.Dependency
  alias ExshomeWeb.ClockView
  alias ExshomeWeb.Live.ServicePage.ClockPage

  describe "index" do
    test "renders current time", %{conn: conn} do
      view = live_with_dependencies(conn, ClockPage, :index)
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(Clock.LocalTime, current_time)
      assert render(view) =~ ClockView.format_date(current_time)
      assert render(view) =~ ClockView.format_time(current_time)
    end
  end
end
