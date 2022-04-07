defmodule ExshomeTest.App.Player.SocketTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  import ExshomeTest.Fixtures

  alias Exshome.App.Player.Socket

  @reconnect_interval 0

  setup do
    server = server_fixture()

    ExshomeTest.TestRegistry.start_dependency(Socket, %{
      on_event: event_handler(self()),
      reconnect_interval: @reconnect_interval
    })

    assert Exshome.Dependency.subscribe(Socket) == :connected

    %{server: server}
  end

  test "simple connection" do
    assert %{"test" => 123} == Socket.request!(%{data: "test"})
    assert last_received_message() == %{"data" => "test", "request_id" => 1}
  end

  test "received all messages" do
    Socket.request!(%{data: "test"})
    Socket.request!(%{data: "test"})
    assert length(received_messages()) == 2
  end

  test "request_id differs" do
    Socket.request!(%{data: "test"})
    message_1 = last_received_message()
    Socket.request!(%{data: "test"})
    message_2 = last_received_message()

    assert message_1["request_id"] < message_2["request_id"]
  end

  test "request fails" do
    respond_with_errors()
    assert {:error, _message} = Socket.request(%{data: "test"})
  end

  test "socket can receive event" do
    event = %{"event" => "some event", "data" => unique_integer()}
    send_event(event)
    assert received_event() == event
  end

  test "client reconnects to the server" do
    Socket.request!(%{data: "test"})
    assert last_received_message()

    stop_server()
    assert_receive({Socket, :disconnected})
    {:error, :not_connected} = Socket.request(%{data: "test"})

    :timer.sleep(@reconnect_interval + 1)

    server_fixture()
    assert_receive({Socket, :connected})
    Socket.request!(%{data: "test"})
    assert last_received_message()
  end

  test "client receives error when server goes down", %{
    server: server
  } do
    fatal_request_fn = fn _, _ ->
      Process.exit(server, :kill)
    end

    set_response_fn(fatal_request_fn)

    {:error, :not_connected} = Socket.request(%{data: "test"})
  end
end
