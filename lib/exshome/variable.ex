defmodule Exshome.Variable do
  @moduledoc """
  This module represents generic API to use with variables.
  Each variable has own name, dependencies, datatype and value.
  It is also a dependency by itself, so you can subscribe to changes in variables.
  """
  use GenServer
  alias Exshome.Dependency
  alias Exshome.Dependency.State

  @callback update_value(State.t(), value :: any()) :: State.t()
  @callback handle_dependency_change(State.t()) :: State.t()

  @spec get_value(GenServer.server()) :: Dependency.get_value_result()
  def get_value(server) do
    Exshome.Service.get_value(server)
  end

  @spec start_link(opts :: map()) :: GenServer.on_start()
  def start_link(opts) do
    module = opts.module
    {name, opts} = Map.pop(opts, :name, module)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    {:ok, %State{module: opts[:module]}, {:continue, :connect_to_dependencies}}
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

  @hook_module Application.compile_env(:exshome, :dependency_hook_module)
  if @hook_module do
    defoverridable(init: 1)

    def init(opts) do
      result = super(opts)
      @hook_module.on_dependency_init(opts)
      result
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
      alias Exshome.Dependency.State
      use Exshome.Dependency
      use Exshome.Named, "variable_#{unquote(config)[:name]}"
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Variable)

      @behaviour Variable
      @after_compile __MODULE__

      def __config__, do: unquote(config)

      def __after_compile__(_env, _bytecode), do: Variable.validate_config(__MODULE__)

      @impl Variable
      defdelegate update_value(state, value), to: Variable

      @impl Exshome.Dependency
      def get_value, do: Variable.get_value(__MODULE__)

      def start_link(opts), do: opts |> update_opts() |> Variable.start_link()

      def child_spec(opts), do: opts |> update_opts() |> Variable.child_spec()

      defp update_opts(%{} = opts) do
        Map.merge(opts, %{module: __MODULE__})
      end
    end
  end
end
