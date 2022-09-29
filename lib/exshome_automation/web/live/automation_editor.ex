defmodule ExshomeAutomation.Web.Live.AutomationEditor do
  @moduledoc """
  Automation editor page
  """
  alias ExshomeAutomation.Web.Live.Automation.AutomationBlock

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖"

  use ExshomeWeb.Live.SvgCanvas

  @impl LiveView
  def mount(_params, _session, socket) do
    socket = assign(socket, selected: nil, drag: false)
    components = for x <- 1..5, do: generate_component("rect-#{x}", socket)

    menu_item = generate_component("rect", socket)

    socket =
      socket
      |> SvgCanvas.render_components(components)
      |> SvgCanvas.render_menu_items([menu_item])

    {:ok, socket}
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
    component =
      id
      |> generate_component(socket)
      |> Map.update!(:class, &"#{&1} hidden")

    socket
    |> assign(selected: nil, drag: false)
    |> SvgCanvas.render_components([component])
  end

  @impl SvgCanvas
  def handle_dragend(%Socket{} = socket, %{id: id, position: position}) do
    socket = assign(socket, :drag, false)
    component = generate_component(id, socket, position)
    SvgCanvas.render_components(socket, [component])
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, %{id: id, position: position}) do
    socket = assign(socket, drag: true)
    component = generate_component(id, socket, position)

    socket
    |> update(:selected, &%{&1 | position: %{x: component.x, y: component.y}})
    |> SvgCanvas.render_components([component])
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

    socket
    |> SvgCanvas.render_components(components)
    |> SvgCanvas.push_to_foreground(selected.id)
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