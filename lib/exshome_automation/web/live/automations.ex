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
        scroll: %{
          x: 0,
          y: 0,
          ratio_x: 0,
          ratio_y: 0,
          height: 30,
          width_x: 40,
          width_y: 40
        },
        selected: nil,
        viewbox: %{x: 0, y: 0, height: 10, width: 10},
        zoom: %{value: 5, min_value: 1, max_value: 10}
      )

    {:ok, socket, temporary_assigns: [components: []]}
  end

  @impl LiveView
  def handle_event("resize", %{"width" => width, "height" => height}, %Socket{} = socket) do
    socket =
      socket
      |> assign(:screen, %{height: height, width: width})
      |> handle_zoom()

    {:noreply, socket}
  end

  def handle_event(
        "select",
        %{"id" => id, "position" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      ) do
    socket = assign(socket, selected: %{id: id, original_x: x, original_y: y})

    {:noreply, socket}
  end

  def handle_event(
        "move",
        %{"x" => x, "y" => y, "id" => "#{@name}-component-" <> id},
        %Socket{} = socket
      ) do
    %{
      viewbox: viewbox,
      screen: screen,
      selected: %{original_x: original_x, original_y: original_y}
    } = socket.assigns

    new_x = original_x + (x - original_x) * viewbox.width / screen.width
    new_y = original_y + (y - original_y) * viewbox.height / screen.height

    component = generate_component(id)

    socket =
      assign(socket, :components, [
        %{
          component
          | x: fit_in_box(new_x, socket.assigns.canvas.width - component.width),
            y: fit_in_box(new_y, socket.assigns.canvas.height - component.height)
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

  def handle_event("move-background", %{"x" => x, "y" => y}, %Socket{} = socket) do
    %{screen: screen, viewbox: viewbox, selected: selected} = socket.assigns

    socket =
      socket
      |> update(
        :scroll,
        &%{
          &1
          | x: selected.original_x - x * viewbox.width / screen.width / &1.ratio_x,
            y: selected.original_y - y * viewbox.height / screen.height / &1.ratio_y
        }
      )
      |> normalize_scroll()

    {:noreply, socket}
  end

  def handle_event(
        "zoom-desktop",
        %{"delta" => delta, "position" => %{"x" => x, "y" => y}},
        %Socket{} = socket
      ) do
    %{viewbox: old_viewbox, screen: screen, scroll: old_scroll} = socket.assigns

    socket =
      socket
      |> update(
        :zoom,
        &%{&1 | value: min(&1.max_value, max(&1.min_value, &1.value + delta * 0.1))}
      )
      |> handle_zoom()

    %{viewbox: viewbox, scroll: scroll} = socket.assigns

    old_x = x * old_viewbox.width / screen.width / old_scroll.ratio_x
    new_x = x * viewbox.width / screen.width / scroll.ratio_x
    delta_x = new_x - old_x

    old_y = y * old_viewbox.height / screen.height / old_scroll.ratio_y
    new_y = y * viewbox.height / screen.height / scroll.ratio_y
    delta_y = new_y - old_y

    socket =
      socket
      |> update(:scroll, &%{&1 | x: &1.x - delta_x, y: &1.y - delta_y})
      |> normalize_scroll()

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

    socket
    |> update(:scroll, &%{&1 | x: new_x, y: new_y})
    |> update(:viewbox, &%{&1 | x: scroll.ratio_x * new_x, y: scroll.ratio_y * new_y})
  end

  defp handle_zoom(%Socket{} = socket) do
    %{zoom: zoom, screen: screen} = socket.assigns

    socket
    |> assign(class: "")
    |> update(
      :viewbox,
      fn viewbox ->
        %{viewbox | height: screen.height / zoom.value, width: screen.width / zoom.value}
      end
    )
    |> update(
      :zoom,
      &%{&1 | value: min(&1.max_value, max(&1.value, &1.min_value))}
    )
    |> update_scrollbars()
  end

  defp update_scrollbars(%Socket{} = socket) do
    %{viewbox: viewbox, canvas: canvas, screen: screen, scroll: scroll} = socket.assigns

    scroll_width_x = (screen.width - scroll.height) * (viewbox.width / canvas.width)
    scroll_width_x = max(scroll_width_x, screen.width / 3)

    scroll_width_y = (screen.height - scroll.height) * (viewbox.height / canvas.height)
    scroll_width_y = max(scroll_width_y, screen.height / 3)

    scroll_ratio_x =
      (canvas.width - viewbox.width) / (screen.width - scroll_width_x - scroll.height)

    scroll_ratio_y =
      (canvas.height - viewbox.height) / (screen.height - scroll_width_y - scroll.height)

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
