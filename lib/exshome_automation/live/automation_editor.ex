defmodule ExshomeAutomation.Live.AutomationEditor do
  @moduledoc """
  Automation editor page
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias ExshomeAutomation.Live.Automation.AutomationBlock
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.Workflow.EditorItem
  alias ExshomeAutomation.Streams.EditorStream

  use ExshomeWeb.Live.AppPage

  use ExshomeWeb.Live.SvgCanvas

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <ExshomeWeb.SvgCanvasComponent.render_svg_canvas
        meta={@__svg_meta__}
        components={@streams.__components__}
        menu_items={@__menu_items__}
      >
        <:header>
          <.live_component
            module={ExshomeWeb.Live.RenameComponent}
            id="rename_workflow"
            value={@deps.workflow.name}
            can_rename?={true}
          />
        </:header>
      </ExshomeWeb.SvgCanvasComponent.render_svg_canvas>
    </.missing_deps_placeholder>
    """
  end

  @impl LiveView
  def mount(%{"id" => id}, _session, socket) do
    :ok = Emitter.subscribe({EditorStream, id})

    socket =
      socket
      |> assign(workflow_id: id)
      |> put_dependencies([{{Workflow, id}, :workflow}])

    menu_items =
      for type <- Map.keys(EditorItem.available_types()) do
        menu_item =
          type
          |> EditorItem.create(%{x: 0, y: 0})
          |> Map.put(:id, type)

        generate_component(menu_item)
      end

    workflow_items =
      case Workflow.list_items(id) do
        NotReady -> []
        items -> items
      end

    components = Enum.map(workflow_items, &generate_component/1)

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
    :ok = Workflow.create_item(socket.assigns.workflow_id, type, position)

    socket
  end

  @impl SvgCanvas
  def handle_delete(%Socket{} = socket, id) do
    :ok = Workflow.delete_item(socket.assigns.workflow_id, id)
    socket
  end

  @impl SvgCanvas
  def handle_dragend(%Socket{} = socket, %{id: id, position: position}) do
    :ok = Workflow.stop_dragging(socket.assigns.workflow_id, id, position)
    socket
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, %{id: id, position: position}) do
    :ok = Workflow.move_item(socket.assigns.workflow_id, id, position)
    socket
  end

  @impl SvgCanvas
  def handle_select(%Socket{} = socket, %{id: selected_id}) do
    :ok = Workflow.select_item(socket.assigns.workflow_id, selected_id)
    socket
  end

  @impl AppPage
  def on_stream(
        {{EditorStream, workflow_id}, %Operation.ReplaceAll{data: items}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    components = Enum.map(items, &generate_component/1)
    SvgCanvas.replace_components(socket, components)
  end

  def on_stream(
        {
          {EditorStream, workflow_id},
          %Operation.Insert{data: %EditorItem{} = item, key: key}
        },
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(item)

    if key != self() do
      SvgCanvas.insert_component(socket, component)
    else
      socket
      |> SvgCanvas.insert_component(component)
      |> handle_select(%{id: item.id})
      |> SvgCanvas.select_item(item.id)
    end
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Delete{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(item)
    SvgCanvas.remove_component(socket, component)
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Update{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_component(item)
    SvgCanvas.insert_component(socket, component)
  end

  defp generate_component(%EditorItem{} = item) do
    selected? = item.selected_by != nil
    selected_by_me? = self() == item.selected_by

    outline_color =
      case {selected?, selected_by_me?} do
        {true, true} -> "stroke-yellow-200 dark:stroke-yellow-400"
        {true, false} -> "stroke-yellow-500 dark:stroke-yellow-700"
        _ -> "stroke-gray-700 dark:stroke-gray-400"
      end

    %AutomationBlock{
      id: item.id,
      class: """
      fill-green-200
      #{if item.drag, do: "opacity-75"}
      #{if selected_by_me?, do: "stroke-1", else: "stroke-[0.1]"}
      #{outline_color}
      """,
      item: item
    }
  end
end
