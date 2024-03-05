defmodule ExshomeAutomation.Services.VariableRegistry do
  @moduledoc """
  Lists available variables.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateStream

  use Exshome.Dependency.GenServerDependency,
    app: ExshomeAutomation,
    name: "variable_registry",
    subscribe: [
      streams: [VariableStateStream]
    ]

  @impl GenServerDependencyBehaviour
  def on_init(%DependencyState{} = state) do
    variables =
      for %Variable{} = variable <- Variable.list(), into: %{} do
        {variable.id, variable}
      end

    update_value(state, fn _ -> variables end)
  end

  @impl Subscription
  def on_stream(
        %DependencyState{} = state,
        {VariableStateStream, %Operation.Delete{data: %Variable{id: id}}}
      ) do
    update_value(state, &Map.delete(&1, id))
  end

  def on_stream(
        %DependencyState{} = state,
        {VariableStateStream, %operation{data: %Variable{} = variable}}
      )
      when operation in [Operation.Insert, Operation.Update] do
    update_value(state, &Map.put(&1, variable.id, variable))
  end
end
