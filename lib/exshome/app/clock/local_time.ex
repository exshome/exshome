defmodule Exshome.App.Clock.LocalTime do
  @moduledoc """
  Provides a value for local time.
  It subscribes to the changes in clock settings and current time.
  """
  alias Exshome.App.Clock

  use Exshome.Variable,
    name: "local_time",
    datatype: Exshome.DataType.String,
    dependencies: [
      {Clock.UtcTimeService, :utc_time},
      {Clock.Settings, :settings}
    ]

  @impl Variable
  def handle_dependency_change(%State{deps: deps} = state) do
    value =
      DateTime.shift_zone!(
        deps.utc_time,
        deps.settings.timezone
      )

    update_value(state, value)
  end
end
