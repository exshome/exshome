defmodule Exshome do
  @moduledoc """
  Documentation for `Exshome`.
  """
  use GenServer

  # Client
  def start_link(socket_location \\ "/tmp/mpvsocket") do
    GenServer.start_link(__MODULE__, socket_location)
  end

  def send(pid, data) when is_map(data) do
    GenServer.call(pid, {:send, data})
  end

  # Server (callbacks)
  @impl GenServer
  def init(socket_location) do
    {:ok, socket} = :gen_tcp.connect({:local, socket_location}, 0, [:binary, packet: :line])
    state = %{socket: socket, counter: 0, requests: %{}}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send, data}, from, state) do
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
  def handle_info({:tcp, _socket, message}, state) do
    new_state =
      message
      |> Jason.decode!()
      |> handle_message(state)

    {:noreply, new_state}
  end

  def handle_message(%{"event" => _event} = message, state) do
    IO.inspect(message)
    state
  end

  def handle_message(message, %{requests: requests} = state) do
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
