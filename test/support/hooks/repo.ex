defmodule ExshomeTest.Hooks.Repo do
  @moduledoc """
  Custom hooks for testing Ecto.
  """

  def put_dynamic_repo(repo), do: ExshomeTest.TestRegistry.put(__MODULE__, repo)

  def get_dynamic_repo, do: ExshomeTest.TestRegistry.get!(__MODULE__)

  @spec tests_started?() :: boolean()
  def tests_started?, do: ExshomeTest.TestRegistry.started?()
end
