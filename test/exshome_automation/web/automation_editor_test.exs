defmodule ExshomeAutomationTest.Web.AutomationEditorTest do
  use ExshomeWebTest.ConnCase, async: true
  import ExshomeTest.SvgCanvasHelpers
  import ExshomeTest.WorkflowHelpers

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Streams.WorkflowStateStream

  @default_height 1000
  @default_width 2000

  describe "render without dependencies" do
    test "works fine", %{conn: conn} do
      assert {:ok, _view, _html} =
               live(conn, ExshomeAutomation.details_path(conn, "automations", "some_id"))
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      start_workflow_supervisor()
      :ok = Dependency.subscribe(WorkflowStateStream)
      :ok = Workflow.create!()

      assert_receive_stream(
        {WorkflowStateStream, %Operation.Insert{data: %Workflow{} = workflow}}
      )

      view = live_with_dependencies(conn, ExshomeAutomation, "automations", workflow.id)
      resize(view, %{height: @default_height, width: @default_width})
      %{view: view, workflow: workflow}
    end

    test "moves element", %{view: view} do
      id = get_random_component_id(view)
      render_move(view, id, %{x: 1, y: 2})
      render_dragend(view, %{x: 1, y: 2})
      assert %{x: 1.0, y: 2.0} = find_element_by_id(view, id)
    end

    test "deletes element", %{view: view} do
      id = get_random_component_id(view)
      [trashbin] = find_elements(view, "#default-trashbin[data-open='false']")
      %{x: x, y: y} = translate_screen_to_canvas(view, trashbin)
      render_move(view, id, %{x: x, y: y})
      assert [] == find_elements(view, "#default-trashbin[data-open='true']")
      render_move(view, id, %{x: x + 1, y: y + 1})
      assert [_] = find_elements(view, "#default-trashbin[data-open='true']")
      render_dragend(view, %{x: x + 1, y: y + 1})
      assert [_] = find_elements(view, "##{id}.hidden")
    end
  end

  defp list_components(view) do
    find_elements(view, "[id^='component-default-rect'")
  end

  def get_random_component_id(view) do
    %{id: id} =
      view
      |> list_components()
      |> Enum.random()

    id
  end
end
