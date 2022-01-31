defmodule Exshome.Settings.ClockSettings do
  @moduledoc """
  Module for storing clock settings.
  """

  use Exshome.Settings,
    fields: [
      [name: :timezone, db_type: :string, default: "Etc/UTC", type: String.t()]
    ]

  @impl Settings
  def validate(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_inclusion(:timezone, TzExtra.time_zone_identifiers())
  end
end
