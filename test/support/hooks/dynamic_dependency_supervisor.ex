defmodule ExshomeTest.Hooks.DynamicDependencySupervisor do
  @moduledoc """
  Custom hooks for dynamic dependency supervisor.
  """

  @spec supervisor_pid(module()) :: pid()
  def supervisor_pid(module) do
    ExshomeTest.TestRegistry.get!({__MODULE__, module})
  end

  @spec put_supervisor_pid(module(), pid()) :: :ok
  def put_supervisor_pid(module, pid) when is_pid(pid) do
    :ok = ExshomeTest.TestRegistry.put({__MODULE__, module}, pid)
  end

  @spec child_spec_for_id(map(), module(), String.t()) :: map()
  def child_spec_for_id(child_opts, _module, _id) do
    ExshomeTest.TestRegistry.prepare_child_opts(child_opts)
  end
end
