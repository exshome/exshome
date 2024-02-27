defmodule Exshome.Variable.VariableStateStream do
  @moduledoc """
  DataStream for variable state changes.
  """
  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def emitter_type, do: Exshome.DataStream
end
