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

  defstruct [:dependency, :id, :name, :not_ready_reason, :ready?, :readonly?, :type, :validations]

  @type t() :: %__MODULE__{
          dependency: Dependency.dependency(),
          id: String.t(),
          name: String.t(),
          not_ready_reason: String.t() | nil,
          ready?: boolean(),
          readonly?: boolean(),
          type: DataType.t(),
          validations: %{atom() => any()}
        }

  @callback not_ready_reason(DependencyState.t()) :: String.t() | nil
  @callback set_value(DependencyState.t(), any()) :: DependencyState.t()

  @validations_key {__MODULE__, :validations}

  @impl Lifecycle
  def init_lifecycle(%DependencyState{} = state) do
    default_validations = load_default_validations(state)
    update_validations(state, fn _ -> default_validations end)
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
        data: get_variable_data(state),
        type: :deleted
      })

    {:cont, state}
  end

  @impl Lifecycle
  def handle_value_change(%DependencyState{} = state, _old_value) do
    update_variable_info(state)
  end

  @spec set_value(Dependency.dependency(), any()) :: :ok | {:error, String.t()}
  def set_value(dependency, value) do
    case validate_value(dependency, value) do
      {:ok, value} -> GenServerDependency.call(dependency, {:set_value, value})
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
      ],
      validate: [
        type: :keyword_list
      ]
    )
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

  @spec update_variable_info(DependencyState.t()) :: DependencyState.t()
  defp update_variable_info(%DependencyState{} = state) do
    %__MODULE__{} = variable_data = variable_from_dependency_state(state)

    old_data = Map.get(state.private, __MODULE__)

    case {old_data, variable_data} do
      {value, value} ->
        :ok

      {nil, _} ->
        :ok = SystemRegistry.register!(__MODULE__, variable_data.id, variable_data)

        broadcast_event(%VariableStateEvent{data: variable_data, type: :created})

      _ ->
        :ok =
          SystemRegistry.update_value!(__MODULE__, variable_data.id, fn _ -> variable_data end)

        broadcast_event(%VariableStateEvent{data: variable_data, type: :updated})
    end

    %DependencyState{
      state
      | private: Map.put(state.private, __MODULE__, variable_data)
    }
  end

  defp broadcast_event(%VariableStateEvent{} = event) do
    :ok = Event.broadcast(event)
    :ok = Event.broadcast(event, event.data.id)
  end

  defp get_variable_data(%DependencyState{private: private}), do: Map.fetch!(private, __MODULE__)

  defp variable_from_dependency_state(%DependencyState{dependency: dependency} = state) do
    module = Dependency.dependency_module(dependency)
    config = get_config(module)

    reason = not_ready_reason(state)

    %__MODULE__{
      dependency: dependency,
      id: Dependency.dependency_id(dependency),
      name: module.__config__[:name],
      ready?: !reason,
      not_ready_reason: reason,
      readonly?: Keyword.get(config, :readonly, false),
      type: Keyword.fetch!(config, :type),
      validations: get_validations(state)
    }
  end

  @spec get_validations(DependencyState.t()) :: map()
  defp get_validations(%DependencyState{} = state) do
    Map.fetch!(state.private, @validations_key)
  end

  @spec update_validations(DependencyState.t(), (map() -> map())) :: DependencyState.t()
  def update_validations(%DependencyState{} = state, update_fn) do
    private =
      state.private
      |> Map.put_new(@validations_key, %{})
      |> Map.update!(@validations_key, update_fn)

    update_variable_info(%DependencyState{
      state
      | private: private
    })
  end

  defp load_default_validations(%DependencyState{dependency: dependency}) do
    dependency
    |> Dependency.dependency_module()
    |> get_config()
    |> Keyword.get(:validate, [])
    |> Enum.into(%{})
  end

  defp not_ready_reason(%DependencyState{deps: deps, value: Dependency.NotReady}) do
    missing_deps = for {key, Dependency.NotReady} <- deps, do: key
    "Missing dependencies: #{inspect(missing_deps)}"
  end

  defp not_ready_reason(%DependencyState{dependency: dependency} = state) do
    Dependency.dependency_module(dependency).not_ready_reason(state)
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
      def not_ready_reason(_), do: nil

      @impl Variable
      def set_value(%DependencyState{} = state, value) do
        module = Exshome.Dependency.dependency_module(state.dependency)

        raise """
        Received unexpected set_value #{inspect(value)},
        Please implement set_value/2 callback for #{module}
        """
      end

      defoverridable(Variable)

      defdelegate update_validations(state, update_fn), to: Variable
    end
  end
end
