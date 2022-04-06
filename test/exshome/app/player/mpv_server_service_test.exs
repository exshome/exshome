defmodule ExshomeTest.App.Player.MpvServerServiceTest do
  use Exshome.DataCase, async: true
  @moduletag :mpv_test_folder

  alias Exshome.App.Player.MpvServerService
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_dependency(MpvServerService, %{})
  end

  test "service has correct state" do
    assert Dependency.subscribe(MpvServerService) != Dependency.NotReady
  end

  test "restarts a service" do
    %{server_pid: server_pid} = Dependency.subscribe(MpvServerService)
    server_pid |> :exec.ospid() |> :exec.kill(9)
    assert_receive({MpvServerService, %{server_pid: new_server_pid}})
    assert server_pid != new_server_pid
  end
end
