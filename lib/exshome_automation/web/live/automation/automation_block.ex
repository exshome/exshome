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
    <rect
      x={@component.x}
      y={@component.y}
      width={@component.width}
      height={@component.height}
      class={"draggable cursor-move #{@component.class}"}
      {@drag_attrs}
    />
    """
  end
end
