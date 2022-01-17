defmodule ExshomeWeb.Live.HomePage do
  @moduledoc """
  Live Home page for our application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    services = [
      {ExshomeWeb.Live.ServicePreview, "clock"}
    ]

    {:ok, assign(socket, services: services)}
  end
end
