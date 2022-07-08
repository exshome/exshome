defmodule Exshome.Variable do
  @moduledoc """
  Variable-related logic.
  """
  alias Exshome.DataType
  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Event
  alias Exshome.SystemRegistry
  alias Exshome.Variable.VariableStateEvent

  use Lifecycle, key: :variable

  defstruct [:dependency, :id, :name, :ready?, :readonly?, :type]

  @type t() :: %__MODULE__{
          dependency: Dependency.dependency(),
          id: String.t(),
          name: String.t(),
          ready?: boolean(),
          readonly?: boolean(),
          type: DataType.t()
        }

  @callback set_value(DependencyState.t(), any()) :: DependencyState.t()

  @impl Lifecycle
  def init_lifecycle(%DependencyState{} = state) do
    %__MODULE__{} = variable_data = variable_from_dependency_state(state)

    :ok = SystemRegistry.register!(__MODULE__, variable_data.id, variable_data)

    :ok =
      Event.broadcast(%VariableStateEvent{
        data: variable_data,
        type: :created
      })

    state
  end

  @impl Lifecycle
  def init_state(%DependencyState{} = state), do: state

  @impl Lifecycle
  def handle_call({:set_value, value}, _from, %DependencyState{} = state) do
    state = Dependency.dependency_module(state.dependency).set_value(state, value)
    {:stop, {:ok, state}}
  end

  @impl Lifecycle
  def handle_stop(_reason, %DependencyState{} = state) do
    :ok =
      Event.broadcast(%VariableStateEvent{
        data: variable_from_dependency_state(state),
        type: :deleted
      })

    {:cont, state}
  end

  @impl Lifecycle
  def handle_value_change(%DependencyState{value: value} = state, old_value)
      when Dependency.NotReady in [value, old_value] do
    %__MODULE__{} = variable_data = variable_from_dependency_state(state)

    :ok =
      SystemRegistry.update_value!(
        __MODULE__,
        variable_data.id,
        fn _ -> variable_data end
      )

    :ok =
      Event.broadcast(%VariableStateEvent{
        data: variable_data,
        type: :updated
      })

    state
  end

  def handle_value_change(%DependencyState{} = state, _old_value), do: state

  @spec set_value!(Dependency.dependency(), any()) :: :ok
  def set_value!(dependency, value) do
    raise_if_not_variable!(dependency)

    if readonly?(dependency) do
      raise "Unable to set a value for #{inspect(dependency)}. It is readonly."
    end

    value = DataType.parse!(datatype(dependency), value)
    GenServerDependency.call(dependency, {:set_value, value})
  end

  @spec validate_value(Dependency.dependency(), value :: any()) ::
          {:ok, any()} | {:error, String.t()}
  def validate_value(dependency, value) do
    type = datatype(dependency)

    case DataType.try_parse_value(type, value) do
      {:ok, value} -> {:ok, value}
      _ -> {:error, "Invalid value #{inspect(value)} for #{DataType.name(type)}"}
    end
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    module
    |> get_config()
    |> NimbleOptions.validate!(
      readonly: [
        type: :boolean
      ],
      type: [
        type: :atom,
        required: true
      ]
    )
  end

  @spec readonly?(Dependency.dependency()) :: boolean()
  def readonly?(dependency) do
    dependency
    |> Dependency.dependency_module()
    |> get_config()
    |> Keyword.get(:readonly, false)
  end

  @spec datatype(Dependency.dependency()) :: DataType.t()
  def datatype(dependency) do
    dependency
    |> Dependency.dependency_module()
    |> get_config()
    |> Keyword.fetch!(:type)
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

  defp variable_from_dependency_state(%DependencyState{dependency: dependency, value: value}) do
    %__MODULE__{
      dependency: dependency,
      id: Dependency.dependency_id(dependency),
      name: Dependency.dependency_module(dependency).__config__[:name],
      ready?: value != Dependency.NotReady,
      readonly?: readonly?(dependency),
      type: datatype(dependency)
    }
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.Dependency.GenServerDependency
      use GenServerDependency, unquote(config)
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]
      alias Exshome.Variable
      register_hook_module(Variable)
      add_tag(Variable)

      @after_compile {Variable, :validate_module!}
      @behaviour Variable

      @impl Variable
      def set_value(%DependencyState{} = state, value) do
        module = Exshome.Dependency.dependency_module(state.dependency)

        raise """
        Received unexpected set_value #{inspect(value)},
        Please implement set_value/2 callback for #{module}
        """
      end

      defoverridable(set_value: 2)
    end
  end
end
