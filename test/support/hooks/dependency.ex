defmodule ExshomeTest.Hooks.Dependency do
  @moduledoc """
  Custom hooks for dependencies.
  """

  alias ExshomeTest.TestRegistry

  def dependency_key(dependency) do
    parent = TestRegistry.get_parent()
    {__MODULE__, parent, dependency}
  end

  def init(opts) do
    custom_init_hook = opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()
  end
end
