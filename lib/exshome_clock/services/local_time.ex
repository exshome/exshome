defmodule ExshomeClock.Services.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  use Exshome.Service.DependencyService,
    app: ExshomeClock,
    name: "local_time",
    dependencies: [
      utc_time: ExshomeClock.Services.UtcTime,
      settings: ExshomeClock.Settings.ClockSettings
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(deps, %ServiceState{} = state) do
    value =
      DateTime.shift_zone!(
        deps.utc_time,
        deps.settings.timezone
      )

    update_value(state, fn _ -> value end)
  end
end
