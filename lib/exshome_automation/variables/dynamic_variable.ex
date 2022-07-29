defmodule ExshomeAutomation.Variables.DynamicVariable do
  @moduledoc """
  A module for user-defined variables.
  """
  alias Exshome.DataType
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor

  @group "automation"

  use Exshome.Variable,
    name: "dynamic_variable",
    child_module: VariableSupervisor,
    variable: [
      group: @group,
      type: DataType.Unknown
    ]

  @impl GenServerDependency
  def on_init(%DependencyState{dependency: {__MODULE__, id}} = state) when is_binary(id) do
    data = Schema.get!(id)

    state
    |> update_data(fn _ -> data end)
    |> update_value(data.value)
  end

  @impl GenServerVariable
  def variable_from_dependency_state(%DependencyState{
        data: %Schema{} = schema,
        dependency: dependency
      }) do
    type = DataType.get_by_name(schema.type)

    %Variable{
      dependency: dependency,
      id: Dependency.dependency_id(dependency),
      name: schema.name,
      group: @group,
      not_ready_reason: nil,
      readonly?: type == DataType.Unknown,
      type: type,
      validations: schema.opts
    }
  end

  def variable_from_dependency_state(state), do: super(state)

  @impl GenServerVariable
  def handle_set_value(%DependencyState{} = state, value) do
    update_value(state, value)
  end

  @spec create_variable!(type :: DataType.t()) :: :ok
  def create_variable!(DataType.Unknown), do: raise("Unable to create variable for unknown type")

  def create_variable!(type) do
    %Schema{id: id} = Schema.create!(type.name())
    VariableSupervisor.start_child_with_id(id)
  end
end
