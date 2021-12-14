defmodule ExshomeTest.TestMpvServer do
  use GenServer

  defstruct [:socket_path, :server, :connection, :test_pid, received_messages: []]

  def start_link(init_arguments) do
    GenServer.start_link(__MODULE__, init_arguments)
  end

  def received_messages(server) do
    GenServer.call(server, :messages)
  end

  @impl GenServer
  def init(%{socket_path: socket_path, test_pid: test_pid}) do

    File.rm(socket_path)

    {:ok, server} =
      :gen_tcp.listen(0, [
        {:ip, {:local, socket_path}},
        :binary,
        {:packet, :line},
        reuseaddr: true
      ])
    state = %__MODULE__{socket_path: socket_path, test_pid: test_pid, server: server}
    {:ok, state, {:continue, :accept_connection}}
  end

  @impl GenServer
  def handle_continue(:accept_connection, %__MODULE__{} = state) do
    {:ok, connection} = :gen_tcp.accept(state.server)
    new_state = %__MODULE__{state | connection: connection}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:tcp, port, message}, %__MODULE__{} = state) when port == state.connection do
    decoded = Jason.decode!(message)
    send(state.test_pid, {__MODULE__, decoded})

    :gen_tcp.send(
      state.connection,
      ~s/{"test": 123, "request_id": #{decoded["request_id"]}, "error": "success"}\n/
    )

    new_state = Map.update!(state, :received_messages, &[decoded | &1])

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:messages, _from, %__MODULE__{} = state) do
    {:reply, state.received_messages, state}
  end
end
