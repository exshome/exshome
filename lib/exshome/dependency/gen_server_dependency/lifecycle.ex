defmodule Exshome.Dependency.GenServerDependency.Lifecycle do
  @moduledoc """
  GenServerDependency lifecycle hooks.
  """
  alias Exshome.Dependency.GenServerDependency.DependencyState

  @type default_response :: {:cont, DependencyState.t()} | {:stop, DependencyState.t()}
  @type handle_call_response ::
          {:cont, DependencyState.t()} | {:stop, {any(), DependencyState.t()}}

  @callback on_init(DependencyState.t()) :: DependencyState.t()
  @callback handle_call(any(), GenServer.from(), DependencyState.t()) :: handle_call_response()
  @callback handle_info(any(), DependencyState.t()) :: default_response()
  @callback handle_stop(any(), DependencyState.t()) :: default_response()

  @optional_callbacks [handle_call: 3, handle_info: 2, handle_stop: 2]

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

  @spec on_init(DependencyState.t()) :: DependencyState.t()
  def on_init(%DependencyState{} = state) do
    state
    |> hook_modules()
    |> Enum.reduce(state, fn module, old_state -> module.on_init(old_state) end)
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

  defp hook_modules(%DependencyState{module: module}) when is_atom(module) do
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
end
