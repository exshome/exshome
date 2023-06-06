defmodule ExshomeAutomation.Web.Live.Automation.AutomationBlock do
  @moduledoc """
  Generic automation block.
  """
  use ExshomeWeb.Live.SvgCanvas.CanvasComponent

  alias ExshomeAutomation.Services.Workflow.EditorItem

  defstruct [
    :id,
    :class,
    :item,
    :width,
    :height,
    :x,
    :y
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          class: String.t(),
          item: EditorItem.t(),
          x: number(),
          y: number()
        }

  @impl CanvasComponent
  def id(%__MODULE__{id: id}), do: id

  @impl CanvasComponent
  def render(assigns) do
    ~H"""
    <svg id={@id} x={@component.x} y={@component.y}>
      <path
        class={"draggable cursor-move #{@component.class}"}
        x={@component.x}
        y={@component.y}
        width={@component.width}
        height={@component.height}
        {@drag_attrs}
        d={generate_path(@component.item)}
      />
    </svg>
    """
  end

  defp generate_path(%EditorItem{type: "rect"}) do
    """
    M 5.5 1
    C 4.67157 1 4 1.67157 4 2.5
    L 4 4.5625L3 4.09375C3 4.09375 2.69669 4 2.5 4
    C 1.67157 4 1 4.67157 1 5.5
    C 1 6.32843 1.67157 7 2.5 7
    C 2.69669 7 3 6.90625 3 6.90625
    L 4 6.46875L4 19
    L 4 41.5
    C 4 42.3284 4.67157 43 5.5 43
    L 7 43L10 45
    L 13 43L30.5 43
    C 31.3284 43 32 42.3284 32 41.5
    C 32 40.6716 31.3284 40 30.5 40
    L 14.5 40
    C 13.6716 40 13 39.3284 13 38.5
    L 13 32.5
    C 13 31.6716 13.6716 30.9999 14.5 31
    L 16 31
    L 19 33
    L 22 31
    L 30.5 31
    C 31.3284 31 32 30.3284 32 29.5
    C 32 28.6716 31.3284 28 30.5 28
    L 14.5 28
    C 14.0858 28 13.7089 27.8339 13.4375 27.5625
    C 13.1661 27.2911 13 26.9142 13 26.5
    L 13 20.5
    C 13 19.6716 13.6716 19 14.5 19
    L 16 19L19 21
    L 22 19
    L 32.5 19
    C 33.3284 19 34 18.3284 34 17.5
    L 34 15.4688
    L 33 15.9062
    C 33 15.9063 32.6967 16 32.5 16
    C 31.6716 16 31 15.3284 31 14.5
    C 31 13.6716 31.6716 13 32.5 13
    C 32.6967 13 33 13.0938 33 13.0938
    L 34 13.5625
    L 34 6.46875
    L 33 6.90625
    C 33 6.90625 32.6967 7.00002 32.5 7
    C 31.6716 7 31 6.32843 31 5.5
    C 31 4.67157 31.6716 4 32.5 4
    C 32.6967 4 33 4.09375 33 4.09375
    L 34 4.5625
    L 34 2.5
    C 34 1.67157 33.3284 1 32.5 1
    L 13 1
    L 10 3
    L 7 1
    L 5.5 1
    Z
    """
  end

  defp generate_path(%EditorItem{}) do
    [
      {:move, 4, 2},
      {:horizontal, 2},
      {:action_connector, :top, 6},
      {:horizontal, 10},
      {:round_corner, :top_right},
      {:vertical, 1},
      :child_connector,
      {:vertical, 2},
      {:round_corner, :bottom_right},
      {:horizontal, -10},
      {:action_connector, :bottom, 6},
      {:horizontal, -2},
      {:round_corner, :bottom_left},
      {:vertical, -2},
      :parent_connector,
      {:vertical, -1},
      {:round_corner, :top_left},
      :close_path
    ]
    |> Enum.map_join(" ", &svg_to_string/1)
  end

  defp svg_to_string({:move, x, y}), do: "m #{x} #{y}"
  defp svg_to_string({:horizontal, x}), do: "h #{x}"
  defp svg_to_string({:vertical, y}), do: "v #{y}"
  defp svg_to_string({:round_corner, :top_right}), do: "q 1 0 1 1"
  defp svg_to_string({:round_corner, :bottom_right}), do: "q 0 1 -1 1"
  defp svg_to_string({:round_corner, :bottom_left}), do: "q -1 0 -1 -1"
  defp svg_to_string({:round_corner, :top_left}), do: "q 0 -1 1 -1"
  defp svg_to_string(:close_path), do: "z"
  defp svg_to_string({:action_connector, :top, width}), do: "l #{width / 2} 2 l #{width / 2} -2"

  defp svg_to_string({:action_connector, :bottom, width}),
    do: "l -#{width / 2} 2 l -#{width / 2} -2"

  defp svg_to_string(:child_connector) do
    """
    v 0.2
    l -1 -0.2
    a 1 1 0 0 0 0 2
    l 1 -0.2
    v 0.2
    """
  end

  defp svg_to_string(:parent_connector) do
    """
    v -0.2
    l -1 0.2
    a 1 1 0 0 1 0 -2
    l 1 0.2
    v -0.2
    """
  end
end
