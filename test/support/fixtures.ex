defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  alias Exshome.MpvSocket
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

  @spec server_fixture(socket_path :: String.t()) :: term()
  def server_fixture(socket_path) do
    server =
      Callbacks.start_supervised!({
        TestMpvServer,
        %TestMpvServer.Arguments{socket_path: socket_path, test_pid: self()}
      })

    set_events([])
    set_test_server(server)
    server
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

  def respond_with_errors do
    TestMpvServer.set_response_fn(test_server(), fn request_id, _ ->
      %{request_id: request_id, error: "some error #{unique_integer()}"}
    end)
  end

  @spec wait_until_socket_disconnects(socket :: pid()) :: term()
  def wait_until_socket_disconnects(socket), do: wait_until_socket_connection(socket, false)

  @spec wait_until_socket_connects(socket :: pid()) :: term()
  def wait_until_socket_connects(socket), do: wait_until_socket_connection(socket, true)

  @spec wait_until_socket_connection(
          socket :: pid(),
          connected? :: boolean(),
          timeout :: integer()
        ) :: term()
  defp wait_until_socket_connection(socket, connected?, timeout \\ 100)

  defp wait_until_socket_connection(_socket, _connected?, timeout) when timeout <= 0 do
    ExUnit.Assertions.flunk("unable to wait until socket state changes")
  end

  defp wait_until_socket_connection(socket, connected?, timeout) do
    if MpvSocket.connected?(socket) != connected? do
      :timer.sleep(1)
      wait_until_socket_connection(socket, connected?, timeout - 1)
    end
  end
end
