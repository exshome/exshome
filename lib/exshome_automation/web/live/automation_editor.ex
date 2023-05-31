defmodule ExshomeAutomation.Web.Live.AutomationEditor do
  @moduledoc """
  Automation editor page
  """
  alias Exshome.Dependency
  alias ExshomeAutomation.Services.Workflow
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
      |> assign(selected: nil, drag: false)
      |> put_dependencies([{{Workflow, id}, :workflow}])

    components = for x <- 1..5, do: generate_component("rect-#{x}", socket)

    menu_item = generate_component("rect", socket)

    socket =
      socket
      |> SvgCanvas.replace_components(components)
      |> SvgCanvas.render_menu_items([menu_item])

    {:ok, socket}
  end

  @impl LiveView
  def handle_event("rename_workflow", %{"new_name" => value}, socket) do
    Workflow.rename(socket.assigns.deps.workflow.id, value)
    {:noreply, socket}
  end

  @impl SvgCanvas
  def handle_create(%Socket{} = socket, %{type: type, position: position}) do
    id = "#{type}-#{Ecto.UUID.generate()}"

    socket
    |> handle_select(%{id: id, position: position})
    |> SvgCanvas.select_item(id)
  end

  @impl SvgCanvas
  def handle_delete(%Socket{} = socket, id) do
    component = generate_component(id, socket)

    socket
    |> assign(selected: nil, drag: false)
    |> SvgCanvas.remove_component(component)
  end

  @impl SvgCanvas
  def handle_dragend(%Socket{} = socket, %{id: id, position: position}) do
    socket = assign(socket, :drag, false)
    component = generate_component(id, socket, position)
    SvgCanvas.insert_component(socket, component)
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, %{id: id, position: position}) do
    socket = assign(socket, drag: true)
    component = generate_component(id, socket, position)

    socket
    |> update(:selected, &%{&1 | position: %{x: component.x, y: component.y}})
    |> SvgCanvas.insert_component(component)
  end

  @impl SvgCanvas
  def handle_select(%Socket{} = socket, %{} = selected) do
    old_selected = socket.assigns.selected
    socket = assign(socket, :selected, selected)

    components =
      case {old_selected, selected} do
        {nil, selected} -> [selected]
        {%{id: id}, %{id: id}} -> [selected]
        _ -> [old_selected, selected]
      end
      |> Enum.map(&generate_component(&1.id, socket, &1.position))

    for component <- components, reduce: socket do
      socket -> SvgCanvas.insert_component(socket, component)
    end
  end

  defp generate_component(id, socket, position \\ %{x: 0, y: 0}) do
    %SvgCanvas{canvas: canvas} = SvgCanvas.get_svg_meta(socket)
    %{x: x, y: y} = position
    %{selected: selected, drag: drag} = socket.assigns
    selected? = selected && selected.id == id
    width = 25
    height = 25

    %AutomationBlock{
      id: id,
      class: """
      fill-green-200
      #{if selected? && drag, do: "opacity-75"}
      #{if selected?, do: "stroke-yellow-200 dark:stroke-yellow-400"}
      """,
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
