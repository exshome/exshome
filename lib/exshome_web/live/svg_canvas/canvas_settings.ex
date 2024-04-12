defmodule ExshomeWeb.Live.SvgCanvas.CanvasSettings do
  @moduledoc """
  Processes logic behind SVG canvas.
  """

  defstruct [
    :name,
    :selected,
    canvas: %{height: 500, width: 500},
    class: "h-px opacity-0",
    menu: %{
      open?: false
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
            open?: boolean()
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
                component: String.t(),
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

  def on_create(%__MODULE__{} = data) do
    data
    |> Map.put(:selected, nil)
    |> Map.update!(:menu, &%{&1 | open?: false})
  end

  def on_drag(%__MODULE__{trashbin: trashbin} = data, %{x: x, y: y} = _pointer_position) do
    pointer_over_trashbin_x = x > trashbin.x && x < trashbin.x + trashbin.size
    pointer_over_trashbin_y = y > trashbin.y && y < trashbin.y + trashbin.size
    pointer_over_trashbin = pointer_over_trashbin_x && pointer_over_trashbin_y
    Map.update!(data, :trashbin, &%{&1 | open?: pointer_over_trashbin})
  end

  def on_dragend(%__MODULE__{} = data) do
    data
    |> Map.put(:selected, nil)
    |> Map.update!(:zoom, &%{&1 | original_mobile: nil})
    |> Map.update!(:trashbin, &%{&1 | open?: false})
  end

  def on_menu_close(%__MODULE__{} = data) do
    Map.update!(data, :menu, &%{&1 | open?: false})
  end

  def on_menu_toggle(%__MODULE__{} = data) do
    Map.update!(data, :menu, &%{&1 | open?: !&1.open?})
  end

  def set_viewbox_position(
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

  def on_resize(%__MODULE__{zoom: zoom} = data, height, width) do
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

  def on_body_scroll_x(
        %__MODULE__{scroll: scroll, selected: selected, viewbox: viewbox} = data,
        x
      ) do
    set_viewbox_position(data, %{x: (x - selected.offset.x) * scroll.ratio_x, y: viewbox.y})
  end

  def on_body_scroll_y(
        %__MODULE__{scroll: scroll, selected: selected, viewbox: viewbox} = data,
        y
      ) do
    set_viewbox_position(data, %{x: viewbox.x, y: (y - selected.offset.y) * scroll.ratio_y})
  end

  def on_select(%__MODULE__{} = data, %{
        "component" => component,
        "pointer" => %{"x" => pointer_x, "y" => pointer_y},
        "offset" => %{"x" => offset_x, "y" => offset_y},
        "position" => %{"x" => x, "y" => y}
      })
      when is_binary(component) and
             is_number(x) and
             is_number(y) and
             is_number(offset_x) and
             is_number(offset_y) and
             is_number(pointer_x) and
             is_number(pointer_y) do
    %__MODULE__{
      data
      | selected: %{
          component: component,
          pointer: %{x: pointer_x, y: pointer_y},
          offset: %{x: offset_x, y: offset_y},
          position: %{x: x, y: y}
        }
    }
  end

  def on_zoom_desktop(%__MODULE__{viewbox: old_viewbox, zoom: old_zoom} = data, delta, x, y) do
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

  def on_zoom_mobile(
        %__MODULE__{zoom: %{original_mobile: nil}} = data,
        original_position,
        original_touches,
        current_touches
      ) do
    data
    |> Map.update!(:zoom, &%{&1 | original_mobile: &1.value})
    |> on_zoom_mobile(original_position, original_touches, current_touches)
  end

  def on_zoom_mobile(
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

  def update_zoom(%__MODULE__{} = data, update_fn) do
    data.zoom.value
    |> update_in(update_fn)
    |> refresh_zoom()
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

    {viewbox_x, scroll_ratio_x} =
      if canvas.width == viewbox.width do
        {0, 1}
      else
        new_ratio =
          (canvas.width - viewbox.width) / (screen.width - scroll_size_x - scroll.height)

        {viewbox.x, new_ratio}
      end

    {viewbox_y, scroll_ratio_y} =
      if canvas.height == viewbox.height do
        {0, 1}
      else
        new_ratio =
          (canvas.height - viewbox.height) / (screen.height - scroll_size_y - scroll.height)

        {viewbox.y, new_ratio}
      end

    %__MODULE__{
      data
      | scroll: %{
          scroll
          | size_x: scroll_size_x,
            size_y: scroll_size_y,
            ratio_x: scroll_ratio_x,
            ratio_y: scroll_ratio_y
        },
        viewbox: %{
          viewbox
          | x: viewbox_x,
            y: viewbox_y
        }
    }
  end

  defp refresh_menu(%__MODULE__{} = data) do
    Map.update!(data, :menu, &%{&1 | open?: false})
  end

  defp compute_center([%{x: x1, y: y1}, %{x: x2, y: y2}]) do
    %{x: (x1 + x2) / 2, y: (y1 + y2) / 2}
  end

  defp compute_distance([%{x: x1, y: y1}, %{x: x2, y: y2}]) do
    result = :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))

    case result do
      zero when zero in [0.0, -0.0] -> 1
      _ -> result
    end
  end
end
