defmodule Exshome do
  @moduledoc """
  Documentation for `Exshome`.
  """
  require Logger
  use GenServer

  defstruct socket: nil, counter: 1, requests: %{}, handle_event: nil

  def start_link(%{socket_location: _socket_location, handle_event: _handle_event} = data) do
    GenServer.start_link(__MODULE__, data)
  end

  def send(pid, data) when is_map(data) do
    GenServer.call(pid, {:send, data})
  end

  def send!(pid, data) do
    {:ok, result} = __MODULE__.send(pid, data)
    result
  end

  # Server (callbacks)
  @impl GenServer
  def init(%{socket_location: socket_location, handle_event: handle_event}) do
    {:ok, socket} = :gen_tcp.connect({:local, socket_location}, 0, [:binary, packet: :line])
    state = %__MODULE__{socket: socket, handle_event: handle_event}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send, data}, from, %__MODULE__{} = state) do
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
  def handle_info({:tcp, _socket, message}, %__MODULE__{} = state) do
    new_state =
      message
      |> Jason.decode!()
      |> handle_message(state)

    {:noreply, new_state}
  end

  def handle_message(%{"event" => _event} = message, %__MODULE__{} = state) do
    state.handle_event.(message)
    state
  end

  def handle_message(message, %__MODULE__{requests: requests} = state) do
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
