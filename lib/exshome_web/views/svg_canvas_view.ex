defmodule ExshomeWeb.SvgCanvasView do
  @moduledoc """
  View for rendering svg canvas.
  """

  use ExshomeWeb, :view
  import Phoenix.LiveView

  def render_svg_canvas(assigns) do
    render("index.html", assigns)
  end

  def render_component(%{component: %module{} = component, context: context} = assigns) do
    attrs =
      component
      |> module.id()
      |> drag_attrs(context)

    assigns
    |> assign(:drag_attrs, attrs)
    |> module.render()
  end

  @spec drag_attrs(String.t(), any()) :: Keyword.t()
  def drag_attrs(id, %{name: name, drag: drag}) when is_binary(id) do
    [{:id, "component-#{name}-#{drag}-#{id}"}, {:"data-drag", drag}]
  end
end
