defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  alias ExshomeTest.TestMpvServer
  alias ExUnit.Callbacks

  def unique_socket_location do
    System.tmp_dir!()
    |> Path.join("socket_location#{unique_integer()}")
  end

  def unique_integer do
    System.unique_integer([:positive, :monotonic])
  end

  def server_fixture(socket_path, test_pid) do
    server =
      Callbacks.start_supervised!({
        TestMpvServer,
        %{socket_path: socket_path, test_pid: test_pid}
      })

    Process.put(TestMpvServer, server)
  end

  @spec received_messages() :: [%{}]
  def received_messages do
    TestMpvServer
    |> Process.get()
    |> TestMpvServer.received_messages()
  end

  def last_received_message do
    [message | _] = received_messages()
    message
  end
end
