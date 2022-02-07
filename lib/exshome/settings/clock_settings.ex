defmodule Exshome.Settings.ClockSettings do
  @moduledoc """
  Module for storing clock settings.
  """

  use Exshome.Settings,
    name: "settings_clock",
    fields: [
      timezone: [
        default: "Etc/UTC",
        type: DataType.String
      ]
    ]

  @impl Settings
  def changeset(%Ecto.Changeset{} = data) do
    data
    |> validate_inclusion(:timezone, TzExtra.time_zone_identifiers())
  end
end
