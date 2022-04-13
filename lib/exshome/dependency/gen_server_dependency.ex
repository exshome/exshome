defmodule Exshome.Dependency.GenServerDependency do
  @moduledoc """
  This module stores generic API for GenServer based dependencies.
  """
  use GenServer

  alias Exshome.Dependency
  alias Exshome.Event

  defmodule DependencyState do
    @moduledoc """
    Inner state for each dependency.
    """

    defstruct [:module, :opts, :deps, :data, value: Dependency.NotReady]

    @type t() :: %__MODULE__{
            module: module(),
            deps: map(),
            data: any(),
            opts: any(),
            value: Dependency.value()
          }
  end

  @callback parse_opts(map()) :: any()
  @callback update_value(DependencyState.t(), value :: any()) :: DependencyState.t()
  @callback handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  @callback handle_event(Event.event_message(), DependencyState.t()) :: DependencyState.t()
  @callback on_init(DependencyState.t()) :: DependencyState.t()
  @callback handle_info(message :: any(), DependencyState.t()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: DependencyState.t()
  @callback handle_call(request :: term(), GenServer.from(), state :: DependencyState.t()) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason, reply, new_state}
              | {:stop, reason, new_state}
            when reply: term(), new_state: DependencyState.t(), reason: term()
  @optional_callbacks handle_info: 2, handle_call: 3

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(%{module: module} = opts) do
    {name, opts} = Map.pop(opts, :name, module)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    {module, opts} = Map.pop!(opts, :module)

    parsed_opts = module.parse_opts(opts)

    dependencies = module.__config__()[:dependencies] || []
    events = module.__config__()[:events] || []

    state =
      %DependencyState{module: module, deps: %{}, opts: parsed_opts}
      |> subscribe_to_dependencies(dependencies)
      |> subscribe_to_events(events)

    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %DependencyState{} = state) do
    new_state = state.module.on_init(state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:get_value, _from, %DependencyState{} = state) do
    {:reply, state.value, state}
  end

  @impl GenServer
  def handle_call(message, from, %DependencyState{} = state) do
    state.module.handle_call(message, from, state)
  end

  @impl GenServer
  def handle_info({Dependency, message}, %DependencyState{} = state) do
    {:noreply, handle_dependency_info(message, state)}
  end

  @impl GenServer
  def handle_info({Event, event}, %DependencyState{} = state) do
    new_state = state.module.handle_event(event, state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info(message, %DependencyState{} = state) do
    state.module.handle_info(message, state)
  end

  @impl GenServer
  def terminate(_reason, %DependencyState{module: module}) do
    Dependency.broadcast_value(module, Dependency.NotReady)
  end

  @spec get_pid(atom() | pid()) :: pid() | nil
  defp get_pid(server) when is_atom(server), do: Process.whereis(server)

  defp get_pid(server) when is_pid(server) do
    if Process.alive?(server), do: server, else: nil
  end

  @spec get_value(GenServer.server()) :: any()
  def get_value(server) do
    call(server, :get_value)
  end

  @spec call(GenServer.server(), any()) :: any()
  def call(server, message) do
    case get_pid(server) do
      nil -> Dependency.NotReady
      pid -> GenServer.call(pid, message)
    end
  end

  @spec update_value(DependencyState.t(), value :: any()) :: DependencyState.t()
  def update_value(%DependencyState{} = state, value) do
    old_value = state.value

    if value != old_value do
      Dependency.broadcast_value(state.module, value)
    end

    %DependencyState{state | value: value}
  end

  @spec update_data(DependencyState.t(), (any() -> any())) :: DependencyState.t()
  def update_data(%DependencyState{} = state, update_fn) do
    %DependencyState{state | data: update_fn.(state.data)}
  end

  @spec handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  def handle_dependency_change(%DependencyState{deps: deps} = state) do
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

  @spec handle_dependency_info(any(), DependencyState.t()) :: DependencyState.t()
  def handle_dependency_info({dependency, value}, %DependencyState{} = state) do
    key =
      state.module.__config__()[:dependencies]
      |> Keyword.fetch!(dependency)

    put_in(state.deps[key], value)
    |> handle_dependency_change()
  end

  @spec subscribe_to_dependencies(DependencyState.t(), Enumerable.t()) :: DependencyState.t()
  def subscribe_to_dependencies(%DependencyState{} = state, dependencies) do
    deps =
      for {dependency, key} <- dependencies, into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    state = %DependencyState{state | deps: deps}

    if Enum.empty?(deps) do
      state
    else
      handle_dependency_change(state)
    end
  end

  @spec subscribe_to_events(DependencyState.t(), Enumerable.t()) :: DependencyState.t()
  def subscribe_to_events(%DependencyState{} = state, events) do
    for {event_module, topic} <- events do
      :ok = Event.subscribe(event_module, topic)
    end

    state
  end

  @hook_module Application.compile_env(:exshome, :dependency_hook_module)
  if @hook_module do
    defoverridable(get_pid: 1)
    defdelegate get_pid(server), to: @hook_module
    defoverridable(init: 1)

    def init(opts) do
      @hook_module.init(opts)
      result = super(opts)
      result
    end
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{} = env, _bytecode) do
    validate_config!(env.module.__config__())
  end

  @doc """
  Validates configuration for the dependency and raises if it is invalid.
  Available configuration options:
  :name (required) - name of the dependency
  :dependencies (default []) - dependencies list
  :events (default []) - events to subscribe, where key is a module, and value is a topic
  """
  @spec validate_config!(Keyword.t()) :: keyword()
  def validate_config!(config) do
    NimbleOptions.validate!(
      config,
      name: [
        type: :string,
        required: true
      ],
      dependencies: [
        type: :keyword_list,
        keys: [
          *: [
            type: :atom
          ]
        ]
      ],
      events: [
        type: :keyword_list,
        keys: [
          *: [
            type: :string
          ]
        ]
      ]
    )
  end

  defmacro __using__(config) do
    quote do
      require Logger
      alias unquote(__MODULE__)
      alias unquote(__MODULE__).DependencyState
      use Exshome.Dependency
      use Exshome.Named, "dependency:#{unquote(config[:name])}"

      @after_compile {GenServerDependency, :validate_module!}
      @behaviour GenServerDependency

      def __config__, do: unquote(config)

      @impl GenServerDependency
      defdelegate update_value(state, value), to: GenServerDependency
      defdelegate update_data(state, data_fn), to: GenServerDependency

      @impl Exshome.Dependency
      def get_value, do: GenServerDependency.get_value(__MODULE__)

      @impl GenServerDependency
      def parse_opts(opts), do: opts
      @impl GenServerDependency
      def on_init(state), do: state

      @impl GenServerDependency
      def handle_dependency_change(state) do
        Logger.warn("""
        Some module dependency changed.
        Please implement handle_dependency_change/1 callback for #{state.module}
        """)

        state
      end

      @impl GenServerDependency
      def handle_event(event, %DependencyState{} = state) do
        Logger.warn("""
        Received unexpected event #{inspect(event)},
        Please implement handle_event/2 callback for #{state.module}
        """)

        state
      end

      defoverridable(parse_opts: 1, on_init: 1, handle_dependency_change: 1, handle_event: 2)

      def call(message), do: GenServerDependency.call(__MODULE__, message)

      def broadcast_event(topic, event),
        do: Exshome.Event.broadcast_event(__MODULE__, topic, event)

      def start_link(opts), do: opts |> update_opts() |> GenServerDependency.start_link()

      def child_spec(opts) do
        opts
        |> update_opts()
        |> GenServerDependency.child_spec()
        |> Map.merge(%{id: __MODULE__})
      end

      defp update_opts(%{} = opts) do
        Map.merge(opts, %{module: __MODULE__})
      end
    end
  end
end
