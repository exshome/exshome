defmodule ExshomeWeb.Live.ServicePage.Clock do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb.Live.ServicePageLive,
    prefix: :clock,
    view_module: ExshomeWeb.ClockView,
    actions: %{
      index: %{
        Exshome.Service.ClockService => :time
      },
      preview: %{
        Exshome.Service.ClockService => :time
      }
    }
end
