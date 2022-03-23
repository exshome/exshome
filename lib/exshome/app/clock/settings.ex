defmodule Exshome.App.Clock.Settings do
  @moduledoc """
  Module for storing clock settings.
  """

  use Exshome.Settings,
    name: "settings_clock",
    fields: [
      timezone: [
        allowed_values: &TzExtra.time_zone_identifiers/0,
        default: "Etc/UTC",
        required: true,
        type: DataType.String
      ]
    ]
end
