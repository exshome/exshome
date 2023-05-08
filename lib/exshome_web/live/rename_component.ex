defmodule ExshomeWeb.Live.RenameComponent do
  @moduledoc """
  A component to render form to rename a service.
  """
  use ExshomeWeb, :live_component

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign_new(:rename, fn -> false end)
      |> assign(
        component_id: assigns.id,
        value: assigns.value,
        can_rename?: assigns.can_rename?
      )

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("toggle_rename", _, socket) do
    socket = update(socket, :rename, fn rename -> !rename end)
    {:noreply, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <form class="w-full md:w-3/4 flex items-center justify-center" phx-change={@component_id}>
      <%= if @rename do %>
        <.datatype_input
          class="md:ml-8"
          type={Exshome.Datatype.String}
          value={@value}
          validations={%{}}
          name="value"
        />
      <% else %>
        <h2 class={
          "text-lg inline md:text-3xl font-black [word-break:break-word] text-center #{if @can_rename?, do: 'pl-8'}"
        }>
          <%= @value %>
        </h2>
      <% end %>
      <%= if @can_rename? do %>
        <.button class="text-xs inline" phx-click="toggle_rename" type="button" phx-target={@myself}>
          <.icon name={if @rename, do: "hero-x-mark", else: "hero-pencil-square"} />
        </.button>
      <% end %>
    </form>
    """
  end
end
