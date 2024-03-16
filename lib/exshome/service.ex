defmodule Exshome.Service do
  @moduledoc """
  The module creates a process backed by `m:GenServer`.
  It creates basic operations and API for extensions.
  """

  defmodule ServiceState do
    @moduledoc """
    Inner state of each service.
    """

    defstruct [
      :id,
      :data,
      :module,
      :opts,
      private: %{}
    ]

    @type t() :: %__MODULE__{
            id: Exshome.Id.t(),
            data: term(),
            module: module(),
            opts: term(),
            private: map()
          }
  end

  defmodule ServiceBehaviour do
    @moduledoc """
    Generic behaviour for each service.
    """
    @type settings_t() :: [{module(), Keyword.t()}]

    @callback start_link(opts :: map()) :: GenServer.on_start()
    @callback service_settings(Exshome.Id.t()) :: settings_t()
    @callback not_ready_value() :: term()
    @callback init(ServiceState.t()) :: ServiceState.t()
    @callback handle_info(message :: term(), ServiceState.t()) ::
                {:noreply, new_state}
                | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:stop, reason :: term(), new_state}
              when new_state: ServiceState.t()
    @callback handle_call(request :: term(), GenServer.from(), state :: ServiceState.t()) ::
                {:reply, reply, new_state}
                | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:noreply, new_state}
                | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:stop, reason, reply, new_state}
                | {:stop, reason, new_state}
              when reply: term(), new_state: ServiceState.t(), reason: term()
    @callback handle_stop(reason :: term(), state :: ServiceState.t()) :: ServiceState.t()
    @optional_callbacks start_link: 1, handle_info: 2, handle_call: 3
  end

  defmodule ServiceExtensionBehaviour do
    @moduledoc """
    Generic service extension operations.
    """
    @type default_response() :: {:cont, ServiceState.t()} | {:stop, ServiceState.t()}
    @type call_response() :: {:cont, ServiceState.t()} | {:stop, {term(), ServiceState.t()}}
    @type response() :: default_response() | call_response()

    @doc """
    Configures extension. You can validate settings here.
    This function runs in the `GenServer.init/1`, so it is better to return fast from it.
    """
    @callback configure_extension!(ServiceState.t(), ServiceBehaviour.settings_t()) :: term()

    @doc """
    Runs after the service has already started, but the module was not inited yet.
    """
    @callback before_init(ServiceState.t()) :: ServiceState.t()
    @doc """
    Runs after the service has already started, and the module is already initiated itself.
    """
    @callback after_init(ServiceState.t()) :: ServiceState.t()

    @callback handle_call(message :: term(), from :: GenServer.from(), state :: ServiceState.t()) ::
                call_response()
    @callback handle_info(message :: term(), state :: ServiceState.t()) :: default_response()
    @callback handle_stop(message :: term(), state :: ServiceState.t()) :: default_response()

    @optional_callbacks [
      before_init: 1,
      after_init: 1,
      handle_call: 3,
      handle_info: 2,
      handle_stop: 2
    ]
  end

  defmodule DependencyServiceBehaviour do
    @moduledoc """
    Features related to the DependencyService.
    """

    alias Exshome.Service.ServiceState

    @callback handle_dependency_change(dependencies :: map(), state :: ServiceState.t()) ::
                ServiceState.t()

    @optional_callbacks [handle_dependency_change: 2]
  end

  defmodule DependencyService do
    @moduledoc """
    Depencency backed by the service.
    """

    alias Exshome.Dependency
    alias Exshome.Emitter
    alias Exshome.Id
    alias Exshome.Service
    alias Exshome.Service.ServiceExtensionBehaviour
    alias Exshome.Service.ServiceState

    defstruct [:config, :deps, :value, :dependency_mapping]

    @type t() :: %__MODULE__{
            config: keyword(),
            deps: %{atom() => Dependency.value()},
            dependency_mapping: %{Id.t() => [atom()]},
            value: Dependency.value()
          }

    @behaviour ServiceExtensionBehaviour

    @impl ServiceExtensionBehaviour
    def configure_extension!(%ServiceState{}, config) do
      %__MODULE__{
        config: config,
        deps: %{},
        dependency_mapping: Enum.group_by(config, &elem(&1, 1), &elem(&1, 0)),
        value: Dependency.NotReady
      }
    end

    @impl ServiceExtensionBehaviour
    def before_init(%ServiceState{} = state) do
      %__MODULE__{} = settings = Service.get_private(state, __MODULE__)

      deps = Dependency.change_deps([], settings.config, settings.deps)

      Service.update_private(state, __MODULE__, &%__MODULE__{&1 | deps: deps})
    end

    @impl ServiceExtensionBehaviour
    def after_init(%ServiceState{} = state) do
      maybe_process_dependency_updates(state)
    end

    @impl ServiceExtensionBehaviour
    def handle_call({__MODULE__, :get_value}, _, %ServiceState{} = state) do
      %__MODULE__{value: value} = Service.get_private(state, __MODULE__)
      {:stop, {value, state}}
    end

    def handle_call(_, _, %ServiceState{} = state), do: {:cont, state}

    @impl ServiceExtensionBehaviour
    def handle_info({Dependency, {id, value}}, %ServiceState{} = state) do
      %__MODULE__{dependency_mapping: mapping, deps: deps} =
        Service.get_private(state, __MODULE__)

      if Map.has_key?(mapping, id) do
        updates = Map.from_keys(mapping[id], value)
        deps = Map.merge(deps, updates)

        state =
          state
          |> Service.update_private(__MODULE__, &%__MODULE__{&1 | deps: deps})
          |> maybe_process_dependency_updates()

        {:stop, state}
      else
        {:cont, state}
      end
    end

    def handle_info(_, _, %ServiceState{} = state), do: {:cont, state}

    @doc """
    Gets a value of the service.
    """
    @spec get_value(Id.t()) :: term()
    def get_value(id), do: Service.call(id, {__MODULE__, :get_value})

    @spec update_value(state :: ServiceState.t(), update_fn :: (old_value :: term() -> term())) ::
            ServiceState.t()
    def update_value(%ServiceState{} = state, update_fn) do
      Service.update_private(state, __MODULE__, fn %__MODULE__{value: old_value} = prev ->
        new_value = update_fn.(old_value)

        if old_value != new_value do
          :ok = Emitter.broadcast(state.id, new_value)
          %__MODULE__{prev | value: new_value}
        else
          prev
        end
      end)
    end

    @spec maybe_process_dependency_updates(ServiceState.t()) :: ServiceState.t()
    defp maybe_process_dependency_updates(%ServiceState{} = state) do
      %__MODULE__{deps: deps} = Service.get_private(state, __MODULE__)
      missing_deps = Enum.any?(deps, fn {_, value} -> value == Dependency.NotReady end)

      if missing_deps || Enum.empty?(deps) do
        state
      else
        state.module.handle_dependency_change(deps, state)
      end
    end

    defmacro __using__(config) do
      quote do
        alias Exshome.Service.DependencyServiceBehaviour
        alias Exshome.Service.ServiceBehaviour
        alias Exshome.Service.ServiceState

        import Exshome.Service.DependencyService, only: [update_value: 2]

        @behaviour Exshome.Behaviours.NamedBehaviour
        @impl Exshome.Behaviours.NamedBehaviour
        def get_name, do: unquote("dependency:#{Keyword.fetch!(config, :name)}")

        @behaviour Exshome.Behaviours.EmitterBehaviour
        @impl Exshome.Behaviours.EmitterBehaviour
        def emitter_type, do: Exshome.Dependency

        @behaviour Exshome.Behaviours.GetValueBehaviour
        @impl Exshome.Behaviours.GetValueBehaviour
        def get_value(id), do: DependencyService.get_value(id)

        @behaviour Exshome.Behaviours.BelongsToAppBehaviour
        @impl Exshome.Behaviours.BelongsToAppBehaviour
        def app, do: unquote(Keyword.fetch!(config, :app))

        @behaviour ServiceBehaviour

        @impl ServiceBehaviour
        def init(state), do: state

        @impl ServiceBehaviour
        def service_settings(_id) do
          [
            {
              Exshome.Service.DependencyService,
              unquote(Keyword.get(config, :dependencies, []))
            }
          ]
        end

        @impl ServiceBehaviour
        def not_ready_value, do: Exshome.Dependency.NotReady

        @impl ServiceBehaviour
        def handle_stop(_reason, %ServiceState{} = state), do: state

        defoverridable ServiceBehaviour

        @behaviour DependencyServiceBehaviour

        def child_spec(%{} = opts) do
          opts = Map.put_new(opts, :id, __MODULE__)

          %{
            id: opts.id,
            start: {Exshome.Service, :start_link, [opts]}
          }
        end
      end
    end
  end

  use GenServer

  alias Exshome.Id
  alias Exshome.SystemRegistry

  @doc """
  Starts a new process and links it to a caller.
  """
  @spec start_link(map()) :: GenServer.on_start()
  def start_link(%{} = opts) do
    {name, opts} = Map.pop(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Updates private data for specific module.
  This is useful to store extension settings.
  """
  @spec update_private(ServiceState.t(), module(), function()) :: ServiceState.t()
  def update_private(%ServiceState{} = state, module, function) do
    update_in(state.private[module], function)
  end

  @doc """
  Returns private data for specific module.
  """
  @spec get_private(state :: ServiceState.t(), module :: module()) :: term()
  def get_private(%ServiceState{private: private}, module), do: Map.fetch!(private, module)

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    {id, opts} = Map.pop!(opts, :id)

    :ok = SystemRegistry.register!(__MODULE__, id, self())

    module = Id.get_module(id)

    state = prepare_lifecycle(%ServiceState{id: id, module: module, opts: opts})

    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %ServiceState{module: module} = state) do
    extensions = get_private(state, __MODULE__)

    state_before_init =
      for ext <- extensions, function_exported?(ext, :before_init, 1), reduce: state do
        old_state -> ext.before_init(old_state)
      end

    state_after_module_init = module.init(state_before_init)

    state_after_init =
      for ext <- extensions,
          function_exported?(ext, :after_init, 1),
          reduce: state_after_module_init do
        old_state -> ext.after_init(old_state)
      end

    {:noreply, state_after_init}
  end

  @impl GenServer
  def handle_call(message, from, %ServiceState{} = state) do
    filter_fn = &function_exported?(&1, :handle_call, 3)
    reduce_fn = fn state, extension -> extension.handle_call(message, from, state) end

    case handle_hooks(state, filter_fn, reduce_fn) do
      {:stop, {value, state}} ->
        {:reply, value, state}

      {:cont, state} ->
        state.module.handle_call(message, from, state)
    end
  end

  @impl GenServer
  def handle_info(message, %ServiceState{} = state) do
    filter_fn = &function_exported?(&1, :handle_info, 2)
    reduce_fn = fn state, extension -> extension.handle_info(message, state) end

    case handle_hooks(state, filter_fn, reduce_fn) do
      {:stop, state} -> {:noreply, state}
      {:cont, state} -> state.module.handle_info(message, state)
    end
  end

  @impl GenServer
  def terminate(reason, %ServiceState{} = state) do
    filter_fn = &function_exported?(&1, :handle_stop, 2)
    reduce_fn = fn state, extension -> extension.handle_stop(reason, state) end

    {_, state} = handle_hooks(state, filter_fn, reduce_fn)
    state.module.handle_stop(reason, state)
  end

  @spec call(id :: Id.t(), message :: term()) :: term()
  def call(id, message, timeout \\ Exshome.Config.default_timeout()) do
    case get_pid(id) do
      nil -> Id.get_module(id).not_ready_value()
      pid -> GenServer.call(pid, message, timeout)
    end
  end

  @spec get_pid(Id.t()) :: pid() | nil
  defp get_pid(id) do
    case SystemRegistry.get_by_id(__MODULE__, id) do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  @spec prepare_lifecycle(ServiceState.t()) :: ServiceState.t()
  defp prepare_lifecycle(%ServiceState{} = state) do
    settings = state.module.service_settings(state.id)

    state =
      for {extension, config} <- settings, reduce: state do
        state ->
          extension_data = extension.configure_extension!(state, config)
          update_private(state, extension, fn _ -> extension_data end)
      end

    extensions = Keyword.keys(settings)
    update_private(state, __MODULE__, fn _ -> extensions end)
  end

  @typep reduce_fn_t() :: (ServiceState.t(), module() -> ServiceExtensionBehaviour.response())
  @spec handle_hooks(
          state :: ServiceState.t(),
          filter_fn :: (module() -> boolean()),
          reduce_fn :: reduce_fn_t()
        ) :: ServiceExtensionBehaviour.response()
  defp handle_hooks(%ServiceState{} = state, filter_fn, reduce_fn) do
    state
    |> get_private(__MODULE__)
    |> Enum.filter(filter_fn)
    |> reduce_hooks(state, reduce_fn)
  end

  @spec reduce_hooks(
          extensions :: [module()],
          state :: ServiceState.t(),
          reduce_fn :: reduce_fn_t()
        ) ::
          ServiceExtensionBehaviour.response()
  defp reduce_hooks([], %ServiceState{} = state, _fun), do: {:cont, state}

  defp reduce_hooks([extension | extensions], %ServiceState{} = state, fun) do
    case fun.(state, extension) do
      {:cont, state} -> reduce_hooks(extensions, state, fun)
      {:stop, _response} = result -> result
    end
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(init: 1)

    def init(opts) do
      @hook_module.init(opts)
      result = super(opts)
      result
    end
  end
end
