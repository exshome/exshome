defmodule ExshomeClock.Live.Settings do
  @moduledoc """
  Clock settings page.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Settings.ClockSettings, :settings}]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.live_component
      module={ExshomeWeb.Live.SettingsComponent}
      id="settings"
      settings={@deps.settings}
    />
    """
  end
end
