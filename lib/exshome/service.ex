defmodule Exshome.Service do
  @moduledoc """
  Generic Exshome service.
  """
  use GenServer
  alias Exshome.Dependency
  alias Exshome.Dependency.State

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
    case Dependency.get_pid(server) do
      nil -> Dependency.NotReady
      pid -> GenServer.call(pid, :get_value)
    end
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

  @hook_module Application.compile_env(:exshome, :dependency_hook_module)
  if @hook_module do
    defoverridable(init: 1)

    def init(opts) do
      result = super(opts)
      @hook_module.on_dependency_init(opts)
      result
    end
  end

  defmacro __using__(name: name) do
    quote do
      alias unquote(__MODULE__)
      alias Exshome.Dependency.State
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
      def on_init(%State{} = state), do: state
      defoverridable(on_init: 1)
    end
  end
end
