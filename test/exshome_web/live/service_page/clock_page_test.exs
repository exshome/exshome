defmodule ExshomeWebTest.Live.ServicePage.ClockPageTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.App.Clock
  alias Exshome.Dependency
  alias Exshome.Settings
  alias ExshomeWeb.Live.ServicePage.ClockPage
  alias ExshomeWeb.ServicePage.ClockView

  describe "clock page index" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ClockPage.path(conn, :index))
    end

    test "renders current time", %{conn: conn} do
      view = live_with_dependencies(conn, ClockPage, :index)
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(Clock.LocalTime, current_time)
      assert render(view) =~ ClockView.format_date(current_time)
      assert render(view) =~ ClockView.format_time(current_time)
    end
  end

  describe "clock page settings" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ClockPage.path(conn, :settings))
    end

    test "renders clock settings", %{conn: conn} do
      view = live_with_dependencies(conn, ClockPage, :settings)

      compare_timezone(view, Clock.ClockSettings.get_value().timezone)
    end

    test "updates clock settings", %{conn: conn} do
      view = live_with_dependencies(conn, ClockPage, :settings)

      random_value =
        Settings.allowed_values(Clock.ClockSettings).timezone
        |> Enum.random()

      value = [
        settings: %{timezone: random_value}
      ]

      assert view |> form("form", value) |> render_change()

      assert compare_timezone(view, random_value)
      refute Settings.get_settings(Clock.ClockSettings).timezone == random_value

      assert view |> form("form", value) |> render_submit()
      assert compare_timezone(view, random_value)
      assert Settings.get_settings(Clock.ClockSettings).timezone == random_value
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

  describe "clock page preview" do
    test "renders without dependencies", %{conn: conn} do
      assert live_preview(conn, ClockPage)
    end

    test "renders current time", %{conn: conn} do
      view = live_preview_with_dependencies(conn, ClockPage)
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(Clock.LocalTime, current_time)

      for clock_part <- ["hour", "minute", "second"] do
        assert has_element?(view, "#clock-#{clock_part}")
      end
    end
  end
end
