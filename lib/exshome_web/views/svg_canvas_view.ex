defmodule ExshomeWeb.SvgCanvasView do
  @moduledoc """
  View for rendering svg canvas.
  """

  use ExshomeWeb, :view

  def render_svg_canvas(assigns) do
    render("index.html", assigns)
  end
end
