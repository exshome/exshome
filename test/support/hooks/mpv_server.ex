defmodule ExshomeTest.Hooks.MpvServer do
  @moduledoc """
  Custom hooks for testing MpvServer.
  """

  alias ExshomeTest.TestRegistry

  def set_mpv_executable_response(response) do
    TestRegistry.put(__MODULE__, response)
  end

  def find_mpv_executable do
    case TestRegistry.get(__MODULE__) do
      {:ok, value} -> value
      {:error, _} -> {:ok, "mpv"}
    end
  end

  def mpv_server_command(_program) do
    "sleep 100000"
  end
end
