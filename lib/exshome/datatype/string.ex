defmodule Exshome.Datatype.String do
  @moduledoc """
  String datatype.
  """

  use Exshome.Behaviours.DatatypeBehaviour,
    base_type: :string,
    default: "",
    icon: "🔤",
    name: "string"

  @impl DatatypeBehaviour
  def to_string(value) when is_binary(value), do: {:ok, value}
  def to_string(value), do: {:error, "#{inspect(value)} is not a string}"}
end
