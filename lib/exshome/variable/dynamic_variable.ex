defmodule Exshome.Variable.DynamicVariable do
  @moduledoc """
  A module for user-defined variables.
  """
  use Exshome.Variable,
    name: "dynamic_variable",
    variable: [
      group: "custom variables",
      type: Exshome.DataType.Unknown
    ]
end
