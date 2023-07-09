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

  describe "connect items" do
    setup %{workflow_id: workflow_id} do
      %EditorItem{id: parent_id} = create_item(workflow_id, "if")
      %{parent_id: parent_id}
    end

    test "adjust position", %{workflow_id: workflow_id, parent_id: parent_id} do
      %EditorItem{} = child = create_item(workflow_id, "if")
      %EditorItem{} = parent = Workflow.get_item!(workflow_id, parent_id)

      parent_connector = parent.connectors[{:action, "then"}]
      child_connector = child.connectors[:parent_action]

      expected_position = %{
        x: round(parent.position.x + parent_connector.x - child_connector.x),
        y: round(parent.position.y + parent_connector.y - child_connector.y)
      }

      :ok = Workflow.select_item(workflow_id, child.id)

      :ok =
        Workflow.stop_dragging(workflow_id, child.id, %{
          x: expected_position.x + 1,
          y: expected_position.y + 1
        })

      %EditorItem{} = updated_parent = Workflow.get_item!(workflow_id, parent_id)
      %EditorItem{position: position} = updated_child = Workflow.get_item!(workflow_id, child.id)

      actual_position = %{x: round(position.x), y: round(position.y)}
      assert actual_position == expected_position
      assert map_size(updated_parent.connected_items) == 1
      assert map_size(updated_child.connected_items) == 1
      assert parent.height < updated_parent.height
    end

    test "action", %{workflow_id: workflow_id, parent_id: parent_id} do
      %EditorItem{id: child_id} = create_item(workflow_id, "if")
      %EditorItem{} = parent = Workflow.get_item!(workflow_id, parent_id)

      random_action =
        parent
        |> EditorItem.get_child_keys()
        |> Enum.filter(fn {type, _} -> type == :action end)
        |> Enum.random()

      connect_items(workflow_id, {parent_id, random_action}, {child_id, :parent_action})

      %EditorItem{} = child = Workflow.get_item!(workflow_id, child_id)
      assert map_size(child.connected_items) == 1
    end

    test "connector", %{workflow_id: workflow_id, parent_id: parent_id} do
      %EditorItem{id: child_id} = create_item(workflow_id, "value")
      %EditorItem{} = parent = Workflow.get_item!(workflow_id, parent_id)

      random_action =
        parent
        |> EditorItem.get_child_keys()
        |> Enum.filter(fn {type, _} -> type == :connector end)
        |> Enum.random()

      connect_items(workflow_id, {parent_id, random_action}, {child_id, :parent_connector})

      %EditorItem{} = child = Workflow.get_item!(workflow_id, child_id)
      assert map_size(child.connected_items) == 1
    end

    test "move_connected_item", %{workflow_id: workflow_id, parent_id: parent_id} do
      %EditorItem{id: child_id} = create_item(workflow_id, "if")
      connect_items(workflow_id, {parent_id, {:action, "then"}}, {child_id, :parent_action})
      parent_position = item_position(workflow_id, parent_id)
      child_position = item_position(workflow_id, child_id)

      :ok = Workflow.select_item(workflow_id, parent_id)

      :ok =
        Workflow.move_item(workflow_id, parent_id, %{
          x: parent_position.x + 1,
          y: parent_position.y + 1
        })

      assert %{
               x: child_position.x + 1,
               y: child_position.y + 1
             } == item_position(workflow_id, child_id)

      :ok =
        Workflow.stop_dragging(workflow_id, parent_id, %{
          x: parent_position.x + 2,
          y: parent_position.y + 2
        })

      assert %{
               x: child_position.x + 2,
               y: child_position.y + 2
             } == item_position(workflow_id, child_id)
    end

    test "resize parents and move siblings", %{
      workflow_id: workflow_id,
      parent_id: grandparent_id
    } do
      grandparent_position = item_position(workflow_id, grandparent_id)
      %EditorItem{id: parent_id} = create_item(workflow_id, "if")
      %EditorItem{id: parent_sibling_id} = create_item(workflow_id, "if")
      %EditorItem{id: child_id} = create_item(workflow_id, "if")
      %EditorItem{id: sibling_id} = create_item(workflow_id, "if")

      initial_grandparent_height = item_height(workflow_id, grandparent_id)

      connect_items(
        workflow_id,
        {grandparent_id, {:action, "else"}},
        {parent_sibling_id, :parent_action}
      )

      grandparent_height_with_one_child = item_height(workflow_id, grandparent_id)
      assert grandparent_height_with_one_child > initial_grandparent_height

      connect_items(workflow_id, {parent_id, {:action, "else"}}, {sibling_id, :parent_action})

      parent_sibling_position = item_position(workflow_id, parent_sibling_id)
      connect_items(workflow_id, {grandparent_id, {:action, "then"}}, {parent_id, :parent_action})
      updated_parent_sibling_position = item_position(workflow_id, parent_sibling_id)
      assert parent_sibling_position.y < updated_parent_sibling_position.y
      grandparent_height_with_two_children = item_height(workflow_id, grandparent_id)
      assert grandparent_height_with_two_children > grandparent_height_with_one_child

      sibling_position = item_position(workflow_id, sibling_id)
      connect_items(workflow_id, {parent_id, {:action, "then"}}, {child_id, :parent_action})
      assert sibling_position.y < item_position(workflow_id, sibling_id).y
      assert updated_parent_sibling_position.y < item_position(workflow_id, parent_sibling_id).y
      assert grandparent_height_with_two_children < item_height(workflow_id, grandparent_id)

      :ok = Workflow.select_item(workflow_id, child_id)
      :ok = Workflow.stop_dragging(workflow_id, child_id, grandparent_position)
      assert sibling_position.y == item_position(workflow_id, sibling_id).y
      assert updated_parent_sibling_position.y == item_position(workflow_id, parent_sibling_id).y
      assert grandparent_height_with_two_children == item_height(workflow_id, grandparent_id)
    end

    defp item_position(workflow_id, item_id) do
      %EditorItem{position: position} = Workflow.get_item!(workflow_id, item_id)
      position
    end

    defp item_height(workflow_id, item_id) do
      %EditorItem{height: height} = Workflow.get_item!(workflow_id, item_id)
      height
    end
  end

  defp create_random_item(workflow_id) do
    type =
      EditorItem.available_types()
      |> Map.keys()
      |> Enum.random()

    create_item(workflow_id, type)
  end

  defp create_item(workflow_id, type) do
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

  defp connect_items(workflow_id, {parent_id, parent_key}, {child_id, child_key}) do
    %EditorItem{} = parent = Workflow.get_item!(workflow_id, parent_id)
    %EditorItem{} = child = Workflow.get_item!(workflow_id, child_id)

    new_child_position = %{
      x: parent.position.x + parent.connectors[parent_key].x - child.connectors[child_key].x,
      y: parent.position.y + parent.connectors[parent_key].y - child.connectors[child_key].y
    }

    :ok = Workflow.select_item(workflow_id, child_id)
    :ok = Workflow.stop_dragging(workflow_id, child_id, new_child_position)
  end
end
