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
  alias ExshomeWeb.Live.SvgCanvas.ComponentMeta
  alias ExshomeWeb.SvgCanvasComponent

  @canvas_name :canvas

  use ExshomeWeb.Live.AppPage

  use ExshomeWeb.Live.SvgCanvas, [@canvas_name]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <SvgCanvasComponent.render_svg_canvas meta={@canvas}>
        <:header>
          <.live_component
            module={ExshomeWeb.Live.RenameComponent}
            id="rename_workflow"
            value={@deps.workflow.name}
            can_rename?={true}
          />
        </:header>
        <:menu :for={{menu_item, meta} <- @menu_data}>
          <SvgCanvasComponent.component :let={drag_attrs} meta={meta}>
            <svg class="w-full p-5" viewbox={"0 0 #{menu_item.item.width} #{menu_item.item.height}"}>
              <.render_component id={menu_item.id} drag_attrs={drag_attrs} component={menu_item} />
            </svg>
          </SvgCanvasComponent.component>
        </:menu>
        <:body>
          <g class="w-full h-full" phx-update="stream" id="editor-body">
            <%= for {id, {component, meta}} <- @streams.components do %>
              <SvgCanvasComponent.component :let={drag_attrs} meta={meta}>
                <.render_component id={id} drag_attrs={drag_attrs} component={component} />
              </SvgCanvasComponent.component>
            <% end %>
          </g>
        </:body>
      </SvgCanvasComponent.render_svg_canvas>
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

    workflow_items =
      case Workflow.list_items(id) do
        NotReady -> []
        items -> items
      end

    components = Enum.map(workflow_items, &generate_body_component/1)

    menu_data =
      EditorItem.available_types()
      |> Map.keys()
      |> Enum.map(&generate_menu_item/1)

    socket =
      socket
      |> assign(:menu_data, menu_data)
      |> stream_configure(:components, dom_id: fn {item, _meta} -> item.id end)
      |> stream(:components, components)

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
    components = Enum.map(items, &generate_body_component/1)
    stream(socket, :components, components, replace: true)
  end

  def on_stream(
        {
          {EditorStream, workflow_id},
          %Operation.Insert{data: %EditorItem{} = item, key: key}
        },
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    {_, meta} = component = generate_body_component(item)

    if key != self() do
      insert_component(socket, component)
    else
      socket
      |> insert_component(component)
      |> handle_select(%{id: item.id})
      |> SvgCanvas.select_item(meta)
    end
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Delete{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_body_component(item)
    stream_delete(socket, :components, component)
  end

  def on_stream(
        {{EditorStream, workflow_id}, %Operation.Update{data: %EditorItem{} = item}},
        %Socket{assigns: %{workflow_id: workflow_id}} = socket
      ) do
    component = generate_body_component(item)
    insert_component(socket, component)
  end

  defp insert_component(%Socket{} = socket, {_, meta} = component) do
    socket
    |> stream_insert(:components, component, at: -1)
    |> SvgCanvas.push_to_foreground(meta)
  end

  defp generate_menu_item(type) do
    component =
      type
      |> EditorItem.create(%{x: 0, y: 0})
      |> Map.put(:id, type)
      |> generate_component()

    meta = ComponentMeta.menu_item_meta(type, @canvas_name)

    {component, meta}
  end

  defp generate_body_component(%EditorItem{} = item) do
    component = generate_component(item)

    meta = ComponentMeta.component_meta(item.id, @canvas_name)

    {component, meta}
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

  defp render_component(assigns) do
    ~H"""
    <svg
      id={@component.id}
      height={@component.item.height}
      width={@component.item.width}
      x={@component.item.position.x}
      y={@component.item.position.y}
      xmlns="http://www.w3.org/2000/svg"
    >
      <%= for {connector_id, connector} <- @component.item.connectors do %>
        <rect
          class={"fill-red-300 dark:fill-red-400 #{if match?(%{type: :hover}, @component.item.connected_items[connector_id]), do: 'opacity-70', else: 'opacity-0'}"}
          x={connector.x}
          y={connector.y}
          width={connector.width}
          height={connector.height}
        />
      <% end %>
      <path
        class={"#{@component.class} draggable cursor-move"}
        x={@component.item.position.x}
        y={@component.item.position.y}
        width={@component.item.width}
        height={@component.item.height}
        {@drag_attrs}
        d={@component.item.svg_path}
      />
      <%= for label <- @component.item.labels do %>
        <text x={label.x} y={label.y} class="text-[3px] font-bold font-mono pointer-events-none">
          <%= label.text %>
        </text>
      <% end %>
    </svg>
    """
  end
end
