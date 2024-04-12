defmodule ExshomeWeb.SvgCanvasComponent do
  @moduledoc """
  Component for rendering svg canvas.
  """

  use ExshomeWeb, :html
  alias ExshomeWeb.Live.SvgCanvas.CanvasSettings

  embed_templates("svg_canvas/*")

  attr :components, :list, required: true, doc: "components to render"
  attr :menu_items, :list, required: true, doc: "canvas menu items"
  attr :meta, CanvasSettings, required: true, doc: "canvas metadata"
  slot :header, doc: "canvas header"

  def render_svg_canvas(assigns) do
    index(assigns)
  end

  attr :id, :string, doc: "trashbin id"
  attr :trashbin, :any, doc: "map with render settings for trashbin"
  defp render_trashbin(assigns), do: trashbin(assigns)

  attr :open?, :boolean, doc: "shows if menu is open"
  attr :menu_items, :list, doc: "menu items"
  attr :name, :string, doc: "svg canvas name"
  defp render_menu(assigns), do: menu(assigns)

  attr :id, :string, required: true, doc: "Dom ID of the component"
  attr :component, :map, required: true, doc: "Component to render"
  attr :context, :map, required: true, doc: "Component context"

  defp render_component(%{component: %module{} = component, context: context} = assigns) do
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
