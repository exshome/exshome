defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [],
    icon: "🤖️"

  @impl LiveView
  def mount(_params, _session, socket) do
    components = for x <- 1..10_000, do: generate_component("rect-#{x}")

    socket = assign(socket, components: components, selected: nil)
    {:ok, socket, temporary_assigns: [components: []]}
  end

  @impl LiveView
  def handle_event("select", %{"id" => "component-" <> id}, %Socket{} = socket) do
    {:noreply, assign(socket, :selected, id)}
  end

  def handle_event("drag", %{"x" => x, "y" => y}, %Socket{} = socket) do
    socket =
      case socket.assigns.selected do
        nil ->
          socket

        selected ->
          component = generate_component(selected)
          assign(socket, :components, [%{component | x: fit_in_box(x), y: fit_in_box(y)}])
      end

    {:noreply, socket}
  end

  def handle_event("deselect", _, %Socket{} = socket) do
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

  defp fit_in_box(coordinate) do
    coordinate
    |> min(100)
    |> max(0)
  end
end
