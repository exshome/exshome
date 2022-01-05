defmodule Exshome.Service do
  @moduledoc """
  Generic Exshome service.
  """

  defmodule State do
    @moduledoc """
    A state for every service. It holds service options together with its value.
    """
    defstruct [:opts, :value]

    @type t() :: %__MODULE__{
            opts: any(),
            value: any()
          }
  end

  @callback parse_opts(map()) :: any()
  @callback update_value(State.t(), value :: any()) :: State.t()
  @callback on_init(State.t()) :: State.t()
  @callback on_call(term(), GenServer.from(), State.t()) :: any()

  @callback broadcast(value :: any()) :: :ok
  @callback subscribe(GenServer.server()) :: any()
  @callback unsubscribe() :: :ok
  @callback get_value(GenServer.server()) :: any()

  @spec start_link(module :: module(), opts :: map()) :: GenServer.on_start()
  def start_link(module, %{} = opts) do
    {name, opts} = Map.pop(opts, :name, nil)
    GenServer.start_link(module, opts, name: name)
  end

  @spec init(module(), any()) :: any()
  def init(module, opts) do
    opts = module.parse_opts(opts)
    state = %State{opts: opts, value: nil}
    {:ok, state, {:continue, :on_init}}
  end

  @init_hook_module Application.compile_env(:exshome, :service_init_hook_module)
  if @init_hook_module do
    defoverridable(init: 2)

    def init(module, opts) do
      result = super(module, opts)
      @init_hook_module.on_service_init(opts)
      result
    end
  end

  @spec handle_continue(module(), State.t()) :: any()
  def handle_continue(module, %State{} = state) do
    new_state = module.on_init(state)
    {:noreply, new_state}
  end

  @spec update_value(module(), State.t(), any()) :: State.t()
  def update_value(module, %State{} = state, value) do
    old_value = state.value

    if value != old_value do
      module.broadcast(value)
    end

    %State{state | value: value}
  end

  defmacro __using__(pubsub_key: key) do
    quote do
      use GenServer
      @behaviour unquote(__MODULE__)

      def start_link(opts) do
        unquote(__MODULE__).start_link(__MODULE__, opts)
      end

      @impl unquote(__MODULE__)
      def get_value(server \\ __MODULE__) do
        GenServer.call(get_service_pid(server), :get_value)
      end

      @impl GenServer
      def init(opts) do
        unquote(__MODULE__).init(__MODULE__, opts)
      end

      @impl GenServer
      def handle_continue(:on_init, state) do
        unquote(__MODULE__).handle_continue(__MODULE__, state)
      end

      @impl GenServer
      def handle_call(:get_value, _from, state) do
        {:reply, state.value, state}
      end

      def handle_call(request, from, state) do
        __MODULE__.on_call(request, from, state)
      end

      @impl unquote(__MODULE__)
      def parse_opts(opts), do: opts
      defoverridable(parse_opts: 1)

      @impl unquote(__MODULE__)
      def update_value(state, value) do
        unquote(__MODULE__).update_value(__MODULE__, state, value)
      end

      @impl unquote(__MODULE__)
      def on_call(_, _, _), do: raise("Not Implemented")
      defoverridable(on_call: 3)

      @impl unquote(__MODULE__)
      def on_init(%unquote(__MODULE__).State{} = state), do: state
      defoverridable(on_init: 1)

      @impl unquote(__MODULE__)
      def broadcast(value) do
        Exshome.PubSub.broadcast(unquote(key), {__MODULE__, value})
      end

      @impl unquote(__MODULE__)
      def subscribe(server \\ __MODULE__) do
        :ok = Exshome.PubSub.subscribe(unquote(key))
        __MODULE__.get_value(get_service_pid(server))
      end

      @impl unquote(__MODULE__)
      def unsubscribe, do: Exshome.PubSub.unsubscribe(unquote(key))

      defp get_service_pid(server) when is_pid(server), do: server

      defp get_service_pid(_server) do
        __MODULE__
      end

      if getter = Application.compile_env(:exshome, :service_pid_getter) do
        defoverridable(get_service_pid: 1)
        defdelegate get_service_pid(server), to: getter
      end
    end
  end
end
