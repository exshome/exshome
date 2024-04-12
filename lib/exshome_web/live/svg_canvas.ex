defmodule ExshomeWeb.Live.SvgCanvas do
  @moduledoc """
  Generic functions to interact with svg canvas.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  alias ExshomeWeb.Live.SvgCanvas.CanvasSettings
  alias Phoenix.LiveView.Socket

  @type new_component_t() :: %{type: String.t(), position: %{x: number(), y: number()}}
  @type component_t() :: %{id: String.t(), position: %{x: number(), y: number()}}

  @callback handle_create(Socket.t(), new_component_t()) :: Socket.t()
  @callback handle_delete(Socket.t(), id :: String.t()) :: Socket.t()
  @callback handle_dragend(Socket.t(), component_t()) :: Socket.t()
  @callback handle_move(Socket.t(), component_t()) :: Socket.t()
  @callback handle_select(Socket.t(), component_t()) :: Socket.t()

  @components_key :__components__
  @menu_items_key :__menu_items__
  @meta_key :__svg_meta__

  @spec get_svg_meta(Socket.t()) :: CanvasSettings.t()
  def get_svg_meta(%Socket{assigns: %{@meta_key => %CanvasSettings{} = svg_meta}}), do: svg_meta

  def on_mount(name, _params, _session, %Socket{} = socket) do
    canvas_name = Atom.to_string(name)

    socket =
      socket
      |> assign(@meta_key, %CanvasSettings{name: canvas_name})
      |> stream_configure(@components_key, [])
      |> assign(@menu_items_key, [])
      |> attach_hook(
        CanvasSettings,
        :handle_event,
        &handle_event/3
      )

    {:cont, socket}
  end

  def handle_event("create", _, %Socket{} = socket) do
    %CanvasSettings{selected: selected, viewbox: viewbox, zoom: %{value: zoom}} =
      get_svg_meta(socket)

    case selected do
      nil ->
        {:halt, socket}

      %{offset: %{x: offset_x, y: offset_y}, pointer: %{x: pointer_x, y: pointer_y}} ->
        component_type = extract_menu_item_type(socket)
        component_x = viewbox.x + pointer_x / zoom - offset_x
        component_y = viewbox.y + pointer_y / zoom - offset_y

        socket
        |> socket.view.handle_create(%{
          type: component_type,
          position: %{
            x: component_x,
            y: component_y
          }
        })
        |> update_svg_meta_response(&CanvasSettings.on_create/1)
    end
  end

  def handle_event(
        "dragend",
        %{"pointer" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) do
    %CanvasSettings{trashbin: trashbin} = get_svg_meta(socket)

    socket =
      case {component_type(socket), trashbin.open?} do
        {:component, true} ->
          id = extract_component_id(socket)

          socket.view.handle_delete(socket, id)

        {:component, false} ->
          socket.view.handle_dragend(
            socket,
            %{
              id: extract_component_id(socket),
              position: compute_element_position(socket, x, y)
            }
          )

        _ ->
          socket
      end

    update_svg_meta_response(socket, &CanvasSettings.on_dragend/1)
  end

  def handle_event("menu-close-" <> _name, _, %Socket{} = socket) do
    update_svg_meta_response(socket, &CanvasSettings.on_menu_close(&1))
  end

  def handle_event("menu-toggle-" <> _name, _, %Socket{} = socket) do
    update_svg_meta_response(socket, &CanvasSettings.on_menu_toggle(&1))
  end

  def handle_event("move", %{"pointer" => %{"x" => x, "y" => y}}, %Socket{} = socket)
      when is_number(x) and is_number(y) do
    socket = update_svg_meta(socket, &CanvasSettings.on_drag(&1, %{x: x, y: y}))
    new_position = compute_element_position(socket, x, y)

    id = extract_component_id(socket)
    {:halt, socket.view.handle_move(socket, %{id: id, position: new_position})}
  end

  def handle_event("move-background", %{"pointer" => %{"x" => x, "y" => y}}, %Socket{} = socket)
      when is_number(x) and is_number(y) do
    %CanvasSettings{
      selected: %{position: %{x: original_x, y: original_y}}
    } = get_svg_meta(socket)

    %{x: new_x, y: new_y} = compute_element_position(socket, x, y)
    delta = %{x: 2 * original_x - new_x, y: 2 * original_y - new_y}
    update_svg_meta_response(socket, &CanvasSettings.set_viewbox_position(&1, delta))
  end

  def handle_event("resize", %{"height" => height, "width" => width}, %Socket{} = socket)
      when is_number(height) and is_number(width) do
    update_svg_meta_response(socket, &CanvasSettings.on_resize(&1, height, width))
  end

  def handle_event("scroll-body-x", %{"pointer" => %{"x" => x}}, %Socket{} = socket)
      when is_number(x) do
    update_svg_meta_response(socket, &CanvasSettings.on_body_scroll_x(&1, x))
  end

  def handle_event("scroll-body-y", %{"pointer" => %{"y" => y}}, %Socket{} = socket)
      when is_number(y) do
    update_svg_meta_response(socket, &CanvasSettings.on_body_scroll_y(&1, y))
  end

  def handle_event("select", event, %Socket{} = socket) do
    socket = update_svg_meta(socket, &CanvasSettings.on_select(&1, event))
    %CanvasSettings{selected: selected} = get_svg_meta(socket)

    socket =
      case component_type(selected.component) do
        :component ->
          socket.view.handle_select(
            socket,
            %{
              id: extract_component_id(socket),
              position:
                compute_element_position(
                  socket,
                  selected.pointer.x,
                  selected.pointer.y
                )
            }
          )

        _ ->
          socket
      end

    {:halt, socket}
  end

  def handle_event(
        "zoom-desktop",
        %{"delta" => delta, "pointer" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      )
      when is_number(delta) and is_number(x) and is_number(y) do
    update_svg_meta_response(socket, &CanvasSettings.on_zoom_desktop(&1, delta, x, y))
  end

  def handle_event(
        "zoom-mobile",
        %{
          "original" => %{"position" => original_position, "touches" => original_touches},
          "current" => current_touches
        },
        %Socket{} = socket
      ) do
    original_position = to_point(original_position)
    original_touches = Enum.map(original_touches, &to_point/1)
    current_touches = Enum.map(current_touches, &to_point/1)

    update_svg_meta_response(
      socket,
      &CanvasSettings.on_zoom_mobile(&1, original_position, original_touches, current_touches)
    )
  end

  def handle_event("zoom-in-" <> _name, _, %Socket{} = socket) do
    on_update_zoom(socket, &(&1 + 1))
  end

  def handle_event("zoom-out-" <> _name, _, %Socket{} = socket) do
    on_update_zoom(socket, &(&1 - 1))
  end

  def handle_event("set-zoom-" <> _name, %{"zoom" => value}, %Socket{} = socket) do
    new_zoom = String.to_integer(value)
    on_update_zoom(socket, fn _ -> new_zoom end)
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:cont, socket}
  end

  @spec replace_components(Socket.t(), list()) :: Socket.t()
  def replace_components(%Socket{} = socket, components) do
    stream(socket, @components_key, components, reset: true)
  end

  @spec insert_component(Socket.t(), map()) :: Socket.t()
  def insert_component(%Socket{} = socket, component) do
    socket
    |> stream_insert(@components_key, component, at: -1)
    |> push_to_foreground(component.id)
  end

  @spec remove_component(Socket.t(), map()) :: Socket.t()
  def remove_component(%Socket{} = socket, component) do
    stream_delete(socket, @components_key, component)
  end

  @spec push_to_foreground(Socket.t(), String.t()) :: Socket.t()
  def push_to_foreground(%Socket{} = socket, id) do
    push_event(socket, "move-to-foreground", %{
      component: generate_component_id(socket, id)
    })
  end

  @spec render_menu_items(Socket.t(), list()) :: Socket.t()
  def render_menu_items(%Socket{} = socket, menu_items) do
    assign(socket, @menu_items_key, menu_items)
  end

  @spec select_item(Socket.t(), String.t()) :: Socket.t()
  def select_item(%Socket{} = socket, id) do
    push_event(socket, "select-item", %{
      component: generate_component_id(socket, id)
    })
  end

  def on_update_zoom(%Socket{} = socket, update_fn) when is_function(update_fn, 1) do
    update_svg_meta_response(socket, fn %CanvasSettings{} = meta ->
      CanvasSettings.update_zoom(meta, update_fn)
    end)
  end

  defp component_type("canvas-background-" <> _), do: :background

  defp component_type("component-" <> _), do: :component

  defp component_type("menu-item-" <> _), do: :menu_item

  defp component_type("scroll-body-x-" <> _), do: :scroll_body_x

  defp component_type("scroll-body-y-" <> _), do: :scroll_body_y

  defp component_type(%Socket{} = socket) do
    %CanvasSettings{selected: selected} = get_svg_meta(socket)

    case selected do
      %{component: component} -> component_type(component)
      _ -> :unknown
    end
  end

  defp compute_element_position(%Socket{} = socket, x, y) do
    %CanvasSettings{
      selected: %{
        position: %{x: original_x, y: original_y},
        pointer: pointer
      },
      zoom: %{value: zoom}
    } = get_svg_meta(socket)

    delta_x = (x - pointer.x) / zoom
    delta_y = (y - pointer.y) / zoom

    new_x = original_x + delta_x
    new_y = original_y + delta_y

    %{x: new_x, y: new_y}
  end

  defp generate_component_id(%Socket{} = socket, id) do
    "component-#{get_svg_meta(socket).name}-#{id}"
  end

  defp extract_component_id(%Socket{} = socket) do
    %CanvasSettings{selected: %{component: component}, name: name} = get_svg_meta(socket)
    prefix = "component-#{name}-"
    String.replace(component, prefix, "")
  end

  defp extract_menu_item_type(%Socket{} = socket) do
    %CanvasSettings{selected: %{component: component}, name: name} = get_svg_meta(socket)
    prefix = "menu-item-#{name}-"
    String.replace(component, prefix, "")
  end

  defp to_point(%{"x" => x, "y" => y}) when is_number(x) and is_number(y) do
    %{x: x, y: y}
  end

  defp update_svg_meta_response(%Socket{} = socket, fun) do
    {:halt, update_svg_meta(socket, fun)}
  end

  defp update_svg_meta(%Socket{} = socket, fun), do: update(socket, @meta_key, fun)

  defmacro __using__(_) do
    quote do
      alias ExshomeWeb.Live.SvgCanvas
      on_mount(SvgCanvas)
      @behaviour SvgCanvas
    end
  end
end
