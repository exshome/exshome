defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  alias ExUnit.Callbacks
  import ExUnit.Assertions

  def unique_socket_location do
    System.tmp_dir!()
    |> Path.join("socket_location#{unique_integer()}")
  end

  def unique_integer do
    System.unique_integer([:positive, :monotonic])
  end

  def server_fixture(path, test_pid) do
    File.rm(path)

    {:ok, server} =
      :gen_tcp.listen(0, [
        {:ip, {:local, path}},
        :binary,
        {:packet, :line},
        active: false,
        reuseaddr: true
      ])

    Callbacks.start_supervised!({Task, fn -> accept_connection(server, test_pid) end})

    Callbacks.on_exit(fn ->
      :ok = :gen_tcp.close(server)
    end)

    server
  end

  def accept_connection(server, test_pid) do
    {:ok, connection} = :gen_tcp.accept(server)

    handle_message(connection, test_pid)
  end

  def handle_message(connection, test_pid) do
    case :gen_tcp.recv(connection, 0) do
      {:ok, message} ->
        decoded = Jason.decode!(message)

        send(test_pid, {__MODULE__, decoded})

        :gen_tcp.send(
          connection,
          ~s/{"test": 123, "request_id": #{decoded["request_id"]}, "error": "success"}\n/
        )

        handle_message(connection, test_pid)

      _ ->
        nil
    end
  end

  def received_messages do
    received_messages([])
  end

  defp received_messages(messages) do
    receive do
      {__MODULE__, message} ->
        received_messages([message | messages])
    after
      0 -> messages
    end
  end

  def received_message do
    assert_received({__MODULE__, message})
    message
  end
end
