defmodule Exshome.MpvSocket do
  @moduledoc """
  Implementation for MPV socket. It allows to send you some commands to the MPV server.
  """
  use GenServer

  defmodule State do
    @moduledoc """
    A structure for storing internal state for the MPV socket.
    """
    defstruct socket: nil, counter: 1, requests: %{}, handle_event: nil

    @type t() :: %__MODULE__{
            socket: :gen_tcp.socket() | nil,
            counter: integer(),
            requests: %{integer() => GenServer.from()},
            handle_event: (%{String.t() => term()} -> any()) | nil
          }
  end

  defmodule Arguments do
    @moduledoc """
    Initial arguments for MPV socket.
    """
    @enforce_keys [:socket_location, :handle_event]
    defstruct [:socket_location, :handle_event]

    @type t() :: %__MODULE__{
            socket_location: String.t(),
            handle_event: (%{String.t() => term()} -> any())
          }
  end

  @spec start_link(Arguments.t()) :: GenServer.on_start()
  def start_link(%Arguments{} = data) do
    GenServer.start_link(__MODULE__, data)
  end

  @spec send(pid :: pid(), data :: map()) :: term()
  def send(pid, data) when is_map(data) do
    GenServer.call(pid, {:send, data})
  end

  @spec send!(pid :: pid(), data :: map()) :: term()
  def send!(pid, data) do
    {:ok, result} = __MODULE__.send(pid, data)
    result
  end

  @impl GenServer
  def init(%Arguments{socket_location: socket_location, handle_event: handle_event}) do
    {:ok, socket} = :gen_tcp.connect({:local, socket_location}, 0, [:binary, packet: :line])
    state = %State{socket: socket, handle_event: handle_event}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send, data}, from, %State{} = state) do
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
end
