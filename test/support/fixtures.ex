defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  alias ExshomeTest.TestMpvServer
  alias ExUnit.Callbacks
  import ExUnit.Assertions

  def unique_socket_location do
    System.tmp_dir!()
    |> Path.join("socket_location#{unique_integer()}")
  end

  def unique_integer do
    System.unique_integer([:positive, :monotonic])
  end

  def server_fixture(socket_path, test_pid) do
    server =
      Callbacks.start_supervised!({
        TestMpvServer,
        %{socket_path: socket_path, test_pid: test_pid}
      })

    set_events([])
    set_test_server(server)
  end

  def event_handler(test_pid) do
    fn event ->
      send(test_pid, {:event, event})
    end
  end

  @spec received_messages() :: [%{}]
  def received_messages do
    TestMpvServer.received_messages(test_server())
  end

  def last_received_message do
    [message | _] = received_messages()
    message
  end

  def received_event do
    assert_receive({:event, event})
    event
  end

  def send_event(event) do
    TestMpvServer.send_event(test_server(), event)
  end

  defp test_server do
    Process.get(TestMpvServer)
  end

  defp set_test_server(server) do
    Process.put(TestMpvServer, server)
  end

  defp set_events(events) do
    Process.put(:events, events)
  end
end
