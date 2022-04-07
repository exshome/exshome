defmodule ExshomeTest.App.Player.MpvServerTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  alias Exshome.App.Player.MpvServer
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_dependency(MpvServer, %{})
  end

  test "service has correct state" do
    assert Dependency.subscribe(MpvServer) != Dependency.NotReady
  end

  test "restarts a service" do
    %{server_pid: server_pid} = Dependency.subscribe(MpvServer)
    server_pid |> :exec.ospid() |> :exec.kill(9)
    assert_receive({MpvServer, %{server_pid: new_server_pid}})
    assert server_pid != new_server_pid
  end
end
