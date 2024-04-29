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

  @menu_items_key :__menu_items__

  @spec get_svg_meta(Socket.t(), binary()) :: CanvasSettings.t()
  defp get_svg_meta(%Socket{private: %{__MODULE__ => mapping}} = socket, binary_name) do
    key = Map.fetch!(mapping, binary_name)
    Map.fetch!(socket.assigns, key)
  end

  @spec get_name_from_mapping!(Socket.t(), String.t()) :: atom()
  defp get_name_from_mapping!(%Socket{private: %{__MODULE__ => mapping}}, name) do
    Map.fetch!(mapping, name)
  end

  def on_mount(canvas_settings, _params, _session, %Socket{} = socket) do
    mapping = Map.new(canvas_settings, &{Atom.to_string(&1), &1})

    socket =
      socket
      |> assign_new(@menu_items_key, fn -> %{} end)
      |> put_private(__MODULE__, mapping)
      |> attach_hook(
        CanvasSettings,
        :handle_event,
        &handle_event/3
      )

    socket =
      for {binary_name, name} <- mapping, reduce: socket do
        socket ->
          socket
          |> assign(name, %CanvasSettings{name: binary_name})
          |> stream_configure(name, [])
          |> stream(name, [])
          |> update(@menu_items_key, &Map.put(&1, name, []))
      end

    {:cont, socket}
  end

  def handle_event("canvas-create", %{"name" => binary_name}, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, binary_name)

    %CanvasSettings{selected: selected, viewbox: viewbox, zoom: %{value: zoom}} =
      get_svg_meta(socket, binary_name)

    case selected do
      nil ->
        {:halt, socket}

      %{
        offset: %{x: offset_x, y: offset_y},
        pointer: %{x: pointer_x, y: pointer_y},
        component: component
      } ->
        prefix = "menu-item-#{name}-"
        component_type = String.replace(component, prefix, "")
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
        |> update_svg_meta_response(name, &CanvasSettings.on_create/1)
    end
  end

  def handle_event(
        "canvas-dragend",
        %{"pointer" => %{"x" => x, "y" => y}, "name" => binary_name},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) do
    name = get_name_from_mapping!(socket, binary_name)
    %CanvasSettings{trashbin: trashbin} = get_svg_meta(socket, binary_name)

    socket =
      case {component_type(socket, binary_name), trashbin.open?} do
        {:component, true} ->
          id = extract_component_id(socket, binary_name)

          socket.view.handle_delete(socket, id)

        {:component, false} ->
          socket.view.handle_dragend(
            socket,
            %{
              id: extract_component_id(socket, binary_name),
              position: compute_element_position(socket, binary_name, x, y)
            }
          )

        _ ->
          socket
      end

    update_svg_meta_response(socket, name, &CanvasSettings.on_dragend/1)
  end

  def handle_event("canvas-menu-close", %{"name" => name}, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_menu_close(&1))
  end

  def handle_event("canvas-menu-toggle", %{"name" => name}, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_menu_toggle(&1))
  end

  def handle_event(
        "canvas-move",
        %{"pointer" => %{"x" => x, "y" => y}, "name" => binary_name},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) do
    name = get_name_from_mapping!(socket, binary_name)
    socket = update_svg_meta(socket, name, &CanvasSettings.on_drag(&1, %{x: x, y: y}))
    new_position = compute_element_position(socket, binary_name, x, y)

    id = extract_component_id(socket, binary_name)
    {:halt, socket.view.handle_move(socket, %{id: id, position: new_position})}
  end

  def handle_event(
        "canvas-move-background",
        %{"pointer" => %{"x" => x, "y" => y}, "name" => binary_name},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) do
    name = get_name_from_mapping!(socket, binary_name)

    %CanvasSettings{
      selected: %{position: %{x: original_x, y: original_y}}
    } = get_svg_meta(socket, binary_name)

    %{x: new_x, y: new_y} = compute_element_position(socket, binary_name, x, y)
    delta = %{x: 2 * original_x - new_x, y: 2 * original_y - new_y}
    update_svg_meta_response(socket, name, &CanvasSettings.set_viewbox_position(&1, delta))
  end

  def handle_event(
        "canvas-resize",
        %{"height" => height, "width" => width, "name" => name},
        %Socket{} = socket
      )
      when is_number(height) and is_number(width) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_resize(&1, height, width))
  end

  def handle_event(
        "canvas-scroll-body-x",
        %{"pointer" => %{"x" => x}, "name" => name},
        %Socket{} = socket
      )
      when is_number(x) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_body_scroll_x(&1, x))
  end

  def handle_event(
        "canvas-scroll-body-y",
        %{"pointer" => %{"y" => y}, "name" => name},
        %Socket{} = socket
      )
      when is_number(y) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_body_scroll_y(&1, y))
  end

  def handle_event("canvas-select", %{"name" => binary_name} = event, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, binary_name)
    socket = update_svg_meta(socket, name, &CanvasSettings.on_select(&1, event))
    %CanvasSettings{selected: selected} = get_svg_meta(socket, binary_name)

    socket =
      case component_type(selected.component) do
        :component ->
          socket.view.handle_select(
            socket,
            %{
              id: extract_component_id(socket, binary_name),
              position:
                compute_element_position(
                  socket,
                  binary_name,
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
        "canvas-zoom-desktop",
        %{"delta" => delta, "pointer" => %{"x" => x, "y" => y}, "name" => name},
        %Socket{} = socket
      )
      when is_number(delta) and is_number(x) and is_number(y) do
    name = get_name_from_mapping!(socket, name)
    update_svg_meta_response(socket, name, &CanvasSettings.on_zoom_desktop(&1, delta, x, y))
  end

  def handle_event(
        "canvas-zoom-mobile",
        %{
          "original" => %{"position" => original_position, "touches" => original_touches},
          "current" => current_touches,
          "name" => name
        },
        %Socket{} = socket
      ) do
    name = get_name_from_mapping!(socket, name)
    original_position = to_point(original_position)
    original_touches = Enum.map(original_touches, &to_point/1)
    current_touches = Enum.map(current_touches, &to_point/1)

    update_svg_meta_response(
      socket,
      name,
      &CanvasSettings.on_zoom_mobile(&1, original_position, original_touches, current_touches)
    )
  end

  def handle_event("canvas-zoom-in", %{"name" => name}, %Socket{} = socket) do
    on_update_zoom(socket, name, &(&1 + 1))
  end

  def handle_event("canvas-zoom-out", %{"name" => name}, %Socket{} = socket) do
    on_update_zoom(socket, name, &(&1 - 1))
  end

  def handle_event("canvas-set-zoom", %{"zoom" => value, "name" => name}, %Socket{} = socket) do
    new_zoom = String.to_integer(value)
    on_update_zoom(socket, name, fn _ -> new_zoom end)
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:cont, socket}
  end

  @spec replace_components(Socket.t(), atom(), list()) :: Socket.t()
  def replace_components(%Socket{} = socket, name, components) do
    stream(socket, name, components, reset: true)
  end

  @spec insert_component(Socket.t(), atom(), map()) :: Socket.t()
  def insert_component(%Socket{} = socket, name, component) do
    socket
    |> stream_insert(name, component, at: -1)
    |> push_to_foreground(name, component.id)
  end

  @spec remove_component(Socket.t(), atom(), map()) :: Socket.t()
  def remove_component(%Socket{} = socket, name, component) do
    stream_delete(socket, name, component)
  end

  @spec push_to_foreground(Socket.t(), atom(), String.t()) :: Socket.t()
  def push_to_foreground(%Socket{} = socket, name, id) do
    push_event(socket, "move-to-foreground", %{
      component: generate_component_id(socket, Atom.to_string(name), id)
    })
  end

  @spec render_menu_items(Socket.t(), atom(), list()) :: Socket.t()
  def render_menu_items(%Socket{} = socket, name, menu_items) do
    update(socket, @menu_items_key, &Map.put(&1, name, menu_items))
  end

  @spec select_item(Socket.t(), atom(), String.t()) :: Socket.t()
  def select_item(%Socket{} = socket, name, id) do
    push_event(socket, "select-item", %{
      component: generate_component_id(socket, Atom.to_string(name), id)
    })
  end

  def on_update_zoom(%Socket{} = socket, name, update_fn) when is_function(update_fn, 1) do
    name = get_name_from_mapping!(socket, name)

    update_svg_meta_response(socket, name, fn %CanvasSettings{} = meta ->
      CanvasSettings.update_zoom(meta, update_fn)
    end)
  end

  defp component_type("canvas-background"), do: :background

  defp component_type("component-" <> _), do: :component

  defp component_type("menu-item-" <> _), do: :menu_item

  defp component_type("scroll-body-x"), do: :scroll_body_x

  defp component_type("scroll-body-y"), do: :scroll_body_y

  defp component_type(%Socket{} = socket, name) do
    %CanvasSettings{selected: selected} = get_svg_meta(socket, name)

    case selected do
      %{component: component} -> component_type(component)
      _ -> :unknown
    end
  end

  defp compute_element_position(%Socket{} = socket, name, x, y) do
    %CanvasSettings{
      selected: %{
        position: %{x: original_x, y: original_y},
        pointer: pointer
      },
      zoom: %{value: zoom}
    } = get_svg_meta(socket, name)

    delta_x = (x - pointer.x) / zoom
    delta_y = (y - pointer.y) / zoom

    new_x = original_x + delta_x
    new_y = original_y + delta_y

    %{x: new_x, y: new_y}
  end

  defp generate_component_id(%Socket{} = socket, name, id) do
    "component-#{get_svg_meta(socket, name).name}-#{id}"
  end

  defp extract_component_id(%Socket{} = socket, name) do
    %CanvasSettings{selected: %{component: component}} = get_svg_meta(socket, name)
    prefix = "component-#{name}-"
    String.replace(component, prefix, "")
  end

  defp to_point(%{"x" => x, "y" => y}) when is_number(x) and is_number(y) do
    %{x: x, y: y}
  end

  defp update_svg_meta_response(%Socket{} = socket, name, fun) do
    {:halt, update_svg_meta(socket, name, fun)}
  end

  defp update_svg_meta(%Socket{} = socket, name, fun), do: update(socket, name, fun)

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.Live.SvgCanvas
      on_mount({SvgCanvas, unquote(config)})
      @behaviour SvgCanvas
    end
  end
end
