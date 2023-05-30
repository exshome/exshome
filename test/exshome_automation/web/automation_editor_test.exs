defmodule ExshomeAutomationTest.Web.AutomationEditorTest do
  use ExshomeWebTest.ConnCase, async: true

  import ExshomeTest.Fixtures
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
      id = get_random_component(view)
      render_move(view, id, %{x: 1, y: 2})
      render_dragend(view, %{x: 1, y: 2})
      assert %{x: 1.0, y: 2.0} = find_component(view, id)
    end

    test "deletes element", %{view: view} do
      assert count_components(view) == 5
      component = get_random_component(view)
      [trashbin] = find_elements(view, "#default-trashbin[data-open='false']")
      %{x: x, y: y} = translate_screen_to_canvas(view, trashbin)
      render_move(view, component, %{x: x, y: y})
      assert [] == find_elements(view, "#default-trashbin[data-open='true']")
      render_move(view, component, %{x: x + 1, y: y + 1})
      assert [_] = find_elements(view, "#default-trashbin[data-open='true']")
      render_dragend(view, %{x: x + 1, y: y + 1})
      assert count_components(view) == 4
    end

    test "renames workflow", %{view: view, workflow: %Workflow{name: name, id: id}} do
      assert render(view) =~ name
      assert view |> element("[phx-click=toggle_rename]") |> render_click()

      new_name = "some_name#{unique_integer()}"
      assert view |> form("form[phx-change=rename_workflow]") |> render_change(%{value: new_name})
      assert_receive_app_page_dependency({{Workflow, ^id}, %Workflow{name: ^new_name}})
      assert render(view) =~ new_name
    end
  end

  defp list_components(view) do
    find_elements(view, "[data-component^='component-default-rect'")
  end

  defp count_components(view) do
    view
    |> list_components()
    |> length()
  end

  def get_random_component(view) do
    %{component: component} =
      view
      |> list_components()
      |> Enum.random()

    component
  end
end
