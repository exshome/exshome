defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖️"

  use ExshomeWeb.Live.SvgCanvas

  @impl LiveView
  def mount(_params, _session, socket) do
    components = for x <- 1..5, do: generate_component("rect-#{x}")

    {:ok, SvgCanvas.render_components(socket, components)}
  end

  @impl SvgCanvas
  def handle_delete(%Socket{} = socket, id) do
    component =
      id
      |> generate_component()
      |> Map.update!(:class, &"#{&1} hidden")

    SvgCanvas.render_components(socket, [component])
  end

  @impl SvgCanvas
  def handle_move(%Socket{} = socket, id, %{x: x, y: y}) do
    %SvgCanvas{canvas: canvas} = SvgCanvas.get_svg_meta(socket)
    component = generate_component(id)

    component = %{
      component
      | x: fit_in_box(x, canvas.width - component.width),
        y: fit_in_box(y, canvas.height - component.height)
    }

    SvgCanvas.render_components(socket, [component])
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
