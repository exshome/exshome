defmodule ExshomeTest.Hooks.SystemRegistry do
  @moduledoc """
  Custom hooks for SystemRegistry.
  """
  alias ExshomeTest.TestRegistry

  def registry_key(module, variable_id) do
    parent = TestRegistry.get_parent()
    {module, parent, variable_id}
  end
end
