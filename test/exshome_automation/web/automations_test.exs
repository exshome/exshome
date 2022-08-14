defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWeb.ConnCase, async: true

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :automations))
    end
  end

  describe "render with dependnencies" do
    setup %{conn: conn} do
      view = render_automations(conn)
      %{view: view}
    end

    test "works fine", %{view: view} do
      assert render_hook(view, "resize", %{height: 1000, width: 500})
      assert get_viewbox(view) == %{x: 0, y: 0, height: 200, width: 100}
      assert render_hook(view, "resize", %{height: 500, width: 1000})
      assert get_viewbox(view) == %{x: 0, y: 0, height: 100, width: 200}
    end
  end

  defp render_automations(conn) do
    live_with_dependencies(conn, ExshomeAutomation, :automations)
  end

  defp get_viewbox(view) do
    [{x, ""}, {y, ""}, {width, ""}, {height, ""}] =
      view
      |> render()
      |> Floki.attribute("#default-body", "viewbox")
      |> List.first()
      |> String.split(~r/\s+/)
      |> Enum.map(&Float.parse/1)

    %{x: x, y: y, height: height, width: width}
  end
end
