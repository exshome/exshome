defmodule ExshomeWeb.Live.ServicePage.Clock do
  @moduledoc """
  Clock view for the application.
  """
  alias ExshomeWeb.Live.ServicePageLive

  @behaviour ServicePageLive

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

  @impl ServicePageLive
  def base_prefix, do: :clock
end
