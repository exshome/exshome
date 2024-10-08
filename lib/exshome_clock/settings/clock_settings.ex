defmodule ExshomeClock.Settings.ClockSettings do
  @moduledoc """
  Module for storing clock settings.
  """

  use Exshome.Settings,
    name: "clock_settings",
    fields: [
      timezone: [
        allowed_values: &TzExtra.time_zone_ids/0,
        default: "Etc/UTC",
        required: true,
        type: Exshome.Datatype.String
      ]
    ]
end
