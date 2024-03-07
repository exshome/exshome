defmodule Exshome.Behaviours.VariableBehaviour do
  @moduledoc """
  Behaviour related to the variable.
  """
  alias Exshome.Emitter

  @callback set_value(Emitter.id(), any()) :: :ok | {:error, String.t()}
  @callback rename(Emitter.id(), name :: String.t()) :: :ok
  @callback delete(Emitter.id()) :: :ok
  @optional_callbacks [delete: 1, rename: 2]
end
