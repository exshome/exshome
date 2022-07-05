defmodule ExshomeTest.Hooks.Variable do
  @moduledoc """
  Custom hooks for variables.
  """
  alias ExshomeTest.TestRegistry

  def registry_key(variable_id) do
    parent = TestRegistry.get_parent()
    {__MODULE__, parent, variable_id}
  end

  def lookup_key(variable_id) do
    parent = TestRegistry.get_parent()
    {__MODULE__, parent, variable_id}
  end
end
