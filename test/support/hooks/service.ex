defmodule ExshomeTest.Hooks.Service do
  @moduledoc """
  Adds common service operations for tests.
  """

  alias Exshome.Service.ServiceExtensionBehaviour
  alias Exshome.Service.ServiceState
  alias ExshomeTest.TestRegistry

  @behaviour ServiceExtensionBehaviour

  @impl ServiceExtensionBehaviour
  def init(%ServiceState{opts: %{TestRegistry => parent_pid}} = state, _) do
    :ok = TestRegistry.allow(parent_pid, self())
    state
  end

  def init(state, _), do: state

  @impl ServiceExtensionBehaviour
  def after_init(%ServiceState{} = state) do
    TestRegistry.notify_ready()
    state
  end
end
