defmodule ExshomeWeb.Live.HomePage do
  @moduledoc """
  Live Home page for our application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    services = [
      ExshomeWeb.Live.ServicePage.ClockPage,
      ExshomeWeb.Live.ServicePage.PlayerPage
    ]

    {:ok, assign(socket, services: services)}
  end

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _uri, socket), do: {:noreply, socket}
end
