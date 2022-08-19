defmodule ExshomeAutomation.Web.Live.Automation.Component do
  @moduledoc """
  Generic automation component.
  """
  use ExshomeWeb.Live.SvgCanvas.CanvasComponent

  defstruct [:canvas_data, :class]

  @type t :: %__MODULE__{
          canvas_data: CanvasComponent.t(),
          class: String.t()
        }

  @impl CanvasComponent
  def to_component(%__MODULE__{canvas_data: canvas_data}), do: canvas_data

  @impl CanvasComponent
  def render(assigns) do
    ~H"""
    <rect
      id={@component.canvas_data.id}
      x={@component.canvas_data.x}
      y={@component.canvas_data.y}
      width={@component.canvas_data.width}
      height={@component.canvas_data.height}
      class={"draggable cursor-move #{@component.class}"}
      data-drag="move"
    />
    """
  end
end
