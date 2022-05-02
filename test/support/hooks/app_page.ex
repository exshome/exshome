defmodule ExshomeTest.Hooks.AppPage do
  @moduledoc """
  Custom hooks for app pages.
  """
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  def handle_info({Dependency, value}, _socket, original_result) do
    send(
      TestRegistry.get_parent(),
      {__MODULE__, Dependency, value}
    )

    original_result
  end

  def handle_info(_event, _socket, original_result), do: original_result
end
