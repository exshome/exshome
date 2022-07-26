defmodule Exshome.Variable do
  @moduledoc """
  Variable-related logic.
  """
  alias Exshome.DataType
  alias Exshome.Dependency
  alias Exshome.Event
  alias Exshome.SystemRegistry
  alias Exshome.Variable.VariableStateEvent

  defstruct [
    :dependency,
    :id,
    :name,
    :group,
    :not_ready_reason,
    :readonly?,
    :type,
    :validations
  ]

  @type t() :: %__MODULE__{
          dependency: Dependency.dependency(),
          id: String.t(),
          name: String.t(),
          group: String.t(),
          not_ready_reason: String.t() | nil,
          readonly?: boolean(),
          type: DataType.t(),
          validations: %{atom() => any()}
        }

  @callback set_value(Dependency.dependency(), any()) :: :ok | {:error, String.t()}

  @spec set_value(Dependency.dependency(), any()) :: :ok | {:error, String.t()}
  def set_value(dependency, value) do
    case validate_value(dependency, value) do
      {:ok, value} -> Dependency.dependency_module(dependency).set_value(dependency, value)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec validate_value(Dependency.dependency(), value :: any()) :: DataType.parse_result()
  defp validate_value(dependency, value) do
    raise_if_not_variable!(dependency)

    {:ok, %__MODULE__{} = config} =
      dependency
      |> Dependency.dependency_id()
      |> get_by_id()

    if config.readonly? do
      {:error, "Unable update a value for #{inspect(dependency)}. It is readonly."}
    else
      DataType.parse(config.type, value, config.validations)
    end
  end

  @spec list() :: [t()]
  def list, do: SystemRegistry.list(__MODULE__)

  @spec get_by_id(String.t()) :: {:ok, t()} | {:error, String.t()}
  def get_by_id(variable_id), do: SystemRegistry.get_by_id(__MODULE__, variable_id)

  @spec raise_if_not_variable!(Dependency.dependency()) :: any()
  defp raise_if_not_variable!(dependency) do
    module = Dependency.dependency_module(dependency)

    module_is_variable =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    if !module_is_variable do
      raise "#{inspect(dependency)} is not a Variable."
    end
  end

  @spec register_variable_data(t()) :: :ok
  def register_variable_data(%__MODULE__{} = variable_data) do
    :ok = SystemRegistry.register!(__MODULE__, variable_data.id, variable_data)
    broadcast_event(%VariableStateEvent{data: variable_data, type: :created})
  end

  @spec update_variable_data(t()) :: :ok
  def update_variable_data(%__MODULE__{} = variable_data) do
    :ok = SystemRegistry.update_value!(__MODULE__, variable_data.id, fn _ -> variable_data end)
    broadcast_event(%VariableStateEvent{data: variable_data, type: :updated})
  end

  @spec remove_variable_data(t()) :: :ok
  def remove_variable_data(%__MODULE__{} = variable_data) do
    :ok = SystemRegistry.remove!(__MODULE__, variable_data.id)
    broadcast_event(%VariableStateEvent{data: variable_data, type: :deleted})
  end

  defp broadcast_event(%VariableStateEvent{} = event) do
    :ok = Event.broadcast(event)
    :ok = Event.broadcast(event, event.data.id)
  end

  defmacro __using__(config) do
    quote do
      use Exshome.Dependency.GenServerDependency, unquote(config)
      import Exshome.Tag, only: [add_tag: 1]
      alias Exshome.Variable
      add_tag(Variable)

      @behaviour Variable
      use Variable.GenServerVariable
    end
  end
end
