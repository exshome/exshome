defmodule ExshomeWeb.Live.Clock.Index do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb.ServicePage,
    dependencies: %{
      Exshome.Service.ClockService => :time
    }

  @impl Phoenix.LiveView
  def render(assigns) do
    ExshomeWeb.ClockView.render("index.html", assigns)
  end
end
