defmodule ExshomeTest.Mpv.ClientTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.Mpv.Client

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location)

    client_data = %Client.Arguments{socket_location: socket_location}

    client = start_supervised!({Client, client_data})

    %{client: client, socket_location: socket_location}
  end

  test "simple connection", %{client: client} do
    :timer.sleep(100)
    assert Process.alive?(client)
  end
end
