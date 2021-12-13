defmodule ExshomeTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location, self())
    client = start_supervised!({Exshome, socket_location})

    %{client: client}
  end

  test "simple connection", %{client: client} do
    assert %{"test" => 123} == Exshome.send!(client, %{data: "test"})
    assert received_message() == %{"data" => "test", "request_id" => 1}
  end

  test "received all messages", %{client: client} do
    Exshome.send!(client, %{data: "test"})
    Exshome.send!(client, %{data: "test"})
    assert length(received_messages()) == 2
  end

  test "request_id differs", %{client: client} do
    Exshome.send!(client, %{data: "test"})
    message_1 = received_message()
    Exshome.send!(client, %{data: "test"})
    message_2 = received_message()

    assert message_1["request_id"] < message_2["request_id"]
  end
end
