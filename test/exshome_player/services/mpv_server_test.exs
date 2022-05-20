defmodule ExshomePlayerTest.Services.MpvServerTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Services.MpvServer
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_dependency(MpvServer, %{})
  end

  test "service has correct state" do
    assert Dependency.subscribe(MpvServer) != Dependency.NotReady
  end

  test "restarts a service" do
    :started = Dependency.subscribe(MpvServer)

    MpvServer.restart()
    assert_receive_dependency({MpvServer, Dependency.NotReady})
    assert_receive_dependency({MpvServer, :started})
  end
end
