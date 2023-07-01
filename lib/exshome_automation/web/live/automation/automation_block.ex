defmodule ExshomeAutomation.Web.Live.Automation.AutomationBlock do
  @moduledoc """
  Generic automation block.
  """
  use ExshomeWeb.Live.SvgCanvas.CanvasComponent

  alias ExshomeAutomation.Services.Workflow.EditorItem

  defstruct [
    :id,
    :class,
    :item
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          class: String.t(),
          item: EditorItem.t()
        }

  @impl CanvasComponent
  def id(%__MODULE__{id: id}), do: id

  @impl CanvasComponent
  def render(assigns) do
    ~H"""
    <svg id={@id} x={@component.item.position.x} y={@component.item.position.y}>
      <%= for {connector_id, connector} <- @component.item.connectors do %>
        <rect
          class={"fill-red-300 dark:fill-red-400 #{if match?(%{type: :hover}, @component.item.connected_items[connector_id]), do: 'opacity-70', else: 'opacity-0'}"}
          x={connector.x}
          y={connector.y}
          width={connector.width}
          height={connector.height}
        />
      <% end %>
      <path
        class={"draggable cursor-move #{@component.class}"}
        x={@component.item.position.x}
        y={@component.item.position.y}
        width={@component.item.width}
        height={@component.item.height}
        {@drag_attrs}
        d={@component.item.svg_path}
      />
    </svg>
    """
  end
end
