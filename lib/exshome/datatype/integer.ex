defmodule Exshome.Datatype.Integer do
  @moduledoc """
  Integer datatype.
  """

  use Exshome.Datatype,
    base_type: :integer,
    icon: "🔢",
    name: "integer",
    validations: [:min, :max]

  @impl Datatype
  def validate(value, :min, min_value) when is_integer(min_value) do
    if value >= min_value do
      {:ok, value}
    else
      {:error, "Should be more than or equal to #{min_value}"}
    end
  end

  def validate(value, :max, max_value) when is_integer(max_value) do
    if value <= max_value do
      {:ok, value}
    else
      {:error, "Should less then or equal to #{max_value}"}
    end
  end

  @impl Datatype
  def to_string(value) when is_integer(value), do: {:ok, "#{value}"}
end
