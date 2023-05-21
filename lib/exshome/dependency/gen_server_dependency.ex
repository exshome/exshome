defmodule Exshome.Dependency.GenServerDependency do
  @moduledoc """
  This module stores generic API for basic GenServer based dependencies.
  """
  use GenServer

  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Dependency.NotReady
  alias Exshome.SystemRegistry

  @callback on_init(DependencyState.t()) :: DependencyState.t()
  @callback update_data(DependencyState.t(), update_fn :: (any() -> any())) :: DependencyState.t()
  @callback update_value(DependencyState.t(), update_fn :: (any() -> any())) ::
              DependencyState.t()
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
  @callback handle_stop(reason :: term(), state :: DependencyState.t()) :: DependencyState.t()
  @optional_callbacks handle_info: 2, handle_call: 3

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(%{dependency: dependency} = opts) do
    {name, opts} = Map.pop(opts, :name, dependency)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl GenServer
  def init(opts) do
    Process.flag(:trap_exit, true)

    {dependency, opts} = Map.pop!(opts, :dependency)

    :ok = SystemRegistry.register!(__MODULE__, dependency, self())

    state =
      %DependencyState{dependency: dependency, deps: %{}, opts: opts}
      |> Lifecycle.init_lifecycle()
      |> Lifecycle.init_state()

    {:ok, state, {:continue, :on_init}}
  end

  @impl GenServer
  def handle_continue(:on_init, %DependencyState{} = state) do
    new_state = Dependency.get_module(state.dependency).on_init(state)

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(message, from, %DependencyState{} = state) do
    case Lifecycle.handle_call(message, from, state) do
      {:stop, {value, state}} ->
        {:reply, value, state}

      {:cont, state} ->
        Dependency.get_module(state.dependency).handle_call(message, from, state)
    end
  end

  @impl GenServer
  def handle_info(message, %DependencyState{} = state) do
    case Lifecycle.handle_info(message, state) do
      {:stop, state} -> {:noreply, state}
      {:cont, state} -> Dependency.get_module(state.dependency).handle_info(message, state)
    end
  end

  @impl GenServer
  def terminate(reason, %DependencyState{} = state) do
    {_, state} = Lifecycle.handle_stop(reason, state)
    Dependency.get_module(state.dependency).handle_stop(reason, state)
  end

  @spec get_pid(Dependency.dependency()) :: pid() | nil
  defp get_pid(dependency) do
    case SystemRegistry.get_by_id(__MODULE__, dependency) do
      {:ok, pid} -> pid
      _ -> nil
    end
  end

  @spec get_value(Dependency.dependency()) :: any()
  def get_value(dependency) do
    call(dependency, :get_value)
  end

  @spec call(Dependency.dependency(), any()) :: any()
  def call(dependency, message, timeout \\ default_timeout()) do
    case get_pid(dependency) do
      nil -> NotReady
      pid -> GenServer.call(pid, message, timeout)
    end
  end

  defp default_timeout, do: 5000

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

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{} = env, _bytecode) do
    validate_dependency_config!(env.module.__config__())
  end

  @doc """
  Validates configuration for the dependency and raises if it is invalid.
  Available configuration options:
  :name (required) - name of the dependency
  """
  @spec validate_dependency_config!(Keyword.t()) :: keyword()
  def validate_dependency_config!(config) do
    NimbleOptions.validate!(
      config,
      name: [
        type: :string,
        required: true
      ],
      child_module: [
        type: :atom
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
      alias Exshome.Dependency.GenServerDependency.Lifecycle
      alias Exshome.Dependency.NotReady
      use Exshome.Dependency.GenServerDependency.Subscription
      use Exshome.Dependency
      use Exshome.Named, "dependency:#{unquote(config[:name])}"
      import Exshome.Tag, only: [add_tag: 1]

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
          |> Keyword.split([:name, :child_module])
          |> then(fn {root_config, hooks} -> Keyword.put(root_config, :hooks, hooks) end)
        )
      end

      @impl Exshome.Dependency
      def get_value(dependency), do: GenServerDependency.get_value(dependency)

      @impl GenServerDependency
      def on_init(state), do: state

      @impl GenServerDependency
      def handle_stop(_reason, state), do: state

      defoverridable(on_init: 1, handle_stop: 2, get_value: 1)

      @impl GenServerDependency
      defdelegate update_value(state, value_fn), to: Lifecycle
      @impl GenServerDependency
      defdelegate update_data(state, data_fn), to: Lifecycle

      @impl Exshome.Dependency
      def type, do: Exshome.Dependency

      def get_child_module, do: unquote(Keyword.get(config, :child_module, __CALLER__.module))

      def call(message), do: GenServerDependency.call(__MODULE__, message)

      def start_link(opts), do: opts |> update_opts() |> GenServerDependency.start_link()

      def child_spec(opts) do
        %{dependency: dependency} = opts = update_opts(opts)

        opts
        |> GenServerDependency.child_spec()
        |> Map.merge(%{id: dependency})
      end

      defp update_opts(%{} = opts) do
        Map.put_new(opts, :dependency, __MODULE__)
      end
    end
  end
end
