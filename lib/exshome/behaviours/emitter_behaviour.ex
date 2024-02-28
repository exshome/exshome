defmodule Exshome.Behaviours.EmitterBehaviour do
  @moduledoc """
  Allows to create implementations of specific emitter types.

  Example implementation:
  ```elixir
  defmodule Example.CustomDataStream do
    use #{inspect(__MODULE__)}, type: Exshome.DataStream
  end
  ```
  """

  @callback emitter_type() :: module()

  @doc """
  Implements a behaviour.
  """
  defmacro __using__(type: type) do
    quote do
      @behaviour unquote(__MODULE__)
      def emitter_type, do: unquote(type)
    end
  end
end
