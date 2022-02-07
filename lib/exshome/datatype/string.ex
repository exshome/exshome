defmodule Exshome.DataType.String do
  @moduledoc """
  String datatype.
  """

  use Exshome.DataType

  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(data) when is_binary(data), do: {:ok, data}
  def cast(_), do: :error

  @impl Ecto.Type
  def dump(term) when is_binary(term), do: {:ok, term}

  @impl Ecto.Type
  def load(term) when is_binary(term), do: {:ok, term}
end
