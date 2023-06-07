defmodule ExshomeAutomation.Web.Live.AutomationEditor do
  @moduledoc """
  Automation editor page
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.Workflow.EditorItem
  alias ExshomeAutomation.Streams.EditorStream
  alias ExshomeAutomation.Web.Live.Automation.AutomationBlock

  use ExshomeWeb.Live.AppPage,
    icon: "🤖"

  use ExshomeWeb.Live.SvgCanvas

  @impl LiveView
  def mount(%{"id" => id}, _session, socket) do
    :ok = Dependency.subscribe({EditorStream, id})

    socket =
      socket
      |> assign(selected_id: nil, drag: false, workflow_id: id)
      |> put_dependencies([{{Workflow, id}, :workflow}])

    menu_items =
      for type <- Map.keys(EditorItem.available_types()) do
        menu_item =
          %{type: type, position: %{x: 0, y: 0}}
          |> EditorItem.create()
          |> Map.put(:id, type)

        generate_component(socket, menu_item)
      end

    workflow_items =
      case Workflow.list_items(id) do
        NotReady -> []
        items -> items
      end

    components = Enum.map(workflow_items, &generate_component(socket, &1))

    socket =
      socket
      |> SvgCanvas.replace_components(components)
      |> SvgCanvas.render_menu_items(menu_items)

    {:ok, socket}
  end

  @impl LiveView
  def handle_event("rename_workflow", %{"new_name" => value}, socket) do
    Workflow.rename(socket.assigns.deps.workflow.id, value)
    {:noreply, socket}
  end

  @impl SvgCanvas
  def handle_create(%Socket{} = socket, %{type: type, position: position}) do
    :ok =
      Workflow.create_item(
        socket.assigns.workflow_id,
        %{type: type, position: position}
      )

    socket
  end

  @impl SvgCanvas
  def handle_delete(%Socket{} = socket, id) do
    :ok = Workflow.delete_item!(socket.assigns.workflow_id, id)
    assign(socket, selected_id: nil, drag: false)
  end

  @impl SvgCanvas
  def handle_dragend(%Socket{} = socket, %{id: id, position: position}) do
    :ok = Workflow.move_item!(socket.assigns.workflow_id, id, position)
    assign(socket, drag: false)
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, %{id: id, position: position}) do
    :ok = Workflow.move_item!(socket.assigns.workflow_id, id, position)
    assign(socket, selected_id: id, drag: true)
  end

  @impl SvgCanvas
  def handle_select(%Socket{} = socket, %{id: selected_id}) do
    old_selected_id = socket.assigns.selected_id

    socket = assign(socket, :selected_id, selected_id)

    ids =
      case {old_selected_id, selected_id} do
        {id, id} -> []
        {nil, new_id} -> [new_id]
        {old_id, new_id} -> [old_id, new_id]
      end

    for id <- ids, reduce: socket do
      socket ->
        item = Workflow.get_item!(socket.assigns.workflow_id, id)
        component = generate_component(socket, item)
        SvgCanvas.insert_component(socket, component)
    end
  end

  @impl AppPage
  def on_stream(
        {{EditorStream, workflow_id}, %Operation.ReplaceAll{data: items}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    components = Enum.map(items, &generate_component(socket, &1))
    SvgCanvas.replace_components(socket, components)
  end

  def on_stream(
        {
          {EditorStream, workflow_id},
          %Operation.Insert{data: %EditorItem{} = item, key: key}
        },
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(socket, item)

    if key != self() do
      SvgCanvas.insert_component(socket, component)
    else
      socket
      |> handle_select(%{id: item.id})
      |> SvgCanvas.select_item(item.id)
    end
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Delete{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(socket, item)
    SvgCanvas.remove_component(socket, component)
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Update{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(socket, item)
    SvgCanvas.insert_component(socket, component)
  end

  defp generate_component(%Socket{} = socket, %EditorItem{} = item) do
    %SvgCanvas{canvas: canvas} = SvgCanvas.get_svg_meta(socket)
    %{x: x, y: y} = item.position
    %{selected_id: selected_id, drag: drag} = socket.assigns
    selected? = selected_id == item.id
    width = item.width
    height = item.height

    %AutomationBlock{
      id: item.id,
      class: """
      fill-green-200
      #{if selected? && drag, do: "opacity-75"}
      #{if selected?, do: "stroke-yellow-200 dark:stroke-yellow-400"}
      """,
      item: item,
      height: height,
      width: width,
      x: fit_in_box(x, canvas.width - width),
      y: fit_in_box(y, canvas.height - height)
    }
  end

  defp fit_in_box(coordinate, size) do
    coordinate
    |> min(size)
    |> max(0)
  end
end
