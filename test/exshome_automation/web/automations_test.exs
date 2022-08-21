defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWeb.ConnCase, async: true
  import ExshomeTest.SvgCanvasHelpers

  @default_height 1000
  @default_width 2000

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
      id = get_random_component_id(view)
      move_component(view, id, %{x: 1, y: 2})
      render_dragend(view, id, %{x: 1, y: 2})
      assert %{x: 1.0, y: 2.0} = find_element_by_id(view, id)
    end

    test "deletes element", %{view: view} do
      id = get_random_component_id(view)
      [%{x: x, y: y}] = find_elements(view, "#default-trashbin[data-open='false']")
      move_component(view, id, %{x: x, y: y})
      assert [] == find_elements(view, "#default-trashbin[data-open='true']")
      move_component(view, id, %{x: x + 1, y: y + 1})
      assert [_] = find_elements(view, "#default-trashbin[data-open='true']")
      render_dragend(view, id, %{x: x + 1, y: y + 1})
      assert [_] = find_elements(view, "##{id}.hidden")
    end
  end

  defp get_move_rate(view) do
    %{height: height, width: width} = get_viewbox(view)
    %{x: @default_height / height, y: @default_width / width}
  end

  defp move_component(view, id, %{x: x, y: y}) do
    rate = get_move_rate(view)
    select_element(view, id)
    render_hook(view, "move", %{id: id, x: x * rate.x, y: y * rate.y, mouse: %{x: x, y: y}})
  end

  defp list_components(view) do
    find_elements(view, "[id^='component-default-move-rect'")
  end

  def get_random_component_id(view) do
    %{id: id} =
      view
      |> list_components()
      |> Enum.random()

    id
  end
end
