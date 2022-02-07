defmodule Exshome.DataType do
  @moduledoc """
  Stores generic ways to work with custom datatypes.
  """

  defmacro __using__(_opts) do
    quote do
      use Ecto.Type
    end
  end
end
