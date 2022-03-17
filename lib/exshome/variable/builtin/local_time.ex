defmodule Exshome.Variable.Builtin.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  use Exshome.Variable,
    name: "local_time",
    datatype: Exshome.DataType.String,
    dependencies: [
      {Exshome.Service.ClockService, :utc_time},
      {Exshome.Settings.ClockSettings, :clock_settings}
    ]

  @impl Variable
  def handle_dependency_change(%State{deps: deps} = state) do
    value =
      DateTime.shift_zone!(
        deps.utc_time,
        deps.clock_settings.timezone
      )

    update_value(state, value)
  end
end
