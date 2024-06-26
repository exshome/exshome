defmodule ExshomePlayerTest.Services.MpvSocketTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  alias ExshomePlayer.Events.MpvEvent
  alias ExshomePlayer.Services.MpvSocket

  describe "default options" do
    setup do
      setup_with_opts(%{})
    end

    test "simple connection" do
      assert %{"test" => 123} == MpvSocket.request!(%{data: "test"})
      assert last_received_message() == %{"data" => "test", "request_id" => 1}
    end

    test "received all messages" do
      MpvSocket.request!(%{data: "test"})
      MpvSocket.request!(%{data: "test"})
      assert length(received_messages()) == 2
    end

    test "request_id differs" do
      MpvSocket.request!(%{data: "test"})
      message_1 = last_received_message()
      MpvSocket.request!(%{data: "test"})
      message_2 = last_received_message()

      assert message_1["request_id"] < message_2["request_id"]
    end

    test "request fails" do
      respond_with_errors()
      assert {:error, _message} = MpvSocket.request(%{data: "test"})
    end

    test "socket can receive event" do
      data = unique_integer()
      event_type = "event #{unique_integer()}"
      send_event(%{event: event_type, data: data})
      assert_receive_event({MpvEvent, {^event_type, %{"data" => ^data}}})
    end

    test "client receives error when server goes down", %{
      server: server
    } do
      fatal_request_fn = fn _, _ ->
        Process.exit(server, :kill)
      end

      set_response_fn(fatal_request_fn)

      {:error, :not_connected} = MpvSocket.request(%{data: "test"})
    end
  end

  describe "immediate reconnect interval" do
    @reconnect_interval 0

    setup do
      setup_with_opts(%{reconnect_interval: @reconnect_interval})
    end

    test "client reconnects to the server" do
      MpvSocket.request!(%{data: "test"})
      assert last_received_message()

      stop_server()
      wait_until_socket_disconnects()
      {:error, :not_connected} = MpvSocket.request(%{data: "test"})

      :timer.sleep(@reconnect_interval + 1)

      server_fixture()
      wait_until_socket_connects()
      MpvSocket.request!(%{data: "test"})
      assert last_received_message()
      stop_supervised!(MpvSocket)
    end
  end

  defp setup_with_opts(opts) do
    server = server_fixture()

    ExshomeTest.TestRegistry.start_service(MpvSocket, opts)

    assert Exshome.Dependency.get_and_subscribe(MpvSocket) == :connected
    Exshome.Emitter.subscribe(MpvEvent)

    %{server: server}
  end
end
