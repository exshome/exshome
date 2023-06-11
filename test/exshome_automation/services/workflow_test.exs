defmodule ExshomeAutomationTest.Services.WorkflowTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.Workflow.EditorItem
  alias ExshomeAutomation.Streams.EditorStream
  alias ExshomeAutomation.Streams.WorkflowStateStream
  alias ExshomeTest.TestRegistry

  import ExshomeTest.Fixtures
  import ExshomeTest.WorkflowHelpers

  setup do
    start_workflow_supervisor()
    Dependency.subscribe(WorkflowStateStream)
    :ok = Workflow.create!()

    assert_receive_stream(
      {WorkflowStateStream, %Operation.Insert{data: %Workflow{id: workflow_id}}}
    )

    :ok = Dependency.subscribe({EditorStream, workflow_id})

    %{workflow_id: workflow_id}
  end

  describe "correct cleanup when the process is dead" do
    test "clears selection", %{workflow_id: workflow_id} do
      %EditorItem{id: item_id} = create_random_item(workflow_id)
      pid = TestRegistry.start_agent!(fn -> Workflow.select_item!(workflow_id, item_id) end)
      assert [%EditorItem{selected_by: ^pid}] = Workflow.list_items(workflow_id)
      :ok = TestRegistry.stop_agent!(pid)
      assert [%EditorItem{selected_by: nil}] = Workflow.list_items(workflow_id)
    end

    test "stops dragging", %{workflow_id: workflow_id} do
      %EditorItem{id: item_id, position: position} = create_random_item(workflow_id)
      new_x = position.x + 1
      new_y = position.y + 1

      pid =
        TestRegistry.start_agent!(fn ->
          Workflow.select_item!(workflow_id, item_id)
          Workflow.move_item!(workflow_id, item_id, %{x: new_x, y: new_y})
        end)

      assert [%EditorItem{selected_by: ^pid, drag: true}] = Workflow.list_items(workflow_id)
      :ok = TestRegistry.stop_agent!(pid)

      assert [%EditorItem{selected_by: nil, drag: false, position: %{x: ^new_x, y: ^new_y}}] =
               Workflow.list_items(workflow_id)
    end

    test "deletes item", %{workflow_id: workflow_id} do
      %EditorItem{id: item_id, position: position} = create_random_item(workflow_id)
      new_x = position.x + 1
      new_y = position.y + 1

      pid =
        TestRegistry.start_agent!(fn ->
          Workflow.select_item!(workflow_id, item_id)
          Workflow.move_item!(workflow_id, item_id, %{x: new_x, y: new_y})
          Workflow.delete_item!(workflow_id, item_id)
        end)

      :ok = TestRegistry.stop_agent!(pid)

      assert [] == Workflow.list_items(workflow_id)
    end

    test "works fine after move", %{workflow_id: workflow_id} do
      %EditorItem{id: item_id, position: position} = create_random_item(workflow_id)
      move_x = position.x + 1
      move_y = position.y + 1
      final_x = position.x + 2
      final_y = position.y + 2

      pid =
        TestRegistry.start_agent!(fn ->
          Workflow.select_item!(workflow_id, item_id)
          Workflow.move_item!(workflow_id, item_id, %{x: move_x, y: move_y})
          Workflow.stop_dragging!(workflow_id, item_id, %{x: final_x, y: final_y})
        end)

      assert [%EditorItem{selected_by: ^pid, drag: false, position: %{x: ^final_x, y: ^final_y}}] =
               Workflow.list_items(workflow_id)

      :ok = TestRegistry.stop_agent!(pid)

      assert [%EditorItem{selected_by: nil, drag: false, position: %{x: ^final_x, y: ^final_y}}] =
               Workflow.list_items(workflow_id)
    end
  end

  defp create_random_item(workflow_id) do
    type =
      EditorItem.available_types()
      |> Map.keys()
      |> Enum.random()

    Workflow.create_item(
      workflow_id,
      type,
      %{x: unique_integer(), y: unique_integer()}
    )

    assert_receive_stream({
      {EditorStream, ^workflow_id},
      %Operation.Insert{data: %EditorItem{} = item}
    })

    item
  end
end
