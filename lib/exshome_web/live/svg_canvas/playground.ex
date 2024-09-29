defmodule ExshomeWeb.Live.SvgCanvas.Playground do
  @moduledoc """
  Simple canvas playground.
  """

  alias ExshomeWeb.Live.SvgCanvas.ComponentMeta
  alias ExshomeWeb.SvgCanvasComponent

  use ExshomeWeb.Live.AppPage

  @canvas_name :playground

  use ExshomeWeb.Live.SvgCanvas, [@canvas_name]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <SvgCanvasComponent.render_svg_canvas meta={@playground}>
      <:menu :for={item <- @menu_data}>
        <SvgCanvasComponent.component :let={drag_attrs} meta={item.meta}>
          <svg>
            <.render_component drag_attrs={drag_attrs} item={item} />
          </svg>
        </SvgCanvasComponent.component>
      </:menu>
      <:body>
        <SvgCanvasComponent.component :let={drag_attrs} :for={item <- @components} meta={item.meta}>
          <.render_component drag_attrs={drag_attrs} item={item} />
        </SvgCanvasComponent.component>
      </:body>
    </SvgCanvasComponent.render_svg_canvas>
    """
  end

  @impl LiveView
  def mount(_, _, socket) do
    menu_data =
      ["red", "green", "blue"]
      |> Enum.map(
        &generate_component(
          &1,
          {0, 0},
          &1,
          ComponentMeta.menu_item_meta(&1, @canvas_name)
        )
      )

    socket =
      socket
      |> assign(:menu_data, menu_data)
      |> assign(:selected_id, nil)
      |> assign(:components, [])
      |> highlight_selection()

    {:ok, socket}
  end

  @impl SvgCanvas
  def handle_create(socket, %{position: %{y: y, x: x}, type: type}) do
    id = Ecto.UUID.generate()

    new_component =
      generate_component(id, {x, y}, type, ComponentMeta.component_meta(id, @canvas_name))

    socket
    |> update(:components, &(&1 ++ [new_component]))
    |> highlight_selection()
    |> SvgCanvas.select_item(new_component.meta)
  end

  @impl SvgCanvas
  def handle_select(socket, %{id: id}) do
    socket
    |> assign(:selected_id, id)
    |> highlight_selection()
    |> selected_to_front()
  end

  @impl SvgCanvas
  def handle_move(socket, %{id: id, position: %{x: x, y: y}}) do
    socket
    |> update(
      :components,
      &Enum.map(&1, fn item -> update_position(item, id, {x, y}) end)
    )
  end

  @impl SvgCanvas
  def handle_dragend(socket, event), do: handle_move(socket, event)

  @impl SvgCanvas
  def handle_delete(socket, id) do
    update(
      socket,
      :components,
      &Enum.reject(&1, fn %{id: component_id} -> id == component_id end)
    )
  end

  defp highlight_selection(socket) do
    selected_id = socket.assigns.selected_id

    socket
    |> update(
      :components,
      &Enum.map(&1, fn item -> %{item | selected?: item.id == selected_id} end)
    )
  end

  defp selected_to_front(socket) do
    selected_id = socket.assigns.selected_id
    {selected, components} = Enum.split_with(socket.assigns.components, &(&1.id == selected_id))
    assign(socket, :components, components ++ selected)
  end

  defp generate_component(id, {x, y}, color, meta) do
    %{id: id, x: x, y: y, color: color, meta: meta, selected?: false}
  end

  defp update_position(%{id: id} = item, id, {x, y}), do: %{item | x: x, y: y}

  defp update_position(item, _, _), do: item

  defp render_component(assigns) do
    ~H"""
    <rect
      id={@item.id}
      x={@item.x}
      y={@item.y}
      width="20"
      height="20"
      fill={@item.color}
      {@drag_attrs}
      stroke={if @item.selected?, do: "yellow", else: "black"}
    />
    """
  end
end
