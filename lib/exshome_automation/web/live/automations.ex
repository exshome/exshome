defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖️"

  @impl LiveView
  def mount(_params, _session, socket) do
    components = for x <- 1..5, do: generate_component("rect-#{x}")

    socket =
      assign(
        socket,
        components: components,
        selected: nil,
        viewbox: %{x: 0, y: 0, height: 500, width: 500},
        screen: %{height: 500, width: 500},
        zoom: 7
      )

    {:ok, socket, temporary_assigns: [components: []]}
  end

  @impl LiveView
  def handle_event("resize", %{"width" => width, "height" => height}, %Socket{} = socket) do
    {:noreply, handle_zoom(width, height, socket)}
  end

  def handle_event("select", _, %Socket{} = socket) do
    {:noreply, socket}
  end

  def handle_event("move", %{"x" => x, "y" => y, "id" => "component-" <> id}, %Socket{} = socket) do
    component = generate_component(id)

    socket =
      assign(socket, :components, [
        %{
          component
          | x: fit_in_box(x, socket.assigns.screen.width),
            y: fit_in_box(y, socket.assigns.screen.height)
        }
      ])

    {:noreply, socket}
  end

  def handle_event("scroll", data, %Socket{} = socket) do
    %{viewbox: viewbox, screen: screen} = socket.assigns

    {:noreply,
     handle_scroll(
       data["id"],
       (data["x"] - viewbox.x) * screen.width / viewbox.width,
       (data["y"] - viewbox.y) * screen.height / viewbox.height,
       socket
     )}
  end

  def handle_event("dragend", _, %Socket{} = socket) do
    {:noreply, assign(socket, selected: nil)}
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

  defp handle_scroll("scroll-x", x, _y, %Socket{} = socket) do
    %{viewbox: view, screen: screen} = socket.assigns
    view = %{view | x: min(max(x, 0), screen.width - view.width)}
    assign(socket, :viewbox, view)
  end

  defp handle_scroll("scroll-y", _x, y, %Socket{} = socket) do
    %{viewbox: view, screen: screen} = socket.assigns
    view = %{view | y: min(max(y, 0), screen.height - view.height)}
    assign(socket, :viewbox, view)
  end

  defp handle_zoom(width, height, %Socket{} = socket) do
    zoom = socket.assigns.zoom

    update(
      socket,
      :viewbox,
      fn view ->
        %{view | height: height / zoom, width: width / zoom}
      end
    )
  end
end
