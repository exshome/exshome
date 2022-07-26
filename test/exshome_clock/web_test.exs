defmodule ExshomeClockTest.WebTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Dependency
  alias Exshome.Settings
  alias ExshomeClock.Services.LocalTime
  alias ExshomeClock.Settings.ClockSettings
  alias ExshomeClock.Web.View

  describe "clock page" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeClock.path(conn, :clock))
    end

    test "renders current time", %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeClock, :clock)
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(LocalTime, current_time)
      assert render(view) =~ View.format_date(current_time)
      assert render(view) =~ View.format_time(current_time)
    end
  end

  describe "settings page" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeClock.path(conn, :settings))
    end

    test "renders clock settings", %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeClock, :settings)

      compare_timezone(view, Dependency.get_value(ClockSettings).timezone)
    end

    test "updates clock settings", %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeClock, :settings)

      random_value =
        Settings.allowed_values(ClockSettings).timezone
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
      assert live_preview(conn, ExshomeClock)
    end

    test "renders current time", %{conn: conn} do
      view = live_preview_with_dependencies(conn, ExshomeClock)
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(LocalTime, current_time)

      for clock_part <- ["hour", "minute", "second"] do
        assert has_element?(view, "#clock-#{clock_part}")
      end
    end
  end
end
