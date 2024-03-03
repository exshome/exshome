defmodule ExshomePlayerTest.Services.MpvServerTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias ExshomePlayer.Services.MpvServer
  alias ExshomeTest.TestRegistry

  describe "MPV is installed" do
    setup do
      TestRegistry.start_dependency(MpvServer, %{})
    end

    test "service has correct state" do
      assert Dependency.get_and_subscribe(MpvServer) != NotReady
    end

    test "restarts a service" do
      :started = Dependency.get_and_subscribe(MpvServer)

      MpvServer.restart()
      assert_receive_dependency({MpvServer, NotReady})
      assert_receive_dependency({MpvServer, :started})
    end
  end

  describe "MPV is not installed" do
    setup do
      ExshomeTest.Hooks.MpvServer.set_mpv_executable_response({:error, :not_found})
      TestRegistry.start_dependency(MpvServer, %{})
    end

    test "server does not start" do
      assert Dependency.get_and_subscribe(MpvServer) == NotReady
    end
  end
end
