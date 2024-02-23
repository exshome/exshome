defmodule Exshome.Variable.VariableStateStream do
  @moduledoc """
  DataStream for variable state changes.
  """

  alias Exshome.Behaviours.DataStreamBehaviour

  @behaviour DataStreamBehaviour

  @impl DataStreamBehaviour
  def data_stream_topic, do: "exshome:variable_state"
end
