defmodule ExshomeTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location, self())

    client_data = %{socket_location: socket_location, handle_event: event_handler(self())}

    client = start_supervised!({Exshome, client_data})

    %{client: client}
  end

  test "simple connection", %{client: client} do
    assert %{"test" => 123} == Exshome.send!(client, %{data: "test"})
    assert last_received_message() == %{"data" => "test", "request_id" => 1}
  end

  test "received all messages", %{client: client} do
    Exshome.send!(client, %{data: "test"})
    Exshome.send!(client, %{data: "test"})
    assert length(received_messages()) == 2
  end

  test "request_id differs", %{client: client} do
    Exshome.send!(client, %{data: "test"})
    message_1 = last_received_message()
    Exshome.send!(client, %{data: "test"})
    message_2 = last_received_message()

    assert message_1["request_id"] < message_2["request_id"]
  end

  test "client can receive event", %{client: _client} do
    event = %{"event" => "some event", "data" => unique_integer()}
    send_event(event)
    assert received_event() == event
  end
end
