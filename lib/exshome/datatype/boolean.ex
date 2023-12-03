defmodule Exshome.Datatype.Boolean do
  @moduledoc """
  Boolean datatype.
  """

  use Exshome.Behaviours.DatatypeBehaviour,
    base_type: :boolean,
    default: false,
    icon: "✅",
    name: "boolean"

  @impl DatatypeBehaviour
  def to_string(value) when is_boolean(value), do: {:ok, "#{value}"}
  def to_string(value), do: {:error, "#{inspect(value)} is not a boolean."}
end
