defmodule Exshome.DataStream do
  @moduledoc """
  An `m:Exshome.EmitterType`, that allows to publish changes in some resources and subscribe to them.
  Stream of changes contains one `t:Exshome.DataStream.Operation.t/0` operation.
  """

  alias Exshome.Behaviours.EmitterTypeBehaviour
  alias Exshome.DataStream.Operation

  @available_batch_operations [
    Operation.Insert,
    Operation.Update,
    Operation.Delete,
    Operation.ReplaceAll
  ]

  @behaviour EmitterTypeBehaviour

  @impl EmitterTypeBehaviour
  def required_behaviours, do: MapSet.new()

  @impl EmitterTypeBehaviour
  def topic_prefix, do: "data_stream"

  @impl EmitterTypeBehaviour
  def validate_message!(%module{}) when module in @available_batch_operations, do: :ok

  def validate_message!(%Operation.Batch{operations: operations}) do
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
