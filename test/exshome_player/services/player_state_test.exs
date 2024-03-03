defmodule ExshomePlayerTest.Services.PlayerStateTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias ExshomePlayer.Events.{PlayerFileEndEvent, PlayerStateEvent}
  alias ExshomePlayer.Services.{MpvSocket, PlayerState}
  alias ExshomeTest.TestRegistry

  describe "default mpv_socket opts" do
    setup do
      setup_with_opts(%{})
    end

    test "client sends event on track end" do
      reason = "reason_#{unique_integer()}"
      send_event(%{"event" => "end-file", "reason" => reason})
      assert_receive_event({PlayerFileEndEvent, ^reason})
    end

    test "client can handle unexpected event" do
      event_type = "unexpected_event_#{unique_integer()}"
      event = %{"event" => event_type}
      send_event(event)
      assert_receive_event({PlayerStateEvent, {^event_type, %{}}})
    end
  end

  describe "immediate mpv_socket reconnect" do
    setup do
      setup_with_opts(%{reconnect_interval: 0})
    end

    test "client can reconnect to a server" do
      assert Dependency.get_value(PlayerState) != NotReady

      stop_server()
      wait_until_socket_disconnects()
      assert Dependency.get_value(PlayerState) == NotReady

      server_fixture()
      wait_until_socket_connects()
      assert Dependency.get_value(PlayerState) != NotReady
      stop_supervised!(MpvSocket)
    end
  end

  defp setup_with_opts(opts) do
    server_fixture()

    TestRegistry.start_dependency(MpvSocket, opts)

    assert Dependency.get_and_subscribe(MpvSocket) == :connected

    TestRegistry.start_dependency(PlayerState)
    Emitter.subscribe(PlayerFileEndEvent)
    Emitter.subscribe(PlayerStateEvent)

    assert Dependency.get_and_subscribe(PlayerState) != NotReady
    %{}
  end
end
