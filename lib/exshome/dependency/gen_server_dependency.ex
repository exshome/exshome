defmodule Exshome.Dependency.GenServerDependency do
  @moduledoc """
  This module stores generic API for GenServer based dependencies.
  """
  use GenServer

  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle

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

    state = Lifecycle.on_init(%DependencyState{module: module, deps: %{}, opts: opts})

    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %DependencyState{} = state) do
    new_state = state.module.on_init(state)
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(message, from, %DependencyState{} = state) do
    case Lifecycle.handle_call(message, from, state) do
      {:stop, {value, state}} -> {:reply, value, state}
      {:cont, state} -> state.module.handle_call(message, from, state)
    end
  end

  @impl GenServer
  def handle_info(message, %DependencyState{} = state) do
    case Lifecycle.handle_info(message, state) do
      {:stop, state} -> {:noreply, state}
      {:cont, state} -> state.module.handle_info(message, state)
    end
  end

  @impl GenServer
  def terminate(reason, %DependencyState{} = state) do
    Lifecycle.handle_stop(reason, state)
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
    validate_dependency_config!(env.module.__config__())
  end

  @doc """
  Validates configuration for the dependency and raises if it is invalid.
  Available configuration options:
  :name (required) - name of the dependency
  :dependencies (default []) - dependencies list
  :events (default []) - events to subscribe, where key is a module, and value is a topic
  """
  @spec validate_dependency_config!(Keyword.t()) :: keyword()
  def validate_dependency_config!(config) do
    NimbleOptions.validate!(
      config,
      name: [
        type: :string,
        required: true
      ],
      hooks: [
        type: :keyword_list
      ]
    )
  end

  @spec modules(app :: atom()) :: MapSet.t(Dependency.dependency())
  def modules(app) when is_atom(app) do
    Map.get(
      Exshome.Tag.tag_mapping(),
      {__MODULE__, app},
      MapSet.new()
    )
  end

  defmacro __using__(config) do
    quote do
      require Logger
      alias Exshome.Dependency.GenServerDependency
      alias Exshome.Dependency.GenServerDependency.DependencyState
      use Exshome.Dependency.GenServerDependency.Subscription
      use Exshome.Dependency
      use Exshome.Named, "dependency:#{unquote(config[:name])}"

      app_module =
        __MODULE__
        |> Module.split()
        |> Enum.slice(0..0)
        |> Module.safe_concat()

      add_tag({GenServerDependency, app_module})

      @after_compile {GenServerDependency, :validate_module!}
      @behaviour GenServerDependency

      def __config__ do
        unquote(
          config
          |> Keyword.pop!(:name)
          |> then(fn {name, hooks} -> [name: name, hooks: hooks] end)
        )
      end

      @impl Exshome.Dependency
      def get_value, do: GenServerDependency.get_value(__MODULE__)

      @impl GenServerDependency
      def on_init(state), do: state

      defoverridable(on_init: 1)

      def call(message), do: GenServerDependency.call(__MODULE__, message)

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
