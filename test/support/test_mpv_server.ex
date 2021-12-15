defmodule ExshomeTest.TestMpvServer do
  @moduledoc """
  Test MPV server. You can use it to emulate an MPV server.
  """
  use GenServer

  defmodule State do
    @moduledoc """
    A structure to represent internal state of test MPV server.
    """
    defstruct [:socket_path, :server, :connection, :test_pid, received_messages: []]

    @type t() :: %__MODULE__{
            socket_path: String.t() | nil,
            server: :gen_tcp.socket() | nil,
            connection: :gen_tcp.socket() | nil,
            test_pid: pid(),
            received_messages: [term()]
          }
  end

  defmodule Arguments do
    @moduledoc """
    Arguments to start a test MPV server.
    """
    @enforce_keys [:socket_path, :test_pid]
    defstruct [:socket_path, :test_pid]

    @type t() :: %__MODULE__{
            socket_path: String.t(),
            test_pid: pid()
          }
  end

  @spec start_link(Arguments.t()) :: GenServer.on_start()
  def start_link(%Arguments{} = init_arguments) do
    GenServer.start_link(__MODULE__, init_arguments)
  end

  @spec received_messages(pid()) :: [%{}]
  def received_messages(server) do
    GenServer.call(server, :messages)
  end

  @spec send_event(server :: pid(), event :: %{}) :: term()
  def send_event(server, event) do
    GenServer.call(server, {:event, event})
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

    state = %State{socket_path: socket_path, test_pid: test_pid, server: server}
    {:ok, state, {:continue, :accept_connection}}
  end

  @impl GenServer
  def handle_continue(:accept_connection, %State{} = state) do
    {:ok, connection} = :gen_tcp.accept(state.server)
    new_state = %State{state | connection: connection}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({:tcp, port, message}, %State{} = state) when port == state.connection do
    decoded = Jason.decode!(message)
    send(state.test_pid, {__MODULE__, decoded})

    send_data(
      state,
      %{test: 123, request_id: decoded["request_id"], error: "success"}
    )

    new_state = Map.update!(state, :received_messages, &[decoded | &1])

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(:messages, _from, %State{} = state) do
    {:reply, state.received_messages, state}
  end

  @impl GenServer
  def handle_call({:event, event}, _from, %State{} = state) do
    send_data(state, event)
    {:reply, :ok, state}
  end

  defp send_data(%State{} = state, data) do
    json_data = Jason.encode!(data)
    :gen_tcp.send(state.connection, "#{json_data}\n")
  end
end
