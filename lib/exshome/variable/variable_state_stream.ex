defmodule Exshome.Variable.VariableStateStream do
  @moduledoc """
  DataStream for variable state changes.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.DataStream
end
