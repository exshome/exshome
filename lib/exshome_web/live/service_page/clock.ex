defmodule ExshomeWeb.Live.ServicePage.Clock do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb.Live.ServicePageLive, :clock

  @impl ServicePageLive
  def dependencies do
    %{
      Exshome.Service.ClockService => :time
    }
  end

  @impl ServicePageLive
  def render(assigns) do
    ExshomeWeb.ClockView.render("index.html", assigns)
  end
end
