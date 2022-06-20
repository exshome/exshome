defmodule ExshomeTest.Hooks.Repo do
  @moduledoc """
  Custom hooks for testing Ecto.
  """

  def put_dynamic_repo(repo) do
    case ExshomeTest.TestRegistry.get(__MODULE__) do
      # Dynamic repo is already set up
      {:ok, _} -> :ok
      # No dynamic repo, setting up a new one
      {:error, _} -> ExshomeTest.TestRegistry.put(__MODULE__, repo)
    end
  end

  def get_dynamic_repo, do: ExshomeTest.TestRegistry.get!(__MODULE__)

  @spec tests_started?() :: boolean()
  def tests_started?, do: ExshomeTest.TestRegistry.started?()
end
