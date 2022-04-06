defmodule Exshome.Dependency.GenServerDependency do
  @moduledoc """
  This module stores generic API for GenServer based dependencies.
  """
  alias Exshome.Dependency

  defmodule State do
    @moduledoc """
    Inner state for each dependency.
    """

    defstruct [:module, :opts, :deps, :data, value: Dependency.NotReady]

    @type t() :: %__MODULE__{
            module: module(),
            value: Exshome.Dependency.get_value_result(),
            data: any(),
            opts: any(),
            deps: map()
          }
  end

  @spec start_link(module(), map()) :: GenServer.on_start()
  def start_link(module, opts) do
    callback_module = opts.module
    {name, opts} = Map.pop(opts, :name, callback_module)
    GenServer.start_link(module, opts, name: name)
  end

  @spec get_pid(atom() | pid()) :: pid() | nil
  defp get_pid(server) when is_atom(server), do: Process.whereis(server)

  defp get_pid(server) when is_pid(server) do
    if Process.alive?(server), do: server, else: nil
  end

  @spec on_init(map()) :: any()
  def on_init(_opts) do
    Process.flag(:trap_exit, true)
  end

  @spec get_value(GenServer.server()) :: any()
  def get_value(server) do
    case get_pid(server) do
      nil -> Dependency.NotReady
      pid -> GenServer.call(pid, :get_value)
    end
  end

  @spec update_value(State.t(), value :: any()) :: State.t()
  def update_value(%State{} = state, value) do
    old_value = state.value

    if value != old_value do
      Dependency.broadcast_value(state.module, value)
    end

    %State{state | value: value}
  end

  @spec handle_dependency_change(State.t()) :: State.t()
  def handle_dependency_change(%State{deps: deps} = state) do
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

  @spec handle_dependency_info(any(), State.t()) :: State.t()
  def handle_dependency_info({dependency, value}, %State{} = state) do
    key =
      state.module.__config__()[:dependencies]
      |> Keyword.fetch!(dependency)

    put_in(state.deps[key], value)
    |> handle_dependency_change()
  end

  @spec subscribe_to_dependencies(State.t(), Enumerable.t()) :: State.t()
  def subscribe_to_dependencies(%State{} = state, dependencies) do
    deps =
      for {dependency, key} <- dependencies, into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    handle_dependency_change(%State{state | deps: deps})
  end

  @spec terminate(State.t()) :: any()
  def terminate(%State{module: module}) do
    Dependency.broadcast_value(module, Dependency.NotReady)
  end

  @hook_module Application.compile_env(:exshome, :dependency_hook_module)
  if @hook_module do
    defoverridable(get_pid: 1)
    defdelegate get_pid(server), to: @hook_module
    defoverridable(on_init: 1)

    def on_init(opts) do
      result = super(opts)
      @hook_module.on_init(opts)
      result
    end
  end
end
