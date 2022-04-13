defmodule ExshomeTest.App.Player.PlayerStateTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  alias Exshome.App.Player.{MpvSocket, PlayerState}
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup do
    server_fixture()

    TestRegistry.start_dependency(MpvSocket, %{reconnect_interval: 0})

    assert Dependency.subscribe(MpvSocket) == :connected

    TestRegistry.start_dependency(PlayerState)
    Exshome.Event.subscribe(PlayerState, "player_event")

    assert Dependency.subscribe(PlayerState) != Dependency.NotReady
    %{}
  end

  test "client can reconnect to a server" do
    assert Dependency.get_value(PlayerState) != Dependency.NotReady

    stop_server()
    wait_until_socket_disconnects()
    assert Dependency.get_value(PlayerState) == Dependency.NotReady

    server_fixture()
    wait_until_socket_connects()
    assert Dependency.get_value(PlayerState) != Dependency.NotReady
  end

  test "client can switch tracks" do
    file_location = "test_file_#{unique_integer()}"
    MpvSocket.load_file(file_location)
    assert %PlayerState{path: ^file_location, pause: false} = Dependency.get_value(PlayerState)
    assert [file_location] == playlist()
    MpvSocket.pause()
    assert %PlayerState{pause: true} = Dependency.get_value(PlayerState)

    another_file = "another_file_#{unique_integer()}"
    MpvSocket.load_file(another_file)
    assert %PlayerState{path: ^another_file, pause: false} = Dependency.get_value(PlayerState)
    assert [another_file] == playlist()
  end

  test "client can set volume" do
    volume_level = unique_integer()
    MpvSocket.set_volume(volume_level)
    assert %PlayerState{volume: ^volume_level} = Dependency.get_value(PlayerState)
  end

  test "client can seek a file" do
    time_pos = unique_integer()
    MpvSocket.seek(time_pos)
    assert %PlayerState{time_pos: ^time_pos} = Dependency.get_value(PlayerState)
  end

  test "client can handle unexpected event" do
    event = %{"event" => "unexpected_event_#{unique_integer()}"}
    send_event(event)
    assert_receive_event({PlayerState, "player_event", ^event})
  end
end
