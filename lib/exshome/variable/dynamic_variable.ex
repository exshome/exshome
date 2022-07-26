defmodule Exshome.Variable.DynamicVariable do
  @moduledoc """
  A module for user-defined variables.
  """
  alias Exshome.DataType
  alias Exshome.Variable.DynamicVariable.Schema
  alias Exshome.Variable.DynamicVariable.Supervisor, as: VariableSupervisor

  @group "custom_variables"

  use Exshome.Variable,
    name: "dynamic_variable",
    variable: [
      group: @group,
      type: Exshome.DataType.Unknown
    ]

  @impl GenServerDependency
  def on_init(%DependencyState{dependency: {__MODULE__, id}} = state) when is_binary(id) do
    data = Schema.get!(id)

    state
    |> update_data(fn _ -> data end)
    |> update_value("")
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

  @spec create_variable!(type :: DataType.t()) :: :ok
  def create_variable!(DataType.Unknown), do: raise("Unable to create variable for unknown type")

  def create_variable!(type) do
    %Schema{id: id} = Schema.create!(type.name())

    spec = child_spec(%{dependency: {__MODULE__, id}, name: nil})
    {:ok, _} = Supervisor.start_child(VariableSupervisor, spec)
    :ok
  end
end
