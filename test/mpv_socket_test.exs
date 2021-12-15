defmodule ExshomeTest.MpvSocketTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.MpvSocket

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location, self())

    socket_data = %MpvSocket.Arguments{
      socket_location: socket_location,
      handle_event: event_handler(self())
    }

    socket = start_supervised!({MpvSocket, socket_data})

    %{socket: socket}
  end

  test "simple connection", %{socket: socket} do
    assert %{"test" => 123} == MpvSocket.send!(socket, %{data: "test"})
    assert last_received_message() == %{"data" => "test", "request_id" => 1}
  end

  test "received all messages", %{socket: socket} do
    MpvSocket.send!(socket, %{data: "test"})
    MpvSocket.send!(socket, %{data: "test"})
    assert length(received_messages()) == 2
  end

  test "request_id differs", %{socket: socket} do
    MpvSocket.send!(socket, %{data: "test"})
    message_1 = last_received_message()
    MpvSocket.send!(socket, %{data: "test"})
    message_2 = last_received_message()

    assert message_1["request_id"] < message_2["request_id"]
  end

  test "request fails", %{socket: socket} do
    respond_with_errors()
    assert {:error, _message} = MpvSocket.send(socket, %{data: "test"})
  end

  test "socket can receive event" do
    event = %{"event" => "some event", "data" => unique_integer()}
    send_event(event)
    assert received_event() == event
  end
end
