defmodule Exshome.Datatype.Boolean do
  @moduledoc """
  Boolean datatype.
  """

  use Exshome.Datatype, base_type: :boolean, default: false, icon: "✅", name: "boolean"

  @impl Datatype
  def to_string(value) when is_boolean(value), do: {:ok, "#{value}"}
  def to_string(_), do: :error
end
