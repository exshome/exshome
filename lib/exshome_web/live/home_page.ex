defmodule ExshomeWeb.Live.HomePage do
  @moduledoc """
  Live Home page for our application.
  """

  use ExshomeWeb, :live_view
  alias ExshomeWeb.Live
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    apps = [
      Live.ClockApp,
      Live.PlayerApp
    ]

    {:ok, assign(socket, apps: apps)}
  end
end
