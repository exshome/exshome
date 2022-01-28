defmodule Exshome.Settings.ClockSettings do
  @moduledoc """
  Module for storing clock settings.
  """

  use Exshome.Settings,
    fields: [
      [name: :timezone, db_type: :string, default: "UTC", type: String.t()]
    ]
end
