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
        d={@component.item.svg_path}
      />
    </svg>
    """
  end
end
