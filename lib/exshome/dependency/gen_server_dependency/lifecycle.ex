defmodule Exshome.Dependency.GenServerDependency.Lifecycle do
  @moduledoc """
  GenServerDependency lifecycle hooks.
  """
  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState

  @type default_response :: {:cont, DependencyState.t()} | {:stop, DependencyState.t()}
  @type handle_call_response ::
          {:cont, DependencyState.t()} | {:stop, {any(), DependencyState.t()}}

  @callback init_lifecycle(DependencyState.t()) :: DependencyState.t()
  @callback init_state(DependencyState.t()) :: DependencyState.t()
  @callback handle_call(any(), GenServer.from(), DependencyState.t()) :: handle_call_response()
  @callback handle_info(any(), DependencyState.t()) :: default_response()
  @callback handle_stop(any(), DependencyState.t()) :: default_response()
  @callback handle_value_change(DependencyState.t(), old_value :: any()) :: DependencyState.t()

  @optional_callbacks [
    handle_call: 3,
    handle_info: 2,
    handle_stop: 2
  ]

  @lifecycle_hooks :dependency_lifecycle_hooks

  defmacro register_hook_module(module) do
    quote do
      unless Module.has_attribute?(__MODULE__, unquote(@lifecycle_hooks)) do
        Module.register_attribute(__MODULE__, unquote(@lifecycle_hooks),
          accumulate: true,
          persist: true
        )
      end

      Module.put_attribute(__MODULE__, unquote(@lifecycle_hooks), unquote(module))
    end
  end

  @spec init_lifecycle(DependencyState.t()) :: DependencyState.t()
  def init_lifecycle(%DependencyState{} = state) do
    state
    |> hook_modules()
    |> Enum.reduce(state, fn module, old_state -> module.init_lifecycle(old_state) end)
  end

  @spec init_state(DependencyState.t()) :: DependencyState.t()
  def init_state(%DependencyState{} = state) do
    state
    |> hook_modules()
    |> Enum.reduce(state, fn module, old_state -> module.init_state(old_state) end)
  end

  @spec handle_call(any(), GenServer.from(), DependencyState.t()) :: handle_call_response()
  def handle_call(message, from, %DependencyState{} = state) do
    handle_hooks(
      state,
      &function_exported?(&1, :handle_call, 3),
      fn state, module -> module.handle_call(message, from, state) end
    )
  end

  @spec handle_info(any(), DependencyState.t()) :: default_response()
  def handle_info(message, %DependencyState{} = state) do
    handle_hooks(
      state,
      &function_exported?(&1, :handle_info, 2),
      fn state, module -> module.handle_info(message, state) end
    )
  end

  @spec handle_stop(any(), DependencyState.t()) :: default_response()
  def handle_stop(reason, %DependencyState{} = state) do
    handle_hooks(
      state,
      &function_exported?(&1, :handle_stop, 2),
      fn state, module -> module.handle_stop(reason, state) end
    )
  end

  @spec update_value(DependencyState.t(), update_fn :: (any() -> any())) :: DependencyState.t()
  def update_value(%DependencyState{} = state, update_fn) do
    old_value = state.value

    state = %DependencyState{state | value: update_fn.(old_value)}

    state
    |> hook_modules()
    |> Enum.reduce(
      state,
      fn module, old_state -> module.handle_value_change(old_state, old_value) end
    )
  end

  @spec update_data(DependencyState.t(), update_fn :: (any() -> any())) :: DependencyState.t()
  def update_data(%DependencyState{} = state, update_fn) do
    %DependencyState{state | data: update_fn.(state.data)}
  end

  defp hook_modules(%DependencyState{dependency: dependency}) do
    module = Dependency.dependency_module(dependency)

    :attributes
    |> module.__info__()
    |> Keyword.get_values(@lifecycle_hooks)
    |> List.flatten()
  end

  def handle_hooks(state, filter_fn, reduce_fn) do
    state
    |> hook_modules()
    |> Enum.filter(filter_fn)
    |> reduce_hooks(state, reduce_fn)
  end

  defp reduce_hooks([], %DependencyState{} = state, _fun), do: {:cont, state}

  defp reduce_hooks([module | modules], %DependencyState{} = state, fun) do
    case fun.(state, module) do
      {:cont, state} -> reduce_hooks(modules, state, fun)
      {:stop, _response} = result -> result
    end
  end

  defmacro __using__(key: key) when is_atom(key) do
    if key == :name, do: raise("Unable to create lifecycle with key #{inspect(key)}")

    quote do
      alias Exshome.Dependency.GenServerDependency.Lifecycle
      @behaviour Lifecycle

      @impl Lifecycle
      def init_lifecycle(%DependencyState{} = state), do: state

      @impl Lifecycle
      def handle_value_change(%DependencyState{} = state, _), do: state

      defoverridable(init_lifecycle: 1, handle_value_change: 2)

      def get_config(module) do
        module.__config__()
        |> Keyword.get(:hooks, [])
        |> Keyword.get(unquote(key), [])
      end
    end
  end
end
