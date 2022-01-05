defmodule ExshomeTest.TestHooks do
  @moduledoc """
  Custom hooks for setting up tests.
  """
  alias ExshomeTest.TestRegistry
  alias Phoenix.LiveView.Socket

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    owner_pid = socket.private.connect_info[:owner_pid]
    owner_pid && ExshomeTest.TestRegistry.allow(owner_pid, self())
    {:cont, socket}
  end

  def topic_name(topic) when is_binary(topic),
    do: "#{inspect(TestRegistry.get_parent())}_#{topic}"

  def get_service_pid(server) when is_pid(server), do: server

  def get_service_pid(server) when is_atom(server) do
    TestRegistry.get_service(server)
  end

  def on_service_init(opts) do
    custom_init_hook = opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()
  end
end
