defmodule ExshomeWeb.SvgCanvasView do
  @moduledoc """
  View for rendering svg canvas.
  """

  use ExshomeWeb, :view

  def render_svg_canvas(assigns) do
    render("index.html", assigns)
  end

  def render_component(%{component: %module{}} = assigns) do
    module.render(assigns)
  end
end
