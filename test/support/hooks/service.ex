defmodule ExshomeTest.Hooks.Service do
  @moduledoc """
  Adds common service operations for tests.
  """

  alias Exshome.Behaviours.ServiceExtensionBehaviour
  alias ExshomeTest.TestRegistry

  @behaviour ServiceExtensionBehaviour

  @impl ServiceExtensionBehaviour
  def validate_config!(_), do: :ok

  @impl ServiceExtensionBehaviour
  def init(state, _) do
    :ok =
      :"$ancestors"
      |> Process.get()
      |> List.last()
      |> TestRegistry.allow(self())

    state
  end
end
