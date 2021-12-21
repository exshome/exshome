defmodule ExshomeTest.Mpv.ClientTest do
  use ExUnit.Case, async: true
  import ExshomeTest.Fixtures

  alias Exshome.Mpv.Client

  setup do
    socket_location = unique_socket_location()
    server_fixture(socket_location)

    client_data = %Client.Arguments{
      socket_location: socket_location,
      player_state_change_fn: event_handler(self())
    }

    client = start_supervised!({Client, client_data})

    %{client: client, socket_location: socket_location}
  end

  test "client can reconnect to a server", %{client: client} do
    assert received_event(%Client.PlayerState{})
    assert Client.player_state(client) != :disconnected
    stop_server()

    assert received_event(:disconnected)
    assert Client.player_state(client) == :disconnected
  end
end
