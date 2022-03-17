defmodule Exshome.Variable do
  @moduledoc """
  This module represents generic API to use with variables.
  Each variable has own name, dependencies, datatype and value.
  It is also a dependency by itself, so you can subscribe to changes in variables.
  """
  use GenServer
  alias Exshome.Dependency

  defmodule State do
    @moduledoc """
    This module represents inner state for each variable.
    """
    defstruct [:module, deps: %{}, value: Exshome.Dependency.NotReady]

    @type t() :: %__MODULE__{
            module: module(),
            value: Exshome.Dependency.get_value_result(),
            deps: map()
          }
  end

  @callback update_value(State.t(), value :: any()) :: State.t()
  @callback handle_dependency_change(State.t()) :: State.t()

  @spec get_value(module()) :: Exshome.Dependency.get_value_result()
  def get_value(module) do
    GenServer.call(module, :get_value)
  end

  @spec start_link(module()) :: GenServer.on_start()
  def start_link(module) do
    GenServer.start_link(__MODULE__, module, name: module)
  end

  @impl GenServer
  def init(module) do
    {:ok, %State{module: module}, {:continue, :connect_to_dependencies}}
  end

  @impl GenServer
  def handle_continue(:connect_to_dependencies, %State{} = state) do
    dependencies = state.module.__config__()[:dependencies]

    deps =
      for {dependency, key} <- dependencies, into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    state =
      %State{state | deps: deps}
      |> handle_dependency_change()

    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:get_value, _from, %State{} = state) do
    {:reply, state.value, state}
  end

  @impl GenServer
  def handle_info({dependency, value}, %State{} = state) do
    key =
      state.module.__config__()[:dependencies]
      |> Keyword.fetch!(dependency)

    state =
      put_in(state.deps[key], value)
      |> handle_dependency_change()

    {:noreply, state}
  end

  @spec update_value(State.t(), value :: any()) :: State.t()
  def update_value(%State{} = state, value) do
    old_value = state.value

    if value != old_value do
      Dependency.broadcast_value(state.module, value)
    end

    %State{state | value: value}
  end

  @spec handle_dependency_change(State.t()) :: State.t()
  def handle_dependency_change(%State{deps: deps} = state) do
    missing_dependencies =
      deps
      |> Map.values()
      |> Enum.any?(&(&1 == Dependency.NotReady))

    if missing_dependencies do
      update_value(state, Dependency.NotReady)
    else
      state.module.handle_dependency_change(state)
    end
  end

  @doc """
  Validates configuration for the variable and raises if they are invalid.
  Available configuration options:
  :name (required) - name of the variable
  :datatype (required) - datatype for the variable
  :dependencies (default %{}) - dependencies of the variable
  """
  @spec validate_config(module()) :: keyword()
  def validate_config(module) do
    NimbleOptions.validate!(
      module.__config__(),
      name: [
        type: :string,
        required: true
      ],
      datatype: [
        type: :atom,
        required: true
      ],
      dependencies: [
        type: :keyword_list,
        keys: [
          *: [
            type: :atom
          ]
        ]
      ]
    )
  end

  defmacro __using__(config) do
    quote do
      alias unquote(__MODULE__)
      alias Variable.State
      use Exshome.Dependency
      use Exshome.Named, "variable_#{unquote(config)[:name]}"
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Variable)

      @behaviour Variable
      @after_compile __MODULE__

      def __config__(), do: unquote(config)

      def __after_compile__(_env, _bytecode), do: Variable.validate_config(__MODULE__)

      @impl Variable
      defdelegate update_value(state, value), to: Variable

      @impl Exshome.Dependency
      def get_value, do: Variable.get_value(__MODULE__)

      def start_link(_opts), do: Variable.start_link(__MODULE__)

      def child_spec(_opts), do: Variable.child_spec(__MODULE__)
    end
  end
end
