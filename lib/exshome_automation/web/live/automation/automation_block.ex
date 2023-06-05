defmodule ExshomeAutomation.Web.Live.Automation.AutomationBlock do
  @moduledoc """
  Generic automation block.
  """
  use ExshomeWeb.Live.SvgCanvas.CanvasComponent

  defstruct [
    :id,
    :class,
    :height,
    :width,
    :x,
    :y
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          class: String.t(),
          height: number(),
          width: number(),
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
        d="
          M 3 0
          C 2.44772 0 2 0.447715 2 1
          L 2 2.25
          L 1 2
          C 0.44772 2 2.06629e-06 2.44772 0 3
          C 0 3.55228 0.447716 4 1 4
          L 2 3.75
          L 2 12
          L 2 27
          C 2 27.5523 2.44772 28 3 28
          L 4 28
          L 6 29
          L 8 28
          L 20 28
          C 20.5523 28 21 27.5523 21 27
          C 21 26.4477 20.5523 26 20 26
          L 9 26
          C 8.44772 26 7.99998 25.5523 8 25
          L 8 21C8 20.4477 8.44772 20 9 20
          L 10 20
          L 12 21
          L 14 20
          L 20 20
          C 20.5523 20 21 19.5523 21 19
          C 21 18.4477 20.5523 18 20 18
          L 9 18
          C 8.44772 18 7.99998 17.5523 8 17
          L 8 13C8 12.4477 8.44772 12 9 12
          L 10 12
          L 12 13
          L 14 12
          L 21 12
          C 21.5523 12 22 11.5523 22 11
          L 22 9.75
          L 21 10
          C 20.4477 10 20 9.55228 20 9
          C 20 8.44772 20.4477 8 21 8
          L 22 8.25
          L 22 3.75
          L 21 4
          C 20.7239 4 20.4622 3.89972 20.2812 3.71875
          C 20.1003 3.53779 20 3.27614 20 3
          C 20 2.72386 20.1003 2.46221 20.2812 2.28125
          C 20.4622 2.10029 20.7239 2 21 2
          L 22 2.25
          L 22 1
          C 22 0.447715 21.5523 0 21 0
          L 8 0
          L 6 1
          L 4 0
          L 3 0
          Z
        "
      />
    </svg>
    """
  end
end
