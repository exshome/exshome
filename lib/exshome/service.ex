defmodule Exshome.Service do
  @moduledoc """
  The module creates a process backed by `m:GenServer`.
  It creates basic operations and API for extensions.
  """

  use GenServer

  alias Exshome.BehaviourMapping
  alias Exshome.Behaviours.ServiceExtensionBehaviour
  alias Exshome.Emitter
  alias Exshome.Id
  alias Exshome.Service.ServiceState
  alias Exshome.Service.ServiceStateEvent
  alias Exshome.SystemRegistry

  @doc """
  Returns all services that belong to specific application.
  """
  @spec app_modules(module) :: MapSet.t(module())
  def app_modules(app) do
    service_modules = BehaviourMapping.behaviour_implementations(ServiceBehaviour)

    app_modules =
      Exshome.Mappings.ModuleByAppMapping
      |> BehaviourMapping.custom_mapping!()
      |> Map.fetch!(app)

    MapSet.intersection(service_modules, app_modules)
  end

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
  @spec update_private(ServiceState.t(), module(), (term() -> term())) :: ServiceState.t()
  def update_private(%ServiceState{} = state, module, function) do
    update_in(state.private[module], function)
  end

  @doc """
  Returns private data for specific module.
  """
  @spec get_private(state :: ServiceState.t(), module :: module()) :: term()
  def get_private(%ServiceState{private: private}, module), do: Map.fetch!(private, module)

  @spec update_value(state :: ServiceState.t(), update_fn :: (old_value :: term() -> term())) ::
          ServiceState.t()
  def update_value(%ServiceState{value: old_value} = state, update_fn) do
    new_value = update_fn.(old_value)
    state = %ServiceState{state | value: new_value}

    for module <- get_private(state, __MODULE__),
        function_exported?(module, :handle_value_change, 2),
        reduce: state do
      state -> module.handle_value_change(old_value, state)
    end
  end

  @spec update_data(state :: ServiceState.t(), update_fn :: (old_value :: term() -> term())) ::
          ServiceState.t()
  def update_data(%ServiceState{} = state, update_fn) do
    %ServiceState{state | data: update_fn.(state.data)}
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    {id, opts} = Map.pop!(opts, :id)

    module = Id.get_module(id)

    state =
      %ServiceState{id: id, module: module, opts: opts}
      |> update_private(__MODULE__, fn _ -> [] end)

    {:ok, state, {:continue, :init_extensions}}
  end

  @impl GenServer
  def handle_continue(:init_extensions, %ServiceState{} = state) do
    {:noreply, init_extensions(state), {:continue, :init_service}}
  end

  def handle_continue(:init_service, %ServiceState{} = state) do
    :ok = SystemRegistry.register!(__MODULE__, state.id, self())

    {:noreply, state.module.init(state), {:continue, :after_init}}
  end

  def handle_continue(:after_init, %ServiceState{} = state) do
    state =
      for ext <- get_private(state, __MODULE__),
          function_exported?(ext, :after_init, 1),
          reduce: state do
        old_state -> ext.after_init(old_state)
      end

    :ok =
      Emitter.broadcast(
        ServiceStateEvent,
        %ServiceStateEvent{id: state.id, state: :ready, pid: self()}
      )

    {:noreply, state}
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
    :ok =
      Emitter.broadcast(
        ServiceStateEvent,
        %ServiceStateEvent{id: state.id, state: :stopped, pid: self()}
      )

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

  @default_settings Application.compile_env(:exshome, [:hooks, __MODULE__], [])
  @spec init_extensions(ServiceState.t()) :: ServiceState.t()
  defp init_extensions(%ServiceState{} = state) do
    settings = state.module.service_settings(state.id) ++ @default_settings

    state =
      for {ext, config} <- settings, reduce: state do
        old_state ->
          :ok = ext.validate_config!(config)
          ext.init(old_state, config)
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
end
