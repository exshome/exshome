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
      <%= for {connector_id, connector} <- @component.item.connectors, connection = @component.item.connections[connector_id] do %>
        <rect
          class={"opacity-50 #{if connection.type == :hover, do: 'fill-red-300 dark:fill-red-400', else: 'fill-gray-200 dark:fill-gray-400'}"}
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
