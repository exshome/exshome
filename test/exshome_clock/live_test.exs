defmodule ExshomeClockTest.LiveTest do
  use ExshomeWebTest.ConnCase, async: true
  alias Exshome.Dependency
  alias Exshome.Emitter
  alias Exshome.Settings
  alias ExshomeClock.Live
  alias ExshomeClock.Services.LocalTime
  alias ExshomeClock.Settings.ClockSettings

  describe "clock page" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, "/app/clock/clock")
    end

    test "renders current time", %{conn: conn} do
      start_app_page_dependencies(Live.Clock)
      {:ok, view, _html} = live(conn, "/app/clock/clock")
      current_time = DateTime.utc_now()
      Emitter.broadcast(LocalTime, current_time)
      assert render(view) =~ Live.Clock.format_date(current_time)
      assert render(view) =~ Live.Clock.format_time(current_time)
    end
  end

  describe "settings page" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, "/app/clock/settings")
    end

    test "renders clock settings", %{conn: conn} do
      start_app_page_dependencies(Live.Settings)
      {:ok, view, _html} = live(conn, "/app/clock/settings")

      compare_timezone(view, Dependency.get_value(ClockSettings).timezone)
    end

    test "updates clock settings", %{conn: conn} do
      start_app_page_dependencies(Live.Settings)
      {:ok, view, _html} = live(conn, "/app/clock/settings")

      default_value = Settings.default_values(ClockSettings).timezone

      random_value =
        Settings.allowed_values(ClockSettings).timezone
        |> Enum.reject(fn value -> value == default_value end)
        |> Enum.random()

      value = [
        settings: %{timezone: random_value}
      ]

      assert view |> form("form", value) |> render_change()

      assert compare_timezone(view, random_value)
      refute Settings.get_settings(ClockSettings).timezone == random_value

      assert view |> form("form", value) |> render_submit()
      assert compare_timezone(view, random_value)
      assert Settings.get_settings(ClockSettings).timezone == random_value
    end

    @spec compare_timezone(Phoenix.LiveViewTest.View, String.t()) :: String.t()
    defp compare_timezone(view, expected_timezone) do
      [timezone] =
        view
        |> render()
        |> Floki.attribute("#settings_timezone [selected]", "value")

      assert timezone == expected_timezone
    end
  end

  describe "preview page" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _, _} = live_isolated(conn, Live.Preview, [])
    end

    test "renders current time", %{conn: conn} do
      start_app_page_dependencies(Live.Preview)
      {:ok, view, _html} = live_isolated(conn, Live.Preview, [])
      current_time = DateTime.utc_now()
      Emitter.broadcast(LocalTime, current_time)

      for clock_part <- ["hour", "minute", "second"] do
        assert has_element?(view, "#clock-#{clock_part}")
      end
    end
  end
end
