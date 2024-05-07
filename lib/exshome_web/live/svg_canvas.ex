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
  defp get_svg_meta(%Socket{} = socket, binary_name) do
    key = get_name_from_mapping!(socket, binary_name)
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

  def handle_event("canvas-" <> event, %{"name" => binary_name} = params, %Socket{} = socket) do
    %CanvasSettings{} = settings = get_svg_meta(socket, binary_name)
    on_canvas_event(event, params, settings, socket)
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:cont, socket}
  end

  @spec on_canvas_event(String.t(), map(), CanvasSettings.t(), Socket.t()) ::
          {:cont, Socket.t()} | {:halt, Socket.t()}

  defp on_canvas_event(
         "resize",
         %{"height" => height, "width" => width},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(height) and is_number(width) do
    settings
    |> CanvasSettings.on_resize(height, width)
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event("menu-toggle", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    settings
    |> CanvasSettings.on_menu_toggle()
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event("menu-close", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    settings
    |> CanvasSettings.on_menu_close()
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event("select", event, %CanvasSettings{} = settings, %Socket{} = socket) do
    settings = CanvasSettings.on_select(settings, event)

    socket = update_canvas_settings(settings, socket)

    socket =
      case component_type(settings) do
        :component ->
          socket.view.handle_select(
            socket,
            %{
              id: extract_component_id(settings),
              position:
                compute_element_position(
                  settings,
                  settings.selected.pointer.x,
                  settings.selected.pointer.y
                )
            }
          )

        _ ->
          socket
      end

    {:halt, socket}
  end

  defp on_canvas_event("create", _, %CanvasSettings{selected: nil}, %Socket{} = socket),
    do: {:halt, socket}

  defp on_canvas_event("create", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    %CanvasSettings{
      selected: %{
        offset: offset,
        pointer: pointer,
        component: component
      },
      viewbox: viewbox,
      zoom: %{value: zoom}
    } = settings

    prefix = "menu-item-#{settings.name}-"
    component_type = String.replace(component, prefix, "")
    component_x = viewbox.x + pointer.x / zoom - offset.x
    component_y = viewbox.y + pointer.y / zoom - offset.y

    socket =
      settings
      |> CanvasSettings.on_create()
      |> update_canvas_settings(socket)
      |> socket.view.handle_create(%{
        type: component_type,
        position: %{
          x: component_x,
          y: component_y
        }
      })

    {:halt, socket}
  end

  defp on_canvas_event(
         "move",
         %{"pointer" => %{"x" => x, "y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(x) and is_number(y) do
    settings = CanvasSettings.on_drag(settings, %{x: x, y: y})
    new_position = compute_element_position(settings, x, y)
    socket = update_canvas_settings(settings, socket)

    id = extract_component_id(settings)
    {:halt, socket.view.handle_move(socket, %{id: id, position: new_position})}
  end

  defp on_canvas_event(
         "move-background",
         %{"pointer" => %{"x" => x, "y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(x) and is_number(y) do
    %CanvasSettings{
      selected: %{position: %{x: original_x, y: original_y}}
    } = settings

    %{x: new_x, y: new_y} = compute_element_position(settings, x, y)
    delta = %{x: 2 * original_x - new_x, y: 2 * original_y - new_y}

    settings
    |> CanvasSettings.set_viewbox_position(delta)
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event(
         "dragend",
         %{"pointer" => %{"x" => x, "y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(x) and is_number(y) do
    socket =
      case {component_type(settings), settings.trashbin.open?} do
        {:component, true} ->
          id = extract_component_id(settings)

          socket.view.handle_delete(socket, id)

        {:component, false} ->
          socket.view.handle_dragend(
            socket,
            %{
              id: extract_component_id(settings),
              position: compute_element_position(settings, x, y)
            }
          )

        _ ->
          socket
      end

    settings
    |> CanvasSettings.on_dragend()
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event(
         "scroll-body-x",
         %{"pointer" => %{"x" => x}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(x) do
    settings
    |> CanvasSettings.on_body_scroll_x(x)
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event(
         "scroll-body-y",
         %{"pointer" => %{"y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(y) do
    settings
    |> CanvasSettings.on_body_scroll_y(y)
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event("zoom-in", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    on_update_zoom(socket, settings, &(&1 + 1))
  end

  defp on_canvas_event("zoom-out", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    on_update_zoom(socket, settings, &(&1 - 1))
  end

  defp on_canvas_event(
         "set-zoom",
         %{"zoom" => value},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       ) do
    new_zoom = String.to_integer(value)
    on_update_zoom(socket, settings, fn _ -> new_zoom end)
  end

  defp on_canvas_event(
         "zoom-desktop",
         %{"delta" => delta, "pointer" => %{"x" => x, "y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(delta) and is_number(x) and is_number(y) do
    settings
    |> CanvasSettings.on_zoom_desktop(delta, x, y)
    |> update_canvas_settings_response(socket)
  end

  defp on_canvas_event(
         "zoom-mobile",
         %{
           "original" => %{"position" => original_position, "touches" => original_touches},
           "current" => current_touches
         },
         %CanvasSettings{} = settings,
         %Socket{} = socket
       ) do
    original_position = to_point(original_position)
    original_touches = Enum.map(original_touches, &to_point/1)
    current_touches = Enum.map(current_touches, &to_point/1)

    settings
    |> CanvasSettings.on_zoom_mobile(original_position, original_touches, current_touches)
    |> update_canvas_settings_response(socket)
  end

  defp update_canvas_settings_response(%CanvasSettings{} = settings, %Socket{} = socket) do
    {:halt, update_canvas_settings(settings, socket)}
  end

  defp update_canvas_settings(%CanvasSettings{name: name} = settings, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, name)
    assign(socket, name, settings)
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

  def on_update_zoom(%Socket{} = socket, %CanvasSettings{} = settings, update_fn)
      when is_function(update_fn, 1) do
    settings
    |> CanvasSettings.update_zoom(update_fn)
    |> update_canvas_settings_response(socket)
  end

  defp component_type("canvas-background"), do: :background

  defp component_type("component-" <> _), do: :component

  defp component_type("menu-item-" <> _), do: :menu_item

  defp component_type("scroll-body-x"), do: :scroll_body_x

  defp component_type("scroll-body-y"), do: :scroll_body_y

  defp component_type(%CanvasSettings{selected: nil}), do: :unknown

  defp component_type(%CanvasSettings{selected: %{component: component}}),
    do: component_type(component)

  defp compute_element_position(%CanvasSettings{} = settings, x, y) do
    %CanvasSettings{
      selected: %{
        position: %{x: original_x, y: original_y},
        pointer: pointer
      },
      zoom: %{value: zoom}
    } = settings

    delta_x = (x - pointer.x) / zoom
    delta_y = (y - pointer.y) / zoom

    new_x = original_x + delta_x
    new_y = original_y + delta_y

    %{x: new_x, y: new_y}
  end

  defp generate_component_id(%Socket{} = socket, name, id) do
    "component-#{get_svg_meta(socket, name).name}-#{id}"
  end

  defp extract_component_id(%CanvasSettings{} = settings) do
    prefix = "component-#{settings.name}-"
    String.replace(settings.selected.component, prefix, "")
  end

  defp to_point(%{"x" => x, "y" => y}) when is_number(x) and is_number(y) do
    %{x: x, y: y}
  end

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.Live.SvgCanvas
      on_mount({SvgCanvas, unquote(config)})
      @behaviour SvgCanvas
    end
  end
end
