defmodule ExshomeWeb.Live.Hooks.SvgCanvas do
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
    viewbox: %{x: 0, y: 0, height: 10, width: 10},
    zoom: %{value: 5, min_value: 1, max_value: 10}
  ]

  @type t() :: %__MODULE__{
          name: String.t(),
          canvas: %{
            height: number(),
            width: number()
          },
          class: String.t(),
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
                original_x: number(),
                original_y: number()
              },
          viewbox: %{
            x: number(),
            y: number(),
            height: number(),
            width: number()
          },
          zoom: %{
            value: number(),
            max_value: number(),
            min_value: number()
          }
        }

  @callback handle_move(Socket.t(), id :: String.t(), %{x: number(), y: number()}) :: Socket.t()

  @assigns_key :__svg_meta__

  @spec get_svg_meta(Socket.t()) :: t()
  def get_svg_meta(%Socket{assigns: %{@assigns_key => %__MODULE__{} = svg_meta}}), do: svg_meta

  def on_mount(name, _params, _session, %Socket{} = socket) do
    canvas_name = Atom.to_string(name)

    socket =
      socket
      |> assign(@assigns_key, %__MODULE__{name: canvas_name})
      |> attach_hook(
        __MODULE__,
        :handle_event,
        Function.capture(__MODULE__, :handle_event, 3)
      )

    {:cont, socket}
  end

  def handle_event("dragend", _, %Socket{} = socket) do
    update_svg_meta_response(socket, &on_dragend/1)
  end

  def handle_event("move", %{"x" => x, "y" => y, "id" => id}, %Socket{} = socket)
      when is_number(x) and is_number(y) and is_binary(id) do
    new_position = compute_element_position(socket, x, y)
    {:halt, socket.view.handle_move(socket, id, new_position)}
  end

  def handle_event("move-background", %{"x" => x, "y" => y}, %Socket{} = socket)
      when is_number(x) and is_number(y) do
    %__MODULE__{
      selected: %{original_x: original_x, original_y: original_y}
    } = get_svg_meta(socket)

    %{x: new_x, y: new_y} = compute_element_position(socket, x, y)
    delta = %{x: 2 * original_x - new_x, y: 2 * original_y - new_y}
    update_svg_meta_response(socket, &set_viewbox_position(&1, delta))
  end

  def handle_event("resize", %{"height" => height, "width" => width}, %Socket{} = socket)
      when is_number(height) and is_number(width) do
    update_svg_meta_response(socket, &on_resize(&1, height, width))
  end

  def handle_event("scroll-body-x", %{"x" => x}, %Socket{} = socket) when is_number(x) do
    update_svg_meta_response(socket, &on_body_scroll_x(&1, x))
  end

  def handle_event("scroll-body-y", %{"y" => y}, %Socket{} = socket) when is_number(y) do
    update_svg_meta_response(socket, &on_body_scroll_y(&1, y))
  end

  def handle_event(
        "select",
        %{"id" => id, "position" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      )
      when is_number(x) and is_number(y) and is_binary(id) do
    update_svg_meta_response(socket, &on_select(&1, id, x, y))
  end

  def handle_event(
        "zoom-desktop",
        %{"delta" => delta, "position" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      )
      when is_number(delta) and is_number(x) and is_number(y) do
    update_svg_meta_response(socket, &on_zoom_desktop(&1, delta, x, y))
  end

  def handle_event(_event, _params, %Socket{} = socket) do
    {:cont, socket}
  end

  defp on_body_scroll_x(%__MODULE__{scroll: %{ratio_x: ratio_x}, viewbox: viewbox} = data, x) do
    set_viewbox_position(data, %{x: x * ratio_x, y: viewbox.y})
  end

  defp on_body_scroll_y(%__MODULE__{scroll: %{ratio_y: ratio_y}, viewbox: viewbox} = data, y) do
    set_viewbox_position(data, %{x: viewbox.x, y: y * ratio_y})
  end

  defp on_dragend(%__MODULE__{} = data) do
    %__MODULE__{data | selected: nil}
  end

  defp on_resize(%__MODULE__{} = data, height, width) do
    %__MODULE__{
      data
      | class: "",
        screen: %{height: height, width: width}
    }
    |> refresh_zoom()
  end

  defp on_select(%__MODULE__{} = data, id, x, y) do
    %__MODULE__{
      data
      | selected: %{id: id, original_x: x, original_y: y}
    }
  end

  defp on_zoom_desktop(%__MODULE__{} = data, delta, _x, _y) do
    data
    |> Map.update!(:zoom, &%{&1 | value: &1.value + delta})
    |> refresh_zoom()
  end

  defp compute_element_position(%Socket{} = socket, x, y) do
    %__MODULE__{
      selected: %{original_x: original_x, original_y: original_y},
      zoom: %{value: zoom}
    } = socket.assigns[@assigns_key]

    new_x = original_x + (x - original_x) / zoom
    new_y = original_y + (y - original_y) / zoom

    %{x: new_x, y: new_y}
  end

  defp refresh_zoom(%__MODULE__{zoom: zoom, screen: screen} = data) do
    zoom = %{zoom | value: min(zoom.max_value, max(zoom.value, zoom.min_value))}

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
      (canvas.width - viewbox.width) / (screen.width - scroll_size_x - scroll.height)

    scroll_ratio_y =
      (canvas.height - viewbox.height) / (screen.height - scroll_size_y - scroll.height)

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

  defp update_svg_meta_response(%Socket{} = socket, fun) do
    {:halt, update(socket, @assigns_key, fun)}
  end

  defmacro __using__(_) do
    quote do
      alias ExshomeWeb.Live.Hooks.SvgCanvas
      on_mount(SvgCanvas)
      @behaviour SvgCanvas

      defdelegate get_svg_meta(socket), to: SvgCanvas
    end
  end
end
