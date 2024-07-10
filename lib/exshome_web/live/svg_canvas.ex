defmodule ExshomeWeb.Live.SvgCanvas do
  @moduledoc """
  Generic functions to interact with svg canvas.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  alias ExshomeWeb.Live.SvgCanvas.CanvasSettings
  alias ExshomeWeb.Live.SvgCanvas.ComponentMeta
  alias Phoenix.LiveView.Socket

  @type new_component_t() :: %{type: String.t(), position: %{x: number(), y: number()}}
  @type component_t() :: %{id: String.t(), position: %{x: number(), y: number()}}

  @callback handle_create(Socket.t(), new_component_t()) :: Socket.t()
  @callback handle_delete(Socket.t(), id :: String.t()) :: Socket.t()
  @callback handle_dragend(Socket.t(), component_t()) :: Socket.t()
  @callback handle_move(Socket.t(), component_t()) :: Socket.t()
  @callback handle_select(Socket.t(), component_t()) :: Socket.t()

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
      |> put_private(__MODULE__, mapping)
      |> attach_hook(
        CanvasSettings,
        :handle_event,
        &handle_event/3
      )

    socket =
      for {binary_name, name} <- mapping, reduce: socket do
        socket -> assign(socket, name, %CanvasSettings{name: binary_name})
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
      case settings.selected do
        %{type: "component"} ->
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

  defp on_canvas_event(
         "move",
         event,
         %CanvasSettings{selected: selected} = settings,
         %Socket{} = socket
       ) do
    on_move(selected[:type], event, settings, socket)
  end

  defp on_canvas_event(
         "dragend",
         %{"pointer" => %{"x" => x, "y" => y}},
         %CanvasSettings{} = settings,
         %Socket{} = socket
       )
       when is_number(x) and is_number(y) do
    socket = on_dragend(%{x: x, y: y}, settings, socket)

    settings
    |> CanvasSettings.on_dragend()
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

  defp on_move(nil, _, _, %Socket{} = socket) do
    {:halt, socket}
  end

  defp on_move("menu-item", _, %CanvasSettings{} = settings, %Socket{} = socket) do
    %CanvasSettings{
      selected: %{
        id: component_type,
        offset: offset,
        pointer: pointer
      },
      viewbox: viewbox,
      zoom: %{value: zoom}
    } = settings

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

  defp on_move(
         "background",
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

  defp on_move(
         "component",
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

  defp on_move(
         "scroll",
         %{"pointer" => %{"x" => x}},
         %CanvasSettings{selected: %{id: "x"}} = settings,
         %Socket{} = socket
       )
       when is_number(x) do
    settings
    |> CanvasSettings.on_body_scroll_x(x)
    |> update_canvas_settings_response(socket)
  end

  defp on_move(
         "scroll",
         %{"pointer" => %{"y" => y}},
         %CanvasSettings{selected: %{id: "y"}} = settings,
         %Socket{} = socket
       )
       when is_number(y) do
    settings
    |> CanvasSettings.on_body_scroll_y(y)
    |> update_canvas_settings_response(socket)
  end

  defp on_dragend(
         %{x: x, y: y},
         %CanvasSettings{selected: %{type: "component"}} = settings,
         %Socket{} = socket
       ) do
    id = extract_component_id(settings)

    if settings.trashbin.open? do
      socket.view.handle_delete(socket, id)
    else
      position = compute_element_position(settings, x, y)
      socket.view.handle_dragend(socket, %{id: id, position: position})
    end
  end

  defp on_dragend(_, _, %Socket{} = socket), do: socket

  defp update_canvas_settings_response(%CanvasSettings{} = settings, %Socket{} = socket) do
    {:halt, update_canvas_settings(settings, socket)}
  end

  defp update_canvas_settings(%CanvasSettings{name: name} = settings, %Socket{} = socket) do
    name = get_name_from_mapping!(socket, name)
    assign(socket, name, settings)
  end

  @spec push_to_foreground(Socket.t(), ComponentMeta.t()) :: Socket.t()
  def push_to_foreground(%Socket{} = socket, %ComponentMeta{} = meta) do
    push_event(socket, "move-to-foreground", %{
      component: ComponentMeta.to_component(meta)
    })
  end

  @spec select_item(Socket.t(), ComponentMeta.t()) :: Socket.t()
  def select_item(%Socket{} = socket, meta) do
    push_event(socket, "select-item", %{
      component: ComponentMeta.to_component(meta)
    })
  end

  def on_update_zoom(%Socket{} = socket, %CanvasSettings{} = settings, update_fn)
      when is_function(update_fn, 1) do
    settings
    |> CanvasSettings.update_zoom(update_fn)
    |> update_canvas_settings_response(socket)
  end

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

  defp extract_component_id(%CanvasSettings{selected: %{id: id, type: "component"}}), do: id

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
