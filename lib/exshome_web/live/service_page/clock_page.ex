defmodule ExshomeWeb.Live.ServicePage.ClockPage do
  @moduledoc """
  Clock page for the application.
  """
  alias Exshome.App.Clock

  use ExshomeWeb.Live.ServicePageLive,
    prefix: :clock,
    view_module: ExshomeWeb.ServicePage.ClockView,
    actions: [
      index: [{Clock.LocalTime, :time}],
      preview: [{Clock.LocalTime, :time}],
      settings: [{Clock.ClockSettings, :settings}]
    ]
end
