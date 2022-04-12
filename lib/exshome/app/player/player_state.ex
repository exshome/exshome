defmodule Exshome.App.Player.PlayerState do
  @moduledoc """
  A structure for storing a playback state for the MPV client.
  """
  @keys [
    :path,
    :pause,
    :volume,
    :duration,
    :time_pos,
    :metadata
  ]

  defstruct @keys

  @type t() :: %__MODULE__{
          path: String.t() | nil,
          pause: boolean() | nil,
          volume: float() | nil,
          duration: float() | nil,
          time_pos: float() | nil,
          metadata: map() | nil
        }

  def property_mapping do
    for key <- @keys, into: %{} do
      property_key = key |> Atom.to_string() |> String.replace(~r/_/, "-")
      {property_key, key}
    end
  end
end
