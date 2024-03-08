defmodule Exshome.Behaviours.VariableBehaviour do
  @moduledoc """
  Behaviour related to the variable.
  """
  alias Exshome.Id

  @callback set_value(Id.t(), any()) :: :ok | {:error, String.t()}
  @callback rename(Id.t(), name :: String.t()) :: :ok
  @callback delete(Id.t()) :: :ok
  @optional_callbacks [delete: 1, rename: 2]
end
