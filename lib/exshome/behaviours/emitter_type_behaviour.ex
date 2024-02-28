defmodule Exshome.Behaviours.EmitterTypeBehaviour do
  @moduledoc """
  Allows to create a module to use with `m:Exshome.Emitter`.
  """

  @doc """
  All child events should implement this behaviour.
  """
  @callback required_behaviours() :: MapSet.t(module())

  @doc """
  Validates message to be sent.
  Raises error if message is invalid.
  """
  @callback validate_message!(term()) :: :ok
end
