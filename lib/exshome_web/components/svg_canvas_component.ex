defmodule ExshomeWeb.SvgCanvasComponent do
  @moduledoc """
  Component for rendering svg canvas.
  """

  use ExshomeWeb, :html
  alias ExshomeWeb.Live.SvgCanvas.CanvasSettings
  alias ExshomeWeb.Live.SvgCanvas.ComponentMeta

  embed_templates("svg_canvas/*")

  attr :meta, CanvasSettings, required: true, doc: "canvas metadata"
  slot :header, doc: "canvas header"
  slot :menu, required: true, doc: "menu items"
  slot :body, required: true, doc: "canvas content"

  def render_svg_canvas(assigns), do: index(assigns)

  attr :width, :float, required: true, doc: "item width"
  attr :height, :float, required: true, doc: "item height"
  attr :type, :string, required: true, doc: "component type"
  attr :name, :string, required: true, doc: "canvas name"

  def menu_item(assigns) do
    ~H"""
    <svg
      class="w-full p-5"
      viewbox={"0 0 #{@width} #{@height}"}
      data-drag="canvas-create"
      data-component={"menu-item-#{@name}-#{@type}"}
      x="1"
      y="1"
      width={@width}
      height={@height}
    >
      <%= render_slot(@inner_block) %>
    </svg>
    """
  end

  attr :meta, ComponentMeta, required: true, doc: "component meta"
  slot :inner_block, required: true, doc: "component contents"

  def component(assigns) do
    assigns = assign(assigns, :drag_attrs, ComponentMeta.to_component_args(assigns.meta))

    ~H"""
    <%= render_slot(@inner_block, @drag_attrs) %>
    """
  end

  attr :id, :string, required: true, doc: "Dom ID of the component"
  attr :component, :map, required: true, doc: "Component to render"
  attr :context, :map, required: true, doc: "Component context"

  def render_component(%{component: %module{} = component, context: context} = assigns) do
    component_id = module.id(component)

    attrs =
      context
      |> Map.put(:component_id, component_id)
      |> drag_attrs()

    assigns
    |> assign(:drag_attrs, attrs)
    |> module.render()
  end

  @spec drag_attrs(map()) :: Keyword.t()
  defp drag_attrs(%{name: name, drag: drag, component_id: component_id} = attrs) do
    role = attrs[:role] || "component"

    [
      {:"data-drag", drag},
      {:"data-component", "#{role}-#{name}-#{component_id}"}
    ]
  end
end
