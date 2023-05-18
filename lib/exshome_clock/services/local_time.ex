defmodule ExshomeClock.Services.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  use Exshome.Dependency.SimpleGenServerDependency,
    name: "local_time",
    subscribe: [
      dependencies: [
        {ExshomeClock.Services.UtcTime, :utc_time},
        {ExshomeClock.Settings.ClockSettings, :settings}
      ]
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: deps} = state) do
    value =
      DateTime.shift_zone!(
        deps.utc_time,
        deps.settings.timezone
      )

    update_value(state, fn _ -> value end)
  end
end
