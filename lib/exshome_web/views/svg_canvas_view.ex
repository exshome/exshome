defmodule ExshomeWeb.SvgCanvasView do
  @moduledoc """
  View for rendering svg canvas.
  """

  use ExshomeWeb, :view
  import Phoenix.LiveView

  def render_svg_canvas(assigns) do
    render("index.html", assigns)
  end

  defp render_trashbin(assigns), do: render("trashbin.html", assigns)

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
    relative_to = attrs[:relative_to] || :canvas

    [
      {:id, "#{role}-#{name}-#{id}"},
      {:"data-drag", drag},
      {:"data-relative-to", relative_to}
    ]
  end
end
