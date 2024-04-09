defmodule ExshomeAutomation.Services.VariableRegistry do
  @moduledoc """
  Lists available variables.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Emitter
  alias Exshome.Variable
  alias Exshome.Variable.VariableConfig
  alias Exshome.Variable.VariableStateStream

  use Exshome.Service.DependencyService,
    app: ExshomeAutomation,
    name: "variable_registry"

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    :ok = Emitter.subscribe(VariableStateStream)

    variables =
      for %VariableConfig{} = variable <- Variable.list(), into: %{} do
        {variable.id, variable}
      end

    update_value(state, fn _ -> variables end)
  end

  @impl DependencyServiceBehaviour
  def handle_stream(
        {VariableStateStream, %Operation.Delete{data: %VariableConfig{id: id}}},
        %ServiceState{} = state
      ) do
    update_value(state, &Map.delete(&1, id))
  end

  def handle_stream(
        {VariableStateStream, %operation{data: %VariableConfig{} = variable}},
        %ServiceState{} = state
      )
      when operation in [Operation.Insert, Operation.Update] do
    update_value(state, &Map.put(&1, variable.id, variable))
  end
end
