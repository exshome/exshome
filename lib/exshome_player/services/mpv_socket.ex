defmodule ExshomePlayer.Services.MpvSocket do
  @moduledoc """
  Implementation for MPV socket. It allows to send you some commands to the MPV server.
  """
  use Exshome.Service.DependencyService, app: ExshomePlayer, name: "mpv_socket"
  alias Exshome.Emitter
  alias ExshomePlayer.Events.MpvEvent
  alias ExshomePlayer.Services.MpvServer

  @type command_response :: %{String.t() => term()}

  @spec send_command(payload :: [term()]) :: command_response()
  def send_command(payload) do
    request!(%{command: payload})
  end

  def request!(data) do
    {:ok, result} = request(data)
    result
  end

  def request(data) when is_map(data) do
    Exshome.Service.call(__MODULE__, {:send_command, data})
  end

  defmodule Data do
    @moduledoc """
    A structure for storing internal state for the MPV socket.
    """
    defstruct [:socket, requests: %{}, counter: 1]

    @type t() :: %__MODULE__{
            socket: :gen_tcp.socket() | nil,
            counter: integer(),
            requests: %{integer() => GenServer.from()}
          }
  end

  @impl ServiceBehaviour
  def init(%ServiceState{} = state), do: connect_to_socket(state)

  @impl ServiceBehaviour
  def handle_call(
        {:send_command, _data},
        _from,
        %ServiceState{data: %Data{socket: nil}} = state
      ) do
    {:reply, not_connected_error(), state}
  end

  @impl ServiceBehaviour
  def handle_call({:send_command, data}, from, %ServiceState{} = state) do
    string_data =
      data
      |> Map.put(:request_id, state.data.counter)
      |> Jason.encode!()

    :ok = :gen_tcp.send(state.data.socket, "#{string_data}\n")

    new_state =
      update_data(state, fn %Data{} = d ->
        %Data{
          d
          | counter: d.counter + 1,
            requests: Map.put(d.requests, d.counter, from)
        }
      end)

    {:noreply, new_state}
  end

  @impl ServiceBehaviour
  def handle_info({:tcp_closed, _socket}, %ServiceState{} = state) do
    for pending_request <- Map.values(state.data.requests) do
      GenServer.reply(pending_request, not_connected_error())
    end

    new_state =
      state
      |> update_data(fn %Data{} = data -> %Data{data | socket: nil, requests: %{}} end)
      |> update_value(fn _ -> :disconnected end)

    {:noreply, schedule_reconnect(new_state)}
  end

  @impl ServiceBehaviour
  def handle_info(:reconnect, %ServiceState{} = state) do
    {:noreply, connect_to_socket(state)}
  end

  @impl ServiceBehaviour
  def handle_info({:tcp, _socket, message}, %ServiceState{} = state) do
    new_state =
      message
      |> Jason.decode!()
      |> handle_message(state)

    {:noreply, new_state}
  end

  def handle_message(%{"event" => _event} = message, %ServiceState{} = state) do
    {type, data} = Map.pop!(message, "event")

    Emitter.broadcast(MpvEvent, {type, data})
    state
  end

  def handle_message(message, %ServiceState{data: %Data{requests: requests}} = state) do
    {request_id, response} = Map.pop!(message, "request_id")

    :ok =
      GenServer.reply(
        requests[request_id],
        process_response(response)
      )

    update_data(
      state,
      fn %Data{} = data -> %Data{data | requests: Map.delete(data.requests, request_id)} end
    )
  end

  defp process_response(%{"error" => "success"} = response) do
    {:ok, response |> Map.delete("error")}
  end

  defp process_response(%{"error" => error}) do
    {:error, error}
  end

  defp not_connected_error, do: {:error, :not_connected}

  @spec connect_to_socket(ServiceState.t()) :: ServiceState.t()
  defp connect_to_socket(%ServiceState{} = state) do
    connect_result =
      :gen_tcp.connect(
        {:local, MpvServer.socket_path()},
        0,
        [:binary, packet: :line]
      )

    case connect_result do
      {:ok, socket} ->
        state
        |> update_data(fn _ -> %Data{socket: socket} end)
        |> update_value(fn _ -> :connected end)

      {:error, _reason} ->
        schedule_reconnect(state)
    end
  end

  @spec schedule_reconnect(ServiceState.t()) :: ServiceState.t()
  defp schedule_reconnect(%ServiceState{} = state) do
    Process.send_after(
      self(),
      :reconnect,
      state.opts[:reconnect_interval] || 100
    )

    state
  end
end
