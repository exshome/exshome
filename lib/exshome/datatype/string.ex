defmodule Exshome.Datatype.String do
  @moduledoc """
  String datatype.
  """

  use Exshome.Datatype, base_type: :string, icon: "🔤", name: "string"

  @impl Datatype
  def to_string(value) when is_binary(value), do: {:ok, value}
  def to_string(_), do: :error
end
