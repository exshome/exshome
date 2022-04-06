defmodule ExshomeTest.Hooks.MpvServer do
  @moduledoc """
  Custom hooks for testing MpvServer.
  """

  def mpv_server_command do
    "sleep 100000"
  end
end
