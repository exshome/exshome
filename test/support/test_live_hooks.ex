defmodule ExshomeTest.TestLiveHooks do
  @moduledoc """
  Custom hooks for setting up the live view.
  """
  alias Phoenix.LiveView.Socket

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    owner_pid = socket.private.connect_info[:owner_pid]
    owner_pid && ExshomeTest.TestRegistry.allow(owner_pid, self())
    {:cont, socket}
  end
end
