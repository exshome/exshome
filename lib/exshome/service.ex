defmodule Exshome.Service do
  @moduledoc """
  Generic Exshome service.
  """
  use GenServer
  alias Exshome.Dependency

  defmodule State do
    @moduledoc """
    A state for every service. It holds service options together with its value.
    """
    defstruct [:opts, :value, :module]

    @type t() :: %__MODULE__{
            module: module(),
            opts: any(),
            value: any()
          }
  end

  @callback parse_opts(map()) :: any()
  @callback update_value(State.t(), value :: any()) :: State.t()
  @callback on_init(State.t()) :: State.t()
  @callback handle_info(message :: any(), State.t()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: State.t()
  @optional_callbacks handle_info: 2

  @spec start_link(opts :: map()) :: GenServer.on_start()
  def start_link(opts) do
    module = opts.module
    {name, opts} = Map.pop(opts, :name, module)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @spec get_value(GenServer.server()) :: any()
  def get_value(server) do
    GenServer.call(get_service_pid(server), :get_value)
  end

  @impl GenServer
  def init(opts) do
    {module, opts} = Map.pop!(opts, :module)
    parsed_opts = module.parse_opts(opts)
    state = %State{opts: parsed_opts, value: nil, module: module}
    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %State{} = state) do
    new_state = state.module.on_init(state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:get_value, _from, state) do
    {:reply, state.value, state}
  end

  @impl GenServer
  def handle_info(message, %State{} = state) do
    state.module.handle_info(message, state)
  end

  @spec update_value(State.t(), any()) :: State.t()
  def update_value(%State{} = state, value) do
    old_value = state.value

    if value != old_value do
      Dependency.broadcast_value(state.module, value)
    end

    %State{state | value: value}
  end

  defp get_service_pid(server) when is_pid(server), do: server

  defp get_service_pid(server) when is_atom(server) do
    server
  end

  @hook_module Application.compile_env(:exshome, :service_hook_module)
  if @hook_module do
    defoverridable(init: 1)

    def init(opts) do
      result = super(opts)
      @hook_module.on_service_init(opts)
      result
    end

    defoverridable(get_service_pid: 1)
    defdelegate get_service_pid(server), to: @hook_module
  end

  defmacro __using__(name: name) do
    quote do
      alias unquote(__MODULE__)
      use Exshome.Dependency
      use Exshome.Named, unquote(name)
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Service)

      @behaviour Service

      @doc "Starts a service."
      def start_link(opts) do
        opts |> update_opts() |> Service.start_link()
      end

      @doc "Returns a child spec for the service."
      def child_spec(opts) do
        opts |> update_opts() |> Service.child_spec()
      end

      defp update_opts(%{} = opts) do
        Map.merge(opts, %{module: __MODULE__})
      end

      @impl Exshome.Dependency
      def get_value, do: Service.get_value(__MODULE__)

      @impl Service
      def parse_opts(opts), do: opts
      defoverridable(parse_opts: 1)

      @doc "Returns a current value of the service."
      @impl Service
      defdelegate update_value(state, value), to: Service

      @doc "Run callbacks on service init."
      @impl Service
      def on_init(%Service.State{} = state), do: state
      defoverridable(on_init: 1)
    end
  end
end
