defmodule ExshomeClock.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  use Exshome.Dependency.GenServerDependency,
    name: "local_time",
    dependencies: [
      {ExshomeClock.UtcTime, :utc_time},
      {ExshomeClock.ClockSettings, :settings}
    ]

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{deps: deps} = state) do
    value =
      DateTime.shift_zone!(
        deps.utc_time,
        deps.settings.timezone
      )

    update_value(state, value)
  end
end
