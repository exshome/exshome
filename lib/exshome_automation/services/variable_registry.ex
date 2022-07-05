defmodule ExshomeAutomation.Services.VariableRegistry do
  @moduledoc """
  Lists available variables.
  """
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateEvent

  use Exshome.Dependency.GenServerDependency,
    name: "variable_registry",
    subscribe: [
      events: [VariableStateEvent]
    ]

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    variables =
      for %Variable{} = variable <- Variable.list(), into: %{} do
        {variable.id, variable}
      end

    update_value(state, variables)
  end

  @impl Subscription
  def handle_event(
        %VariableStateEvent{data: %Variable{id: id}, type: :deleted},
        %DependencyState{} = state
      ) do
    update_value(state, Map.delete(state.value, id))
  end

  @impl Subscription
  def handle_event(
        %VariableStateEvent{data: %Variable{} = variable, type: type},
        %DependencyState{} = state
      )
      when type in [:created, :updated] do
    update_value(state, Map.put(state.value, variable.id, variable))
  end
end
