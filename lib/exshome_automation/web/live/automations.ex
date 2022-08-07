defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖️"

  @name "automation"

  @impl LiveView
  def mount(_params, _session, socket) do
    components = for x <- 1..5, do: generate_component("rect-#{x}")

    socket =
      assign(
        socket,
        canvas: %{height: 500, width: 500},
        class: "opacity-0",
        components: components,
        name: @name,
        screen: %{width: 100, height: 100},
        scroll: %{x: 0, y: 0, ratio_x: 0, ratio_y: 0, height: 30, width_x: 40, width_y: 40},
        selected: nil,
        viewbox: %{x: 0, y: 0, height: 10, width: 10},
        zoom: 7
      )

    {:ok, socket, temporary_assigns: [components: []]}
  end

  @impl LiveView
  def handle_event("resize", %{"width" => width, "height" => height}, %Socket{} = socket) do
    socket =
      socket
      |> assign(:screen, %{height: height, width: width})
      |> handle_zoom()
      |> update_scrollbars()

    {:noreply, socket}
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
          | x: fit_in_box(x, socket.assigns.canvas.width),
            y: fit_in_box(y, socket.assigns.canvas.height)
        }
      ])

    {:noreply, socket}
  end

  def handle_event("scroll", data, %Socket{} = socket) do
    {:noreply, handle_scroll(data["id"], data["x"], data["y"], socket)}
  end

  def handle_event("dragend", _, %Socket{} = socket) do
    {:noreply, assign(socket, selected: nil)}
  end

  def handle_event("move-background", %{"x" => _x, "y" => _y}, %Socket{} = socket) do
    {:noreply, socket}
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

  defp handle_scroll(@name <> "-scroll-x", x, _y, %Socket{} = socket) do
    socket
    |> update(:scroll, &%{&1 | x: x})
    |> normalize_scroll()
  end

  defp handle_scroll(@name <> "-scroll-y", _x, y, %Socket{} = socket) do
    socket
    |> update(:scroll, &%{&1 | y: y})
    |> normalize_scroll()
  end

  defp normalize_scroll(%Socket{} = socket) do
    %{screen: screen, scroll: scroll} = socket.assigns

    new_x =
      scroll.x
      |> max(0)
      |> min(screen.width - scroll.height - scroll.width_x)

    new_y =
      scroll.y
      |> max(0)
      |> min(screen.height - scroll.height - scroll.width_y)

    update(socket, :scroll, &%{&1 | x: new_x, y: new_y})
  end

  defp handle_zoom(%Socket{} = socket) do
    %{zoom: zoom, screen: screen} = socket.assigns

    socket
    |> assign(class: "")
    |> update(
      :viewbox,
      fn view ->
        %{view | height: screen.height / zoom, width: screen.width / zoom}
      end
    )
  end

  defp update_scrollbars(%Socket{} = socket) do
    %{viewbox: view, canvas: canvas, screen: screen, scroll: scroll} = socket.assigns

    scroll_width_x = (screen.width - scroll.height) * (view.width / canvas.width)
    scroll_width_x = max(scroll_width_x, screen.width / 3)

    scroll_width_y = (screen.height - scroll.height) * (view.height / canvas.height)
    scroll_width_y = max(scroll_width_y, screen.height / 3)

    scroll_ratio_x = (canvas.width - view.width) / (screen.width - scroll_width_x - scroll.height)

    scroll_ratio_y =
      (canvas.height - view.height) / (screen.height - scroll_width_y - scroll.height)

    update(
      socket,
      :scroll,
      &%{
        &1
        | width_x: scroll_width_x,
          ratio_x: scroll_ratio_x,
          width_y: scroll_width_y,
          ratio_y: scroll_ratio_y
      }
    )
  end
end
