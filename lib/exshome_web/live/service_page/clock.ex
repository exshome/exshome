defmodule ExshomeWeb.Live.ServicePage.Clock do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb.Live.ServicePageLive,
    prefix: :clock,
    view_module: ExshomeWeb.ClockView,
    actions: [
      index: [{Exshome.Variable.Builtin.LocalTime, :time}],
      preview: [{Exshome.Variable.Builtin.LocalTime, :time}],
      settings: [{Exshome.Settings.ClockSettings, :settings}]
    ]
end
