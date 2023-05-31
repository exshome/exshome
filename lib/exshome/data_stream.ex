defmodule Exshome.DataStream do
  @moduledoc """
  Contains all features related to DataStream.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady

  @type stream() :: Dependency.dependency()
  @type changes() :: Operation.t()
  @type stream_event() :: NotReady | Operation.t()

  @available_batch_operations [
    Operation.Insert,
    Operation.Update,
    Operation.Delete,
    Operation.ReplaceAll
  ]

  @spec broadcast(stream(), changes()) :: :ok
  def broadcast(stream, changes) do
    raise_if_invalid_stream!(stream)
    raise_if_invalid_changes!(changes)
    :ok = Dependency.broadcast_value(stream, changes)
  end

  @spec raise_if_invalid_stream!(stream()) :: any()
  defp raise_if_invalid_stream!(stream) do
    Dependency.raise_if_not_dependency!(__MODULE__, stream)
  end

  @spec raise_if_invalid_changes!(changes()) :: any()
  defp raise_if_invalid_changes!(%module{}) when module in @available_batch_operations, do: :ok

  defp raise_if_invalid_changes!(%Operation.Batch{operations: operations}) do
    unsupported_operations =
      for operation <- operations,
          %module{} = operation,
          module not in @available_batch_operations,
          do: operation

    if Enum.any?(unsupported_operations) do
      raise "Data stream does not support these operations: #{inspect(unsupported_operations)}."
    end

    :ok
  end

  defmacro __using__(name) do
    quote do
      alias Exshome.DataStream
      use Exshome.Named, "stream:#{unquote(name)}"
      use Exshome.Dependency
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(DataStream)

      @impl Dependency
      def type, do: DataStream

      @impl Dependency
      def get_value(stream), do: :ok
    end
  end
end
