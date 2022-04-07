defmodule Exshome.App.Clock.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  alias Exshome.App.Clock

  use Exshome.Dependency.GenServerDependency,
    name: "local_time",
    dependencies: [
      {Clock.UtcTime, :utc_time},
      {Clock.ClockSettings, :settings}
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
