defmodule Exshome.DataStream do
  @moduledoc """
  Contains all features related to DataStream.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady

  @type stream() :: Dependency.dependency()
  @type changes() :: Operation.t()
  @type get_value_result() :: NotReady | Operation.ReplaceAll.t()
  @type stream_event() :: NotReady | Operation.t()

  @available_batch_operations [
    Operation.Insert,
    Operation.Update,
    Operation.Delete,
    Operation.ReplaceAll
  ]

  @callback handle_get_value() :: [term()]

  @spec get_value(stream()) :: get_value_result()
  def get_value(stream) do
    result = Dependency.get_module(stream).handle_get_value()
    prepare_get_value_result(result)
  end

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

  @spec prepare_get_value_result(list() | NotReady) :: NotReady | Operation.ReplaceAll.t()
  def prepare_get_value_result(NotReady), do: NotReady

  def prepare_get_value_result(data) when is_list(data) do
    %Operation.ReplaceAll{data: data}
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
      @behaviour DataStream

      @impl Dependency
      def type, do: DataStream

      @impl Dependency
      defdelegate get_value(stream), to: DataStream
    end
  end
end
