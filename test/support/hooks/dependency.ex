defmodule ExshomeTest.Hooks.Dependency do
  @moduledoc """
  Custom hooks for dependencies.
  """

  def init(opts) do
    custom_init_hook = opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()
  end
end
