defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖️"

  use ExshomeWeb.Live.Hooks.SvgCanvas

  @impl LiveView
  def mount(_params, _session, socket) do
    components = for x <- 1..5, do: generate_component("rect-#{x}")

    socket = assign(socket, components: components)

    {:ok, socket, temporary_assigns: [components: []]}
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, id, %{x: x, y: y}) do
    %SvgCanvas{canvas: canvas} = get_svg_meta(socket)
    component = generate_component(id)

    assign(socket, :components, [
      %{
        component
        | x: fit_in_box(x, canvas.width - component.width),
          y: fit_in_box(y, canvas.height - component.height)
      }
    ])
  end

  defp generate_component(id) do
    %{
      id: id,
      x: 0,
      y: 0,
      height: 25,
      width: 25,
      class: "fill-green-200"
    }
  end

  defp fit_in_box(coordinate, size) do
    coordinate
    |> min(size)
    |> max(0)
  end
end
