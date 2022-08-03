defmodule Exshome.Variable.GenServerVariable do
  @moduledoc """
  Common blocks for building gen-server variables.
  """

  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Variable

  use Lifecycle, key: :variable

  @callback not_ready_reason(DependencyState.t()) :: String.t() | nil
  @callback handle_set_value(DependencyState.t(), any()) :: DependencyState.t()
  @callback variable_from_dependency_state(DependencyState.t()) :: Variable.t()

  @validations_key {__MODULE__, :validations}

  @spec set_value(Dependency.dependency(), any()) :: :ok | {:error, String.t()}
  def set_value(dependency, value) do
    GenServerDependency.call(dependency, {:set_value, value})
  end

  @impl Lifecycle
  def init_lifecycle(%DependencyState{} = state) do
    default_validations = load_default_validations(state)
    update_validations(state, fn _ -> default_validations end)
  end

  @impl Lifecycle
  def init_state(%DependencyState{} = state), do: state

  @impl Lifecycle
  def handle_call({:set_value, value}, _from, %DependencyState{} = state) do
    state = Dependency.dependency_module(state.dependency).handle_set_value(state, value)
    {:stop, {:ok, state}}
  end

  def handle_call(_, _, %DependencyState{} = state), do: {:cont, state}

  @impl Lifecycle
  def handle_stop(_reason, %DependencyState{} = state) do
    :ok =
      state
      |> get_variable_data()
      |> Variable.remove_variable_data()

    {:cont, state}
  end

  @impl Lifecycle
  def handle_value_change(%DependencyState{} = state, _old_value) do
    update_variable_info(state)
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    module
    |> get_config()
    |> NimbleOptions.validate!(
      group: [
        type: :string,
        required: true
      ],
      readonly?: [
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

  @spec update_variable_info(DependencyState.t()) :: DependencyState.t()
  defp update_variable_info(%DependencyState{} = state) do
    %Variable{} =
      variable_data =
      Dependency.dependency_module(state.dependency).variable_from_dependency_state(state)

    old_data = Map.get(state.private, __MODULE__)

    case {old_data, variable_data} do
      {value, value} ->
        :ok

      {nil, _} ->
        :ok = Variable.register_variable_data(variable_data)

      _ ->
        :ok = Variable.update_variable_data(variable_data)
    end

    %DependencyState{
      state
      | private: Map.put(state.private, __MODULE__, variable_data)
    }
  end

  defp get_variable_data(%DependencyState{private: private}), do: Map.fetch!(private, __MODULE__)

  def variable_from_dependency_state(%DependencyState{dependency: dependency} = state) do
    module = Dependency.dependency_module(dependency)
    config = get_config(module)

    %Variable{
      dependency: dependency,
      id: Dependency.dependency_id(dependency),
      name: module.__config__[:name],
      group: Keyword.fetch!(config, :group),
      not_ready_reason: not_ready_reason(state),
      can_delete?: false,
      can_rename?: false,
      readonly?: Keyword.get(config, :readonly?, false),
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

    if Enum.any?(missing_deps) do
      "Missing dependencies: #{inspect(missing_deps)}"
    else
      "Variable has not started yet"
    end
  end

  defp not_ready_reason(%DependencyState{dependency: dependency} = state) do
    Dependency.dependency_module(dependency).not_ready_reason(state)
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.Variable.GenServerVariable
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]
      register_hook_module(GenServerVariable)
      alias Exshome.Variable

      @after_compile {GenServerVariable, :validate_module!}
      @behaviour GenServerVariable

      @impl GenServerVariable
      def not_ready_reason(_), do: nil

      @impl GenServerVariable
      def handle_set_value(%DependencyState{} = state, value) do
        module = Exshome.Dependency.dependency_module(state.dependency)

        raise """
        Received unexpected handle_set_value #{inspect(value)},
        Please implement handle_set_value/2 callback for #{module}
        """
      end

      @impl GenServerVariable
      defdelegate variable_from_dependency_state(state), to: GenServerVariable

      defoverridable(GenServerVariable)

      defdelegate update_validations(state, update_fn), to: GenServerVariable

      @impl Variable
      defdelegate set_value(dependency, value), to: GenServerVariable
    end
  end
end
