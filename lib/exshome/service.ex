defmodule Exshome.Service do
  @moduledoc """
  Generic Exshome service.
  """
  use GenServer
  alias Exshome.Dependency.GenServerDependency
  alias Exshome.Dependency.GenServerDependency.State

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
    GenServerDependency.start_link(__MODULE__, opts)
  end

  @spec child_spec(opts :: map()) :: map()
  def child_spec(%{module: module} = opts) do
    %{super(opts) | id: module}
  end

  @impl GenServer
  def init(opts) do
    GenServerDependency.on_init(opts)
    {module, opts} = Map.pop!(opts, :module)
    parsed_opts = module.parse_opts(opts)
    state = %State{opts: parsed_opts, module: module}
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

  @impl GenServer
  def terminate(_reason, state), do: GenServerDependency.terminate(state)

  defmacro __using__(name: name) do
    quote do
      alias unquote(__MODULE__)
      alias Exshome.Dependency.GenServerDependency
      alias Exshome.Dependency.GenServerDependency.State
      use Exshome.Dependency
      use Exshome.Named, "service:#{unquote(name)}"
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Service)

      @behaviour Service

      def start_link(opts), do: opts |> update_opts() |> Service.start_link()

      def child_spec(opts), do: opts |> update_opts() |> Service.child_spec()

      defp update_opts(%{} = opts) do
        Map.merge(opts, %{module: __MODULE__})
      end

      @impl Exshome.Dependency
      def get_value, do: GenServerDependency.get_value(__MODULE__)

      @impl Service
      def parse_opts(opts), do: opts
      defoverridable(parse_opts: 1)

      @impl Service
      defdelegate update_value(state, value), to: GenServerDependency

      @impl Service
      def on_init(%State{} = state), do: state
      defoverridable(on_init: 1)
    end
  end
end
