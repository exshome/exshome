defmodule Exshome.ServiceSettings.Settings do
  @moduledoc """
  Schema for storing application settings.
  """
  use Exshome.Schema
  import Ecto.Changeset

  schema "service_settings" do
    field(:settings, :map)

    timestamps()
  end

  @doc false
  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:settings])
    |> validate_required([:settings])
  end
end
