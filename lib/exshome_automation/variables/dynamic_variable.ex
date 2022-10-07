defmodule ExshomeAutomation.Variables.DynamicVariable do
  @moduledoc """
  A module for user-defined variables.
  """
  alias Exshome.Datatype
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor

  @group "automation"

  use Exshome.Variable,
    name: "dynamic_variable",
    child_module: VariableSupervisor,
    variable: [
      group: @group,
      readonly?: true,
      type: Datatype.Unknown
    ]

  @impl GenServerDependency
  def on_init(%DependencyState{dependency: {__MODULE__, id}} = state) when is_binary(id) do
    id
    |> Schema.get!()
    |> set_state_from_schema(state)
  end

  @impl GenServerVariable
  def variable_from_dependency_state(%DependencyState{
        data: %Schema{} = schema,
        dependency: dependency
      }) do
    type = Datatype.get_by_name(schema.type)

    %Variable{
      dependency: dependency,
      id: Dependency.dependency_id(dependency),
      name: schema.name,
      group: @group,
      not_ready_reason: nil,
      readonly?: type == Datatype.Unknown,
      can_delete?: true,
      can_rename?: true,
      type: type,
      validations: schema.opts
    }
  end

  def variable_from_dependency_state(state), do: super(state)

  @impl GenServerDependency
  def handle_call({:rename, name}, _, %DependencyState{} = state) do
    state =
      state.data
      |> Schema.rename!(name)
      |> set_state_from_schema(state)

    {:reply, :ok, state}
  end

  @impl GenServerVariable
  def handle_set_value(%DependencyState{data: %Schema{}} = state, value) do
    state.data
    |> Schema.update_value!(value)
    |> set_state_from_schema(state)
  end

  @spec create_variable!(type :: Datatype.t()) :: :ok
  def create_variable!(Datatype.Unknown), do: raise("Unable to create variable for unknown type")

  def create_variable!(type) do
    %Schema{id: id} = Schema.create!(type.name())
    VariableSupervisor.start_child_with_id(id)
  end

  defp set_state_from_schema(%Schema{} = data, %DependencyState{} = state) do
    state
    |> update_data(fn _ -> data end)
    |> update_value_from_schema()
  end

  defp update_value_from_schema(%DependencyState{data: %Schema{} = schema} = state) do
    {:ok, value} =
      schema.type
      |> Datatype.get_by_name()
      |> Ecto.Type.cast(schema.value)

    update_value(state, fn _ -> value end)
  end

  @impl Variable
  def delete({__MODULE__, id}) when is_binary(id) do
    id
    |> Schema.get!()
    |> Schema.delete!()

    :ok = VariableSupervisor.terminate_child_with_id(id)
  end

  @impl Variable
  def rename(dependency, name) when is_binary(name) do
    GenServerDependency.call(dependency, {:rename, name})
  end
end
