defmodule Exshome.Variable do
  @moduledoc """
  Variable-related logic.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Datatype
  alias Exshome.Dependency
  alias Exshome.Emitter
  alias Exshome.Id
  alias Exshome.SystemRegistry
  alias Exshome.Variable.VariableConfig
  alias Exshome.Variable.VariableStateStream

  @spec set_value(Id.t(), any()) :: :ok | {:error, String.t()}
  def set_value(dependency, value) do
    case validate_value(dependency, value) do
      {:ok, value} -> Id.get_module(dependency).set_value(dependency, value)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate_value(Id.t(), value :: any()) :: Datatype.parse_result()
  defp validate_value(variable, value) do
    {:ok, %VariableConfig{} = config} =
      variable
      |> Dependency.dependency_id()
      |> get_by_id()

    if config.readonly? do
      {:error, "Unable update a value for #{inspect(variable)}. It is readonly."}
    else
      Datatype.parse(config.type, value, config.validations)
    end
  end

  @spec list() :: [VariableConfig.t()]
  def list, do: SystemRegistry.list(VariableConfig)

  @spec get_by_id(String.t()) :: {:ok, VariableConfig.t()} | {:error, String.t()}
  def get_by_id(variable_id), do: SystemRegistry.get_by_id(VariableConfig, variable_id)

  @spec delete_by_id!(String.t()) :: :ok
  def delete_by_id!(id) do
    {:ok, %VariableConfig{} = variable} = get_by_id(id)

    unless variable.can_delete? do
      raise "Unable to delete #{variable.name}"
    end

    %VariableConfig{service_id: service_id} = variable

    Id.get_module(service_id).delete(service_id)
  end

  @spec rename_by_id!(id :: String.t(), name :: String.t()) :: :ok
  def rename_by_id!(id, name) when is_binary(name) do
    {:ok, %VariableConfig{} = variable} = get_by_id(id)

    unless variable.can_rename? do
      raise "Unable to rename #{variable.name}"
    end

    %VariableConfig{service_id: service_id} = variable

    Id.get_module(service_id).rename(service_id, name)
  end

  @spec register_variable_data(VariableConfig.t()) :: :ok
  def register_variable_data(%VariableConfig{} = variable_data) do
    :ok = SystemRegistry.register!(VariableConfig, variable_data.id, variable_data)
    broadcast_state(%Operation.Insert{data: variable_data})
  end

  @spec update_variable_data(VariableConfig.t()) :: :ok
  def update_variable_data(%VariableConfig{} = variable_data) do
    :ok =
      SystemRegistry.update_value!(VariableConfig, variable_data.id, fn _ -> variable_data end)

    broadcast_state(%Operation.Update{data: variable_data})
  end

  @spec remove_variable_data(VariableConfig.t()) :: :ok
  def remove_variable_data(%VariableConfig{} = variable_data) do
    :ok = SystemRegistry.remove!(VariableConfig, variable_data.id)
    broadcast_state(%Operation.Delete{data: variable_data})
  end

  @spec broadcast_state(Operation.single_operation()) :: :ok
  defp broadcast_state(%{data: %VariableConfig{}} = operation) do
    :ok = Emitter.broadcast(VariableStateStream, operation)
    :ok = Emitter.broadcast({VariableStateStream, operation.data.id}, operation)
  end
end
