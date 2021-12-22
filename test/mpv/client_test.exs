defmodule ExshomeTest.Mpv.ClientTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.Mpv.{Client, Socket}
  alias Exshome.Mpv.Client.PlayerState
  alias ExshomeTest.TestMpvServer

  @unknown_event :unknown_event

  setup do
    socket_location = unique_socket_location()
    server = server_fixture(socket_location)

    client_data = %Client.Arguments{
      socket_args: %Socket.Arguments{
        socket_location: socket_location,
        reconnect_interval: 0
      },
      player_state_change_fn: event_handler(self()),
      unknown_event_handler: event_handler(self(), @unknown_event)
    }

    client = start_supervised!({Client, client_data})
    assert_client_connected()
    %{client: client, socket_location: socket_location, server: server}
  end

  test "client can reconnect to a server", %{client: client, socket_location: socket_location} do
    assert Client.player_state(client) != :disconnected
    stop_server()

    assert received_event(:disconnected)
    assert Client.player_state(client) == :disconnected

    server_fixture(socket_location)
    assert_client_connected()
    assert Client.player_state(client) != :disconnected
  end

  test "client can switch tracks", %{client: client, server: server} do
    file_location = "test_file_#{unique_integer()}"
    Client.load_file(client, file_location)
    assert %PlayerState{path: ^file_location, pause: false} = Client.player_state(client)
    assert [file_location] == TestMpvServer.playlist(server)
    Client.pause(client)
    assert %PlayerState{pause: true} = Client.player_state(client)

    another_file = "another_file_#{unique_integer()}"
    Client.load_file(client, another_file)
    assert %PlayerState{path: ^another_file, pause: false} = Client.player_state(client)
    assert [another_file] == TestMpvServer.playlist(server)
  end

  test "client can set volume", %{client: client} do
    volume_level = unique_integer()
    Client.set_volume(client, volume_level)
    assert %PlayerState{volume: ^volume_level} = Client.player_state(client)
  end

  test "client can seek a file", %{client: client} do
    time_pos = unique_integer()
    Client.seek(client, time_pos)
    assert %PlayerState{time_pos: ^time_pos} = Client.player_state(client)
  end

  test "client can handle unexpected event", %{server: server} do
    event = "unexpected_event_#{unique_integer()}"
    TestMpvServer.send_event(server, %{event: event})
    assert received_unknown_event() == %{"event" => event}
  end

  defp assert_client_connected do
    updated_player_state()
  end

  defp received_unknown_event do
    assert_receive({@unknown_event, event})
    event
  end
end
