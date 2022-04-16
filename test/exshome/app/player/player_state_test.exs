defmodule ExshomeTest.App.Player.PlayerStateTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  alias Exshome.App.Player.{MpvSocket, PlayerState}
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  describe "default mpv_socket opts" do
    setup do
      setup_with_opts(%{})
    end

    test "client can handle unexpected event" do
      event = %{"event" => "unexpected_event_#{unique_integer()}"}
      send_event(event)
      assert_receive_event({PlayerState, "player_event", ^event})
    end
  end

  describe "immediate mpv_socket reconnect" do
    setup do
      setup_with_opts(%{reconnect_interval: 0})
    end

    test "client can reconnect to a server" do
      assert Dependency.get_value(PlayerState) != Dependency.NotReady

      stop_server()
      wait_until_socket_disconnects()
      assert Dependency.get_value(PlayerState) == Dependency.NotReady

      server_fixture()
      wait_until_socket_connects()
      assert Dependency.get_value(PlayerState) != Dependency.NotReady
      stop_supervised!(MpvSocket)
    end
  end

  defp setup_with_opts(opts) do
    server_fixture()

    TestRegistry.start_dependency(MpvSocket, opts)

    assert Dependency.subscribe(MpvSocket) == :connected

    TestRegistry.start_dependency(PlayerState)
    Exshome.Event.subscribe(PlayerState, "player_event")

    assert Dependency.subscribe(PlayerState) != Dependency.NotReady
    %{}
  end
end
