defmodule ExshomeAutomation.Variables.DynamicVariable do
  @moduledoc """
  A module for user-defined variables.
  """
  alias Exshome.Behaviours.VariableBehaviour
  alias Exshome.Datatype
  alias Exshome.Dependency
  alias Exshome.Variable.VariableConfig
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor

  @group "automation"

  use Exshome.Service.VariableService,
    app: ExshomeAutomation,
    name: "dynamic_variable",
    parent_module: VariableSupervisor,
    variable: [
      group: @group,
      readonly?: true,
      type: Datatype.Unknown
    ]

  @impl ServiceBehaviour
  def init(%ServiceState{id: {__MODULE__, id}} = state) when is_binary(id) do
    id
    |> Schema.get!()
    |> set_state_from_schema(state)
  end

  @impl VariableServiceBehaviour
  def variable_from_state(%ServiceState{data: %Schema{} = schema, id: id}) do
    type = Datatype.get_by_name(schema.type)

    %VariableConfig{
      dependency: id,
      id: Dependency.dependency_id(id),
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

  @impl ServiceBehaviour
  def handle_call({:rename, name}, _, %ServiceState{} = state) do
    state =
      state.data
      |> Schema.rename!(name)
      |> set_state_from_schema(state)

    {:reply, :ok, state}
  end

  @impl VariableServiceBehaviour
  def handle_set_value(value, %ServiceState{data: %Schema{}} = state) do
    state.data
    |> Schema.update_value!(value)
    |> set_state_from_schema(state)
  end

  @spec create_variable!(type :: Datatype.t()) :: :ok
  def create_variable!(Datatype.Unknown), do: raise("Unable to create variable for unknown type")

  def create_variable!(type) do
    %Schema{id: id} =
      type
      |> Datatype.name()
      |> Schema.create!()

    VariableSupervisor.start_child_with_id(id)
  end

  defp set_state_from_schema(%Schema{} = data, %ServiceState{} = state) do
    state
    |> update_data(fn _ -> data end)
    |> update_value_from_schema()
  end

  defp update_value_from_schema(%ServiceState{data: %Schema{} = schema} = state) do
    {:ok, value} =
      schema.type
      |> Datatype.get_by_name()
      |> Ecto.Type.cast(schema.value)

    update_value(state, fn _ -> value end)
  end

  @impl VariableBehaviour
  def delete({__MODULE__, id}) when is_binary(id) do
    id
    |> Schema.get!()
    |> Schema.delete!()

    :ok = VariableSupervisor.terminate_child_with_id(id)
  end

  @impl VariableBehaviour
  def rename(id, name) when is_binary(name) do
    Exshome.Service.call(id, {:rename, name})
  end
end
