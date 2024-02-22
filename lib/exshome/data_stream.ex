defmodule Exshome.DataStream do
  @moduledoc """
  An `m:Exshome.Emitter`, that allows to publish changes in some resources and subscribe to them.
  Stream of changes contains one `t:Exshome.DataStream.Operation.t/0` operation.

  If you want to create a new data stream, your module needs to implement `m:Exshome.Behaviours.DataStreamBehaviour` behaviour. Then you will be able to use it with `m:#{inspect(__MODULE__)}`.
  """

  alias Exshome.Behaviours.DataStreamBehaviour
  alias Exshome.Behaviours.EmitterBehaviour
  alias Exshome.DataStream.Operation
  alias Exshome.Emitter

  @behaviour EmitterBehaviour

  @impl EmitterBehaviour
  def child_behaviour, do: DataStreamBehaviour

  @impl EmitterBehaviour
  def child_module({module, _id}), do: module
  def child_module(module) when is_atom(module), do: module

  @impl EmitterBehaviour
  def pub_sub_topic(stream) do
    module = child_module(stream)
    module.data_stream_topic(stream)
  end

  @impl EmitterBehaviour
  def topic_prefix, do: "data_stream"

  @doc """
  Subscribes to a stream. Subscriber will receive every change to the mailbox.
  For example, you can process it with `c:GenServer.handle_info/2` callback.

  Message format is a tuple `{#{inspect(__MODULE__)}, {stream, operation}}`, where:
  - `stream` is the stream you have subscribed to;
  - `operation` is one of `t:Exshome.DataStream.Operation.t/0`.
  """
  @spec subscribe(DataStreamBehaviour.stream()) :: :ok
  def subscribe(stream), do: Emitter.subscribe(__MODULE__, stream)

  @doc """
  Unsubscribes from the data stream.
  Your process will no longer receive new updates, though it still may have some previous messages in the mailbox.
  """
  @spec unsubscribe(DataStreamBehaviour.stream()) :: :ok
  def unsubscribe(stream), do: Emitter.unsubscribe(__MODULE__, stream)

  @doc """
  Broadcast data stream changes.
  """
  @spec broadcast(DataStreamBehaviour.stream(), Operation.t()) :: :ok
  def broadcast(stream, changes) do
    raise_if_invalid_operation!(changes)

    Emitter.broadcast(__MODULE__, stream, {stream, changes})
  end

  @available_batch_operations [
    Operation.Insert,
    Operation.Update,
    Operation.Delete,
    Operation.ReplaceAll
  ]

  @spec raise_if_invalid_operation!(Operation.t()) :: any()
  defp raise_if_invalid_operation!(%module{}) when module in @available_batch_operations, do: :ok

  defp raise_if_invalid_operation!(%Operation.Batch{operations: operations}) do
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
end
