defmodule ExshomeWeb.Live.HomePage do
  @moduledoc """
  Live Home page for our application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket
  alias ExshomeWeb.Live.App

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    apps = [
      App.Clock,
      App.Player
    ]

    {:ok, assign(socket, apps: apps)}
  end
end
