defmodule Exshome.Mpv.Socket do
  @moduledoc """
  Implementation for MPV socket. It allows to send you some commands to the MPV server.
  """
  use GenServer
  @connected_key :connected?
  @connect_to_socket_key :connect_to_socket
  @reconnect_key :reconnect
  @send_command_key :send_command

  defmodule State do
    @moduledoc """
    A structure for storing internal state for the MPV socket.
    """
    defstruct [
      :socket,
      :handle_event,
      :socket_location,
      requests: %{},
      counter: 1,
      reconnect_interval: 100
    ]

    @type t() :: %__MODULE__{
            socket: :gen_tcp.socket() | nil,
            counter: integer(),
            reconnect_interval: integer(),
            socket_location: String.t() | nil,
            requests: %{integer() => GenServer.from()},
            handle_event: (%{String.t() => term()} -> any()) | nil
          }
  end

  defmodule Arguments do
    @moduledoc """
    Initial arguments for MPV socket.
    """
    @enforce_keys [:socket_location, :handle_event]
    defstruct [:socket_location, :handle_event, reconnect_interval: 100]

    @type t() :: %__MODULE__{
            handle_event: (%{String.t() => term()} -> any()),
            reconnect_interval: integer(),
            socket_location: String.t()
          }
  end

  @spec start_link(Arguments.t()) :: GenServer.on_start()
  def start_link(%Arguments{} = data) do
    GenServer.start_link(__MODULE__, data)
  end

  @spec send(pid :: pid(), data :: map()) :: term()
  def send(pid, data) when is_map(data) do
    GenServer.call(pid, {@send_command_key, data})
  end

  @spec connected?(pid :: pid()) :: boolean()
  def connected?(pid) do
    GenServer.call(pid, @connected_key)
  end

  @spec send!(pid :: pid(), data :: map()) :: term()
  def send!(pid, data) do
    {:ok, result} = __MODULE__.send(pid, data)
    result
  end

  @impl GenServer
  def init(%Arguments{} = args) do
    state = struct(State, Map.from_struct(args))
    {:ok, state, {:continue, @connect_to_socket_key}}
  end

  @impl GenServer
  def handle_continue(@connect_to_socket_key, %State{} = state) do
    connect_result =
      :gen_tcp.connect({:local, state.socket_location}, 0, [:binary, packet: :line])

    case connect_result do
      {:ok, socket} ->
        new_state = %State{state | socket: socket}
        {:noreply, new_state}

      {:error, _reason} ->
        Process.send_after(self(), @reconnect_key, state.reconnect_interval)
        {:noreply, state}
    end
  end

  @impl GenServer
  def handle_call({@send_command_key, _data}, _from, %State{socket: nil} = state) do
    {:reply, not_connected_error(), state}
  end

  @impl GenServer
  def handle_call({@send_command_key, data}, from, %State{} = state) do
    string_data =
      data
      |> Map.put(:request_id, state.counter)
      |> Jason.encode!()

    :ok = :gen_tcp.send(state.socket, "#{string_data}\n")

    new_state = %{
      state
      | counter: state.counter + 1,
        requests: Map.put(state.requests, state.counter, from)
    }

    {:noreply, new_state}
  end

  @impl GenServer
  def handle_call(@connected_key, _from, %State{socket: socket} = state) do
    {:reply, socket != nil, state}
  end

  @impl GenServer
  def handle_info(@reconnect_key, %State{} = state) do
    {:noreply, state, {:continue, @connect_to_socket_key}}
  end

  @impl GenServer
  def handle_info({:tcp_closed, _socket}, %State{} = state) do
    for pending_request <- Map.values(state.requests) do
      GenServer.reply(pending_request, not_connected_error())
    end

    new_state = %State{state | socket: nil, requests: %{}}
    {:noreply, new_state, {:continue, @connect_to_socket_key}}
  end

  @impl GenServer
  def handle_info({:tcp, _socket, message}, %State{} = state) do
    new_state =
      message
      |> Jason.decode!()
      |> handle_message(state)

    {:noreply, new_state}
  end

  def handle_message(%{"event" => _event} = message, %State{} = state) do
    state.handle_event.(message)
    state
  end

  def handle_message(message, %State{requests: requests} = state) do
    {request_id, response} = Map.pop!(message, "request_id")

    :ok =
      GenServer.reply(
        requests[request_id],
        process_response(response)
      )

    Map.put(state, :requests, Map.delete(requests, request_id))
  end

  defp process_response(%{"error" => "success"} = response) do
    {:ok, response |> Map.delete("error")}
  end

  defp process_response(%{"error" => error}) do
    {:error, error}
  end

  defp not_connected_error, do: {:error, :not_connected}
end
