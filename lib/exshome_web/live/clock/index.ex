defmodule ExshomeWeb.Live.Clock.Index do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb, :live_view
  alias Exshome.Service.Clock
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    time = Clock.subscribe()
    {:ok, assign(socket, time: time)}
  end

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _url, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({Clock, time}, %Socket{} = socket) do
    {:noreply, assign(socket, time: time)}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ExshomeWeb.ClockView.render("index.html", assigns)
  end
end
