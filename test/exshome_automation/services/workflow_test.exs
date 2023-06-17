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
      pid = TestRegistry.start_agent!(fn -> Workflow.select_item(workflow_id, item_id) end)
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
          Workflow.select_item(workflow_id, item_id)
          Workflow.move_item(workflow_id, item_id, %{x: new_x, y: new_y})
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
          Workflow.select_item(workflow_id, item_id)
          Workflow.move_item(workflow_id, item_id, %{x: new_x, y: new_y})
          Workflow.delete_item(workflow_id, item_id)
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
          Workflow.select_item(workflow_id, item_id)
          Workflow.move_item(workflow_id, item_id, %{x: move_x, y: move_y})
          Workflow.stop_dragging(workflow_id, item_id, %{x: final_x, y: final_y})
        end)

      assert [%EditorItem{selected_by: ^pid, drag: false, position: %{x: ^final_x, y: ^final_y}}] =
               Workflow.list_items(workflow_id)

      :ok = TestRegistry.stop_agent!(pid)

      assert [%EditorItem{selected_by: nil, drag: false, position: %{x: ^final_x, y: ^final_y}}] =
               Workflow.list_items(workflow_id)
    end
  end

  describe "check logic constraints" do
    test "select non-existing item", %{workflow_id: workflow_id} do
      assert {:error, _reason} = Workflow.select_item(workflow_id, "non-existing")
    end

    test "move non-existing item", %{workflow_id: workflow_id} do
      assert {:error, _reason} = Workflow.move_item(workflow_id, "non-existing", %{x: 0, y: 0})
    end

    test "stop dragging non-existing item", %{workflow_id: workflow_id} do
      assert {:error, _reason} =
               Workflow.stop_dragging(
                 workflow_id,
                 "non-existing",
                 %{x: 0, y: 0}
               )
    end

    test "delete non-existing item", %{workflow_id: workflow_id} do
      assert {:error, _reason} = Workflow.delete_item(workflow_id, "non-existing")
    end
  end

  describe "check sort order" do
    test "list_items returns items sorted by their update time", %{workflow_id: workflow_id} do
      %EditorItem{id: id1} = create_random_item(workflow_id)
      %EditorItem{id: id2} = create_random_item(workflow_id)

      assert workflow_item_ids(workflow_id) == [id1, id2]
      :ok = Workflow.move_item(workflow_id, id1, %{x: 0, y: 0})
      assert workflow_item_ids(workflow_id) == [id2, id1]
    end

    defp workflow_item_ids(workflow_id) do
      workflow_id
      |> Workflow.list_items()
      |> Enum.map(& &1.id)
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
