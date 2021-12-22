defmodule ExshomeTest.Mpv.ClientTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.Mpv.{Client, Socket}
  alias Exshome.Mpv.Client.PlayerState
  alias ExshomeTest.TestMpvServer

  setup do
    socket_location = unique_socket_location()
    server = server_fixture(socket_location)

    client_data = %Client.Arguments{
      socket_args: %Socket.Arguments{
        socket_location: socket_location,
        reconnect_interval: 0
      },
      player_state_change_fn: event_handler(self())
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

  defp assert_client_connected do
    updated_player_state()
  end
end
