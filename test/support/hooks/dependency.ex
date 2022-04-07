defmodule ExshomeTest.Hooks.Dependency do
  @moduledoc """
  Custom hooks for dependencies.
  """

  alias ExshomeTest.TestRegistry

  def get_pid(server) when is_pid(server), do: server

  def get_pid(server) when is_atom(server) do
    TestRegistry.get_dependency_pid(server)
  end

  def init(opts) do
    custom_init_hook = opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()
  end
end
