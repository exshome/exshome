defmodule Exshome.Variable.VariableStateStream do
  @moduledoc """
  DataStream for variable state changes.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic({__MODULE__, id}), do: "variable_state:#{id}"
  def data_stream_topic(__MODULE__), do: "variable_state"
end
