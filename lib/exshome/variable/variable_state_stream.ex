defmodule Exshome.Variable.VariableStateStream do
  @moduledoc """
  DataStream for variable state changes.
  """
  alias Exshome.Behaviours.EmitterBehaviour

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def app, do: Exshome

  @impl EmitterBehaviour
  def type, do: Exshome.DataStream
end
