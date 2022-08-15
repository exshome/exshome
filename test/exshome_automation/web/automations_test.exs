defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWeb.ConnCase, async: true
  import ExshomeTest.SvgCanvasHelpers

  @default_height 100
  @default_width 100

  describe "render without dependencies" do
    test "works fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :automations))
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeAutomation, :automations)
      resize(view, %{height: @default_height, width: @default_width})
      %{view: view}
    end

    test "moves element", %{view: view} do
      %{id: id} =
        view
        |> list_components()
        |> Enum.random()

      move_component(view, id, %{x: 1, y: 2})
      assert %{x: 1.0, y: 2.0} = find_element_by_id(view, id)
    end
  end

  defp move_component(view, id, %{x: x, y: y}) do
    rate = get_move_rate(view)
    select_element(view, id)
    render_hook(view, "move", %{id: id, x: x * rate.x, y: y * rate.y})
    render_dragend(view)
  end

  defp list_components(view) do
    find_elements(view, "[id^='rect-'")
  end

  defp get_move_rate(view) do
    %{height: height, width: width} = get_viewbox(view)
    %{x: @default_height / height, y: @default_width / width}
  end
end
