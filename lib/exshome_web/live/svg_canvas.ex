defmodule ExshomeWeb.Live.SvgCanvas do
  @moduledoc """
  Generic functions to interact with svg canvas.
  """
  import Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  defstruct [
    :name,
    :selected,
    canvas: %{height: 500, width: 500},
    class: "opacity-0",
    menu: %{
      open?: false,
      size: 70,
      x: 0,
      y: 0
    },
    screen: %{height: 100, width: 100},
    scroll: %{
      x: 0,
      y: 0,
      ratio_x: 0,
      ratio_y: 0,
      height: 30,
      size_x: 40,
      size_y: 40
    },
    trashbin: %{
      open?: false,
      size: 80,
      x: 0,
      y: 0
    },
    viewbox: %{x: 0, y: 0, height: 10, width: 10},
    zoom: %{value: 5, min: 1, max: 10, original_mobile: nil}
  ]

  @type t() :: %__MODULE__{
          name: String.t(),
          canvas: %{
            height: number(),
            width: number()
          },
          class: String.t(),
          menu: %{
            open?: boolean(),
            size: number(),
            x: number(),
            y: number()
          },
          screen: %{
            height: number(),
            width: number()
          },
          scroll: %{
            x: number(),
            y: number(),
            ratio_x: number(),
            ratio_y: number(),
            height: number(),
            size_x: number(),
            size_y: number()
          },
          selected:
            nil
            | %{
                id: String.t(),
                pointer: %{x: number(), y: number()},
                offset: %{x: number(), y: number()},
                position: %{x: number(), y: number()}
              },
          viewbox: %{
            x: number(),
            y: number(),
            height: number(),
            width: number()
          },
          trashbin: %{
            open?: boolean(),
            x: number(),
            y: number(),
            size: number()
          },
          zoom: %{
            value: number(),
            max: number(),
            min: number(),
            original_mobile: nil | number()
          }
        }

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

  @spec get_svg_meta(Socket.t()) :: t()
  def get_svg_meta(%Socket{assigns: %{@meta_key => %__MODULE__{} = svg_meta}}), do: svg_meta

  def on_mount(name, _params, _session, %Socket{} = socket) do
    canvas_name = Atom.to_string(name)

    %Socket{private: private} =
      socket =
      socket
      |> assign(@meta_key, %__MODULE__{name: canvas_name})
      |> assign(@components_key, [])
      |> assign(@menu_items_key, [])
      |> attach_hook(
        __MODULE__,
        :handle_event,
        Function.capture(__MODULE__, :handle_event, 3)
      )

    socket = %Socket{
      socket
      | private:
          Map.update(
            private,
            :temporary_assigns,
            %{@components_key => []},
            &Map.put(&1, @components_key, [])
          )
    }

    {:cont, socket}
  end

  def handle_event("create", _, %Socket{} = socket) do
    %__MODULE__{selected: selected, viewbox: viewbox, zoom: %{value: zoom}} = get_svg_meta(socket)

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
        |> update_svg_meta_response(&on_create/1)
    end
  end

  def handle_event(
        "dragend",
        %{"pointer" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) do
    %__MODULE__{trashbin: trashbin} = get_svg_meta(socket)

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

    update_svg_meta_response(socket, &on_dragend/1)
  end

  def handle_event("move", %{"pointer" => %{"x" => x, "y" => y}}, %Socket{} = socket)
      when is_number(x) and is_number(y) do
    socket = update_svg_meta(socket, &on_drag(&1, %{x: x, y: y}))
    new_position = compute_element_position(socket, x, y)

    id = extract_component_id(socket)
    {:halt, socket.view.handle_move(socket, %{id: id, position: new_position})}
  end

  def handle_event("move-background", %{"pointer" => %{"x" => x, "y" => y}}, %Socket{} = socket)
      when is_number(x) and is_number(y) do
    %__MODULE__{
      selected: %{position: %{x: original_x, y: original_y}}
    } = get_svg_meta(socket)

    %{x: new_x, y: new_y} = compute_element_position(socket, x, y)
    delta = %{x: 2 * original_x - new_x, y: 2 * original_y - new_y}
    update_svg_meta_response(socket, &set_viewbox_position(&1, delta))
  end

  def handle_event("toggle-menu-" <> _name, _, %Socket{} = socket) do
    update_svg_meta_response(socket, &on_toggle_menu(&1))
  end

  def handle_event("resize", %{"height" => height, "width" => width}, %Socket{} = socket)
      when is_number(height) and is_number(width) do
    update_svg_meta_response(socket, &on_resize(&1, height, width))
  end

  def handle_event("scroll-body-x", %{"pointer" => %{"x" => x}}, %Socket{} = socket)
      when is_number(x) do
    update_svg_meta_response(socket, &on_body_scroll_x(&1, x))
  end

  def handle_event("scroll-body-y", %{"pointer" => %{"y" => y}}, %Socket{} = socket)
      when is_number(y) do
    update_svg_meta_response(socket, &on_body_scroll_y(&1, y))
  end

  def handle_event("select", event, %Socket{} = socket) do
    socket = update_svg_meta(socket, &on_select(&1, event))
    %__MODULE__{selected: selected} = get_svg_meta(socket)

    socket =
      case component_type(selected.id) do
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
    update_svg_meta_response(socket, &on_zoom_desktop(&1, delta, x, y))
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
      &on_zoom_mobile(&1, original_position, original_touches, current_touches)
    )
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:cont, socket}
  end

  @spec push_to_foreground(Socket.t(), String.t()) :: Socket.t()
  def push_to_foreground(%Socket{} = socket, id) do
    push_event(socket, "move-to-foreground", %{
      id: generate_component_id(socket, id),
      parent: "#{get_svg_meta(socket).name}-body"
    })
  end

  @spec render_components(Socket.t(), list()) :: Socket.t()
  def render_components(%Socket{} = socket, components) do
    assign(socket, @components_key, components)
  end

  @spec render_menu_items(Socket.t(), list()) :: Socket.t()
  def render_menu_items(%Socket{} = socket, menu_items) do
    assign(socket, @menu_items_key, menu_items)
  end

  @spec select_item(Socket.t(), String.t()) :: Socket.t()
  def select_item(%Socket{} = socket, id) do
    push_event(socket, "select-item", %{
      id: generate_component_id(socket, id)
    })
  end

  defp on_body_scroll_x(
         %__MODULE__{scroll: scroll, selected: selected, viewbox: viewbox} = data,
         x
       ) do
    set_viewbox_position(data, %{x: (x - selected.offset.x) * scroll.ratio_x, y: viewbox.y})
  end

  defp on_body_scroll_y(
         %__MODULE__{scroll: scroll, selected: selected, viewbox: viewbox} = data,
         y
       ) do
    set_viewbox_position(data, %{x: viewbox.x, y: (y - selected.offset.y) * scroll.ratio_y})
  end

  defp on_create(%__MODULE__{} = data) do
    data
    |> Map.put(:selected, nil)
    |> Map.update!(:menu, &%{&1 | open?: false})
  end

  defp on_drag(%__MODULE__{trashbin: trashbin} = data, %{x: x, y: y} = _pointer_position) do
    pointer_over_trashbin_x = x > trashbin.x && x < trashbin.x + trashbin.size
    pointer_over_trashbin_y = y > trashbin.y && y < trashbin.y + trashbin.size
    pointer_over_trashbin = pointer_over_trashbin_x && pointer_over_trashbin_y
    Map.update!(data, :trashbin, &%{&1 | open?: pointer_over_trashbin})
  end

  defp on_dragend(%__MODULE__{} = data) do
    data
    |> Map.put(:selected, nil)
    |> Map.update!(:zoom, &%{&1 | original_mobile: nil})
    |> Map.update!(:trashbin, &%{&1 | open?: false})
  end

  defp on_resize(%__MODULE__{zoom: zoom} = data, height, width) do
    %__MODULE__{
      data
      | class: "",
        screen: %{height: height, width: width}
    }
    |> Map.update!(
      :canvas,
      &%{&1 | width: max(&1.width, width / zoom.min), height: max(&1.height, height / zoom.min)}
    )
    |> refresh_zoom()
    |> refresh_trashbin_position()
    |> refresh_menu()
  end

  defp on_select(%__MODULE__{} = data, %{
         "id" => id,
         "pointer" => %{"x" => pointer_x, "y" => pointer_y},
         "offset" => %{"x" => offset_x, "y" => offset_y},
         "position" => %{"x" => x, "y" => y}
       })
       when is_binary(id) and
              is_number(x) and
              is_number(y) and
              is_number(offset_x) and
              is_number(offset_y) and
              is_number(pointer_x) and
              is_number(pointer_y) do
    %__MODULE__{
      data
      | selected: %{
          id: id,
          pointer: %{x: pointer_x, y: pointer_y},
          offset: %{x: offset_x, y: offset_y},
          position: %{x: x, y: y}
        }
    }
  end

  defp on_toggle_menu(%__MODULE__{} = data) do
    Map.update!(data, :menu, &%{&1 | open?: !&1.open?})
  end

  defp on_zoom_desktop(%__MODULE__{viewbox: old_viewbox, zoom: old_zoom} = data, delta, x, y) do
    data =
      %__MODULE__{zoom: new_zoom} =
      data
      |> Map.update!(:zoom, &%{&1 | value: &1.value + delta})
      |> refresh_zoom()

    set_viewbox_position(data, %{
      x: old_viewbox.x + x / old_zoom.value - x / new_zoom.value,
      y: old_viewbox.y + y / old_zoom.value - y / new_zoom.value
    })
  end

  defp on_zoom_mobile(
         %__MODULE__{zoom: %{original_mobile: nil}} = data,
         original_position,
         original_touches,
         current_touches
       ) do
    data
    |> Map.update!(:zoom, &%{&1 | original_mobile: &1.value})
    |> on_zoom_mobile(original_position, original_touches, current_touches)
  end

  defp on_zoom_mobile(
         %__MODULE__{zoom: %{original_mobile: old_zoom}} = data,
         original_position,
         original_touches,
         current_touches
       ) do
    computed_zoom =
      compute_distance(current_touches) * old_zoom / compute_distance(original_touches)

    data =
      %__MODULE__{zoom: %{value: new_zoom}} =
      data
      |> Map.update!(:zoom, &%{&1 | value: computed_zoom})
      |> refresh_zoom()

    original_center = compute_center(original_touches)
    current_center = compute_center(current_touches)

    x = original_center.x / old_zoom - current_center.x / new_zoom
    y = original_center.y / old_zoom - current_center.y / new_zoom

    set_viewbox_position(data, %{
      x: original_position.x + x,
      y: original_position.y + y
    })
  end

  defp component_type("canvas-background-" <> _), do: :background

  defp component_type("component-" <> _), do: :component

  defp component_type("menu-item-" <> _), do: :menu_item

  defp component_type("scroll-body-x-" <> _), do: :scroll_body_x

  defp component_type("scroll-body-y-" <> _), do: :scroll_body_y

  defp component_type(%Socket{} = socket) do
    %__MODULE__{selected: selected} = get_svg_meta(socket)

    case selected do
      %{id: id} -> component_type(id)
      _ -> :unknown
    end
  end

  defp compute_center([%{x: x1, y: y1}, %{x: x2, y: y2}]) do
    %{x: (x1 + x2) / 2, y: (y1 + y2) / 2}
  end

  defp compute_distance([%{x: x1, y: y1}, %{x: x2, y: y2}]) do
    result = :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))

    case result do
      0.0 -> 1
      _ -> result
    end
  end

  defp compute_element_position(%Socket{} = socket, x, y) do
    %__MODULE__{
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
    %__MODULE__{selected: %{id: id}, name: name} = get_svg_meta(socket)
    prefix = "component-#{name}-"
    String.replace(id, prefix, "")
  end

  defp extract_menu_item_type(%Socket{} = socket) do
    %__MODULE__{selected: %{id: id}, name: name} = get_svg_meta(socket)
    prefix = "menu-item-#{name}-"
    String.replace(id, prefix, "")
  end

  defp refresh_menu(%__MODULE__{screen: screen, scroll: scroll} = data) do
    Map.update!(
      data,
      :menu,
      &%{
        &1
        | y: screen.height - scroll.height - &1.size,
          open?: false
      }
    )
  end

  defp refresh_trashbin_position(%__MODULE__{screen: screen, scroll: scroll} = data) do
    Map.update!(
      data,
      :trashbin,
      &%{
        &1
        | x: screen.width - scroll.height - &1.size,
          y: screen.height - scroll.height - &1.size
      }
    )
  end

  defp refresh_zoom(%__MODULE__{zoom: zoom, screen: screen} = data) do
    zoom = %{zoom | value: min(zoom.max, max(zoom.value, zoom.min))}

    data
    |> Map.put(:zoom, zoom)
    |> Map.update!(
      :viewbox,
      &%{
        &1
        | height: screen.height / zoom.value,
          width: screen.width / zoom.value
      }
    )
    |> refresh_scrollbars()
  end

  defp refresh_scrollbars(
         %__MODULE__{viewbox: viewbox, canvas: canvas, screen: screen, scroll: scroll} = data
       ) do
    computed_scroll_size_x = (screen.width - scroll.height) * (viewbox.width / canvas.width)
    scroll_size_x = max(computed_scroll_size_x, screen.width / 3)

    computed_scroll_size_y = (screen.height - scroll.height) * (viewbox.height / canvas.height)
    scroll_size_y = max(computed_scroll_size_y, screen.height / 3)

    scroll_ratio_x =
      if canvas.width == viewbox.width do
        1
      else
        (canvas.width - viewbox.width) / (screen.width - scroll_size_x - scroll.height)
      end

    scroll_ratio_y =
      if canvas.height == viewbox.height do
        1
      else
        (canvas.height - viewbox.height) / (screen.height - scroll_size_y - scroll.height)
      end

    %__MODULE__{
      data
      | scroll: %{
          scroll
          | size_x: scroll_size_x,
            size_y: scroll_size_y,
            ratio_x: scroll_ratio_x,
            ratio_y: scroll_ratio_y
        }
    }
  end

  defp set_viewbox_position(
         %__MODULE__{canvas: canvas, viewbox: viewbox, scroll: scroll} = data,
         %{x: x, y: y}
       ) do
    viewbox_x = max(0, min(x, canvas.width - viewbox.width))
    viewbox_y = max(0, min(y, canvas.height - viewbox.height))

    %__MODULE__{
      data
      | viewbox: %{viewbox | x: viewbox_x, y: viewbox_y},
        scroll: %{scroll | x: viewbox_x / scroll.ratio_x, y: viewbox_y / scroll.ratio_y}
    }
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
