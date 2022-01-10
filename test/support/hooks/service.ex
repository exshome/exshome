defmodule ExshomeTest.Hooks.Service do
  @moduledoc """
  Custom hooks for service startup.
  """

  alias ExshomeTest.TestRegistry
  def get_service_pid(server) when is_pid(server), do: server

  def get_service_pid(server) when is_atom(server) do
    TestRegistry.get_service(server)
  end

  def on_service_init(opts) do
    custom_init_hook = opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()
  end
end
