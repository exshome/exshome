defmodule ExshomeTest.Hooks.LiveView do
  @moduledoc """
  Custom hooks for setting up tests.
  """
  alias ExshomeTest.TestRegistry
  alias Phoenix.LiveView.Socket

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    owner_pid =
      if socket.parent_pid do
        TestRegistry.get_parent(socket.parent_pid)
      else
        socket.private.connect_info[:owner_pid]
      end

    not_rendered_in_owner_process = owner_pid != self()
    valid_owner_pid = owner_pid && not_rendered_in_owner_process

    valid_owner_pid && TestRegistry.allow(owner_pid, self())
    {:cont, socket}
  end
end
