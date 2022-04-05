defmodule ExshomeTest.App.Player.MpvClientTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  import ExshomeTest.Fixtures

  alias Exshome.App.Player.{MpvClient, MpvSocket}
  alias Exshome.App.Player.MpvClient.PlayerState
  alias ExshomeTest.TestMpvServer

  @unknown_event :unknown_event

  setup do
    server = server_fixture()
    my_pid = self()

    client_data = %MpvClient.Arguments{
      socket_args: %MpvSocket.Arguments{
        reconnect_interval: 0,
        on_init: fn -> ExshomeTest.TestRegistry.allow(my_pid, self()) end
      },
      player_state_change_fn: event_handler(self()),
      unknown_event_handler: event_handler(self(), @unknown_event)
    }

    client = start_supervised!({MpvClient, client_data})
    assert_client_connected()
    %{client: client, server: server}
  end

  test "client can reconnect to a server", %{client: client} do
    assert MpvClient.player_state(client) != :disconnected
    stop_server()

    assert received_event(:disconnected)
    assert MpvClient.player_state(client) == :disconnected

    server_fixture()
    assert_client_connected()
    assert MpvClient.player_state(client) != :disconnected
  end

  test "client can switch tracks", %{client: client, server: server} do
    file_location = "test_file_#{unique_integer()}"
    MpvClient.load_file(client, file_location)
    assert %PlayerState{path: ^file_location, pause: false} = MpvClient.player_state(client)
    assert [file_location] == TestMpvServer.playlist(server)
    MpvClient.pause(client)
    assert %PlayerState{pause: true} = MpvClient.player_state(client)

    another_file = "another_file_#{unique_integer()}"
    MpvClient.load_file(client, another_file)
    assert %PlayerState{path: ^another_file, pause: false} = MpvClient.player_state(client)
    assert [another_file] == TestMpvServer.playlist(server)
  end

  test "client can set volume", %{client: client} do
    volume_level = unique_integer()
    MpvClient.set_volume(client, volume_level)
    assert %PlayerState{volume: ^volume_level} = MpvClient.player_state(client)
  end

  test "client can seek a file", %{client: client} do
    time_pos = unique_integer()
    MpvClient.seek(client, time_pos)
    assert %PlayerState{time_pos: ^time_pos} = MpvClient.player_state(client)
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
