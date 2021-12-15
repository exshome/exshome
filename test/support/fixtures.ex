defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  alias ExshomeTest.TestMpvServer
  alias ExUnit.Callbacks
  import ExUnit.Assertions

  @received_event_tag :event

  @spec unique_socket_location() :: String.t()
  def unique_socket_location do
    System.tmp_dir!()
    |> Path.join("socket_location#{unique_integer()}")
  end

  @spec unique_integer() :: integer()
  def unique_integer do
    System.unique_integer([:positive, :monotonic])
  end

  @spec server_fixture(socket_path:: String.t(), test_pid :: pid()) :: term()
  def server_fixture(socket_path, test_pid) do
    server =
      Callbacks.start_supervised!({
        TestMpvServer,
        %TestMpvServer.Arguments{socket_path: socket_path, test_pid: test_pid}
      })

    set_events([])
    set_test_server(server)
  end

  @spec event_handler(pid()) :: fun()
  def event_handler(test_pid) do
    fn event ->
      send(test_pid, {@received_event_tag, event})
    end
  end

  @spec received_messages() :: [%{}]
  def received_messages do
    TestMpvServer.received_messages(test_server())
  end

  @spec last_received_message() :: %{}
  def last_received_message do
    [message | _] = received_messages()
    message
  end

  @spec received_event() :: %{}
  def received_event do
    assert_receive({@received_event_tag, event})
    event
  end

  @spec send_event(%{}) :: %{}
  def send_event(event) do
    TestMpvServer.send_event(test_server(), event)
  end

  @spec test_server() :: pid()
  defp test_server do
    Process.get(TestMpvServer) || raise "Test server not found"
  end

  @spec set_test_server(pid()) :: term()
  defp set_test_server(server) do
    Process.put(TestMpvServer, server)
  end

  @spec set_events([%{}]) :: term()
  defp set_events(events) do
    Process.put(:events, events)
  end
end
