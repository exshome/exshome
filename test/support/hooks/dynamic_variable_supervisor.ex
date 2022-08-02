defmodule ExshomeTest.Hooks.DynamicVariableSupervisor do
  @moduledoc """
  Custom hooks for dynamic variable supervisor.
  """

  @spec supervisor_pid() :: pid()
  def supervisor_pid do
    ExshomeTest.TestRegistry.get!(__MODULE__)
  end

  @spec put_supervisor_pid(pid()) :: :ok
  def put_supervisor_pid(pid) when is_pid(pid) do
    :ok = ExshomeTest.TestRegistry.put(__MODULE__, pid)
  end

  @spec child_spec_for_id(map(), String.t()) :: map()
  def child_spec_for_id(child_opts, _id) do
    ExshomeTest.TestRegistry.prepare_child_opts(child_opts)
  end
end
