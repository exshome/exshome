defmodule ExshomeTest.Mpv.SocketTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.Mpv.Socket

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location)

    socket_data = %Socket.Arguments{
      socket_location: socket_location,
      handle_event: event_handler(self()),
      reconnect_interval: 1
    }

    socket = start_supervised!({Socket, socket_data})

    %{socket: socket, socket_location: socket_location}
  end

  test "simple connection", %{socket: socket} do
    assert %{"test" => 123} == Socket.request!(socket, %{data: "test"})
    assert last_received_message() == %{"data" => "test", "request_id" => 1}
  end

  test "received all messages", %{socket: socket} do
    Socket.request!(socket, %{data: "test"})
    Socket.request!(socket, %{data: "test"})
    assert length(received_messages()) == 2
  end

  test "request_id differs", %{socket: socket} do
    Socket.request!(socket, %{data: "test"})
    message_1 = last_received_message()
    Socket.request!(socket, %{data: "test"})
    message_2 = last_received_message()

    assert message_1["request_id"] < message_2["request_id"]
  end

  test "request fails", %{socket: socket} do
    respond_with_errors()
    assert {:error, _message} = Socket.request(socket, %{data: "test"})
  end

  test "socket can receive event", %{socket: socket} do
    wait_until_socket_connects(socket)
    assert length(received_events()) > 0
    event = %{"event" => "some event", "data" => unique_integer()}
    send_event(event)
    assert received_event() == event
  end

  test "client reconnects to the server", %{
    socket: socket,
    socket_location: socket_location
  } do
    Socket.request!(socket, %{data: "test"})
    assert last_received_message()

    stop_server()
    wait_until_socket_disconnects(socket)
    {:error, :not_connected} = Socket.request(socket, %{data: "test"})

    server_fixture(socket_location)
    wait_until_socket_connects(socket)
    Socket.request!(socket, %{data: "test"})
    assert last_received_message()
  end
end
