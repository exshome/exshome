defmodule ExshomeAutomationTest.Live.AutomationEditorTest do
  use ExshomeWebTest.ConnCase, async: true

  import ExshomeTest.Fixtures
  import ExshomeTest.SvgCanvasHelpers
  import ExshomeTest.WorkflowHelpers

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias ExshomeAutomation.Live.AutomationEditor
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor
  alias ExshomeAutomation.Streams.{EditorStream, WorkflowStateStream}

  @default_height 1000
  @default_width 2000

  describe "render wrong workflow id" do
    test "shows missing dependencies", %{conn: conn} do
      assert {:ok, view, _html} =
               live(conn, "/app/automation/automations/wrong_id")

      assert render(view) =~ ~r/Missing dependencies:/
    end
  end

  describe "render with not started workflow" do
    test "works fine", %{conn: conn} do
      %Workflow{id: workflow_id} = create_workflow()
      :ok = WorkflowSupervisor.terminate_child_with_id(workflow_id)

      start_app_page_dependencies(AutomationEditor)
      {:ok, view, _html} = live(conn, "/app/automation/automations/#{workflow_id}")

      assert render(view) =~ ~r/Missing dependencies:/

      WorkflowSupervisor.start_child_with_id(workflow_id)
      assert_receive_app_page_stream({{EditorStream, ^workflow_id}, %Operation.ReplaceAll{}})
      refute render(view) =~ ~r/Missing dependencies:/
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      workflow = create_workflow()

      assert Workflow.list_items(workflow.id) != NotReady

      start_app_page_dependencies(AutomationEditor)
      {:ok, view, _html} = live(conn, "/app/automation/automations/#{workflow.id}")
      :ok = generate_random_components(view, 5)
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

      assert view
             |> form("form[phx-change=rename_workflow]")
             |> render_change(%{new_name: new_name})

      assert_receive_app_page_dependency({{Workflow, ^id}, %Workflow{name: ^new_name}})
      assert render(view) =~ new_name
    end
  end

  defp list_components(view) do
    find_elements(view, "[data-component^='component-default-'")
  end

  defp count_components(view) do
    view
    |> list_components()
    |> length()
  end

  defp get_random_component(view) do
    %{component: component} =
      view
      |> list_components()
      |> Enum.random()

    component
  end

  defp create_workflow do
    :ok = Dependency.subscribe(WorkflowStateStream)
    start_workflow_supervisor()
    :ok = Workflow.create!()
    assert_receive_stream({WorkflowStateStream, %Operation.Insert{data: %Workflow{} = workflow}})
    workflow
  end
end
