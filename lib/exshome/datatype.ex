defmodule Exshome.DataType do
  @moduledoc """
  Stores generic ways to work with custom datatypes.
  """

  @type t() :: atom()

  defmacro __using__(_opts) do
    quote do
      use Ecto.Type
    end
  end
end
