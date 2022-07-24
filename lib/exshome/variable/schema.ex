defmodule Exshome.Variable.Schema do
  @moduledoc """
  Schema for storing dynamic variable data.
  """

  use Exshome.Schema

  schema "service_settings" do
    field(:name, :string, default: "")
    field(:opts, :map)
    field(:type, :string)
    field(:value, :string)
    field(:version, :integer)

    timestamps()
  end
end
