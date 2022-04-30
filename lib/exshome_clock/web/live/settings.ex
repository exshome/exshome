defmodule ExshomeClock.Web.Live.Settings do
  @moduledoc """
  Clock settings page.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Settings.ClockSettings, :settings}],
    icon: "⚙"
end
