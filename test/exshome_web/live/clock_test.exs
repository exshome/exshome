defmodule ExshomeWeb.Live.ClockTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Clock
  alias ExshomeWeb.ClockView
  import Phoenix.LiveViewTest

  test "renders a current time", %{conn: conn} do
    {:ok, view, _html} = live(conn, Routes.clock_index_path(conn, :index))
    current_time = Clock.get_state()
    Clock.broadcast(current_time)
    render(view) =~ ClockView.format_date(current_time.time)
    render(view) =~ ClockView.format_time(current_time.time)
  end
end
