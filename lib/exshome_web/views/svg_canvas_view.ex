defmodule ExshomeWeb.SvgCanvasView do
  @moduledoc """
  View for rendering svg canvas.
  """

  use ExshomeWeb, :view
  alias ExshomeWeb.Live.SvgCanvas

  attr :components, :list, required: true, doc: "components to render"
  attr :menu_items, :list, required: true, doc: "canvas menu items"
  attr :meta, SvgCanvas, required: true, doc: "canvas metadata"

  def render_svg_canvas(assigns) do
    render("index.html", assigns)
  end

  attr :id, :string, doc: "trashbin id"
  attr :trashbin, :any, doc: "map with render settings for trashbin"
  defp render_trashbin(assigns), do: render("trashbin.html", assigns)

  attr :menu, :any, doc: "map with render settings for menu"
  attr :menu_items, :list, doc: "menu items"
  attr :name, :string, doc: "svg canvas name"
  defp render_menu(assigns), do: render("menu.html", assigns)

  defp render_component(%{component: %module{} = component, context: context} = assigns) do
    attrs =
      component
      |> module.id()
      |> drag_attrs(context)

    assigns
    |> assign(:drag_attrs, attrs)
    |> module.render()
  end

  @spec drag_attrs(String.t(), any()) :: Keyword.t()
  def drag_attrs(id, %{name: name, drag: drag} = attrs) when is_binary(id) do
    role = attrs[:role] || "component"

    [
      {:id, "#{role}-#{name}-#{id}"},
      {:"data-drag", drag}
    ]
  end
end
