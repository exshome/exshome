defmodule Exshome.Service do
  @moduledoc """
  The module creates a process backed by `m:GenServer`.
  It creates basic operations and API for extensions.
  """

  defmodule NotReady do
    @moduledoc """
    Shows that service is not ready.
    """
  end

  defmodule State do
    @moduledoc """
    Inner state of each service.
    """

    defstruct [
      :id,
      :data,
      :module,
      private: %{}
    ]

    @type t() :: %__MODULE__{
            id: Exshome.Id.t(),
            data: term(),
            module: module(),
            private: map()
          }
  end

  defmodule ServiceBehaviour do
    @moduledoc """
    Generic behaviour for each service.
    """
    @type settings_t() :: [{module(), Keyword.t()}]

    @callback service_settings(Exshome.Id.t()) :: settings_t()
    @callback not_ready_value() :: term()
    @callback init(State.t()) :: State.t()
    @callback handle_info(message :: term(), State.t()) ::
                {:noreply, new_state}
                | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:stop, reason :: term(), new_state}
              when new_state: State.t()
    @callback handle_call(request :: term(), GenServer.from(), state :: State.t()) ::
                {:reply, reply, new_state}
                | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:noreply, new_state}
                | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
                | {:stop, reason, reply, new_state}
                | {:stop, reason, new_state}
              when reply: term(), new_state: State.t(), reason: term()
    @callback handle_stop(reason :: term(), state :: State.t()) :: State.t()
    @optional_callbacks handle_info: 2, handle_call: 3
  end

  defmodule ServiceExtensionBehaviour do
    @moduledoc """
    Generic service extension operations.
    """
    @type default_response() :: {:cont, State.t()} | {:stop, State.t()}
    @type call_response() :: {:cont, State.t()} | {:stop, {term(), State.t()}}
    @type response() :: default_response() | call_response()

    @doc """
    Configures extension. You can validate settings here.
    This function runs in the `GenServer.init/1`, so it is better to return fast from it.
    """
    @callback configure_extension!(State.t(), ServiceBehaviour.settings_t()) :: term()

    @doc """
    Runs after the service has already started, but the module was not inited yet.
    """
    @callback before_init(State.t()) :: State.t()

    @callback handle_call(message :: term(), from :: GenServer.from(), state :: State.t()) ::
                call_response()
    @callback handle_info(message :: term(), state :: State.t()) :: default_response()
    @callback handle_stop(message :: term(), state :: State.t()) :: default_response()
  end

  use GenServer

  alias Exshome.Id
  alias Exshome.SystemRegistry

  @doc """
  Starts a new process and links it to a caller.
  """
  @spec start_link(map()) :: GenServer.on_start()
  def start_link(%{id: id} = opts) do
    {name, opts} = Map.pop(opts, :name, id)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Updates private data for specific module.
  This is useful to store extension settings.
  """
  @spec update_private(State.t(), module(), function()) :: State.t()
  def update_private(%State{} = state, module, function) do
    update_in(state.private[module], function)
  end

  @doc """
  Returns private data for specific module.
  """
  @spec get_private(state :: State.t(), module :: module()) :: term()
  def get_private(%State{private: private}, module), do: Map.fetch!(private, module)

  @impl GenServer
  def init(%{id: id}) do
    Process.flag(:trap_exit, true)

    :ok = SystemRegistry.register!(__MODULE__, id, self())

    module = Id.get_module(id)

    state = prepare_lifecycle(%State{id: id, module: module})

    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %State{module: module} = state) do
    state_with_extensions =
      for extension <- get_private(state, __MODULE__), reduce: state do
        old_state -> extension.before_init(old_state)
      end

    new_state = module.init(state_with_extensions)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(message, from, %State{} = state) do
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
  def handle_info(message, %State{} = state) do
    filter_fn = &function_exported?(&1, :handle_info, 2)
    reduce_fn = fn state, extension -> extension.handle_call(message, state) end

    case handle_hooks(state, filter_fn, reduce_fn) do
      {:stop, state} -> {:noreply, state}
      {:cont, state} -> state.module.handle_info(message, state)
    end
  end

  @impl GenServer
  def terminate(reason, %State{} = state) do
    filter_fn = &function_exported?(&1, :handle_stop, 2)
    reduce_fn = fn state, extension -> extension.handle_stop(reason, state) end

    {_, state} = handle_hooks(state, filter_fn, reduce_fn)
    state.module.handle_stop(reason, state)
  end

  @spec call(id :: Id.t(), message :: term()) :: term()
  def call(id, message, timeout \\ default_timeout()) do
    case get_pid(id) do
      nil -> Id.get_module(id).not_ready_value()
      pid -> GenServer.call(pid, message, timeout)
    end
  end

  @spec default_timeout() :: integer()
  defp default_timeout, do: 5000

  @spec get_pid(Id.t()) :: pid() | nil
  defp get_pid(id) do
    case SystemRegistry.get_by_id(__MODULE__, id) do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  @spec prepare_lifecycle(State.t()) :: State.t()
  defp prepare_lifecycle(%State{} = state) do
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

  @typep reduce_fn_t() :: (State.t(), module() -> ServiceExtensionBehaviour.response())
  @spec handle_hooks(
          state :: State.t(),
          filter_fn :: (module() -> boolean()),
          reduce_fn :: reduce_fn_t()
        ) :: ServiceExtensionBehaviour.response()
  defp handle_hooks(%State{} = state, filter_fn, reduce_fn) do
    state
    |> get_private(__MODULE__)
    |> Enum.filter(filter_fn)
    |> reduce_hooks(state, reduce_fn)
  end

  @spec reduce_hooks(extensions :: [module()], state :: State.t(), reduce_fn :: reduce_fn_t()) ::
          ServiceExtensionBehaviour.response()
  defp reduce_hooks([], %State{} = state, _fun), do: {:cont, state}

  defp reduce_hooks([extension | extensions], %State{} = state, fun) do
    case fun.(state, extension) do
      {:cont, state} -> reduce_hooks(extensions, state, fun)
      {:stop, _response} = result -> result
    end
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(init: 1, default_timeout: 0)
    defdelegate default_timeout(), to: @hook_module

    def init(opts) do
      @hook_module.init(opts)
      result = super(opts)
      result
    end
  end
end
