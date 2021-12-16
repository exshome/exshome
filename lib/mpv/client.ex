defmodule Exshome.Mpv.Client do
  use GenServer
  alias Exshome.Mpv.Socket

  defmodule Arguments do
    @moduledoc """
    Initial arguments for MPV client.
    """
    @enforce_keys [:socket_location]
    defstruct [:socket_location]

    @type t() :: %__MODULE__{
            socket_location: String.t()
          }
  end

  defmodule State do
    @moduledoc """
    A structure for storing internal state for the MPV client.
    """
    defstruct [:socket, :socket_location]

    @type t() :: %__MODULE__{
            socket: :gen_tcp.socket() | nil,
            socket_location: String.t() | nil
          }
  end

  @connect_to_socket_key :connect_to_socket
  @handle_event_key :handle_event
  @send_command_key :send_command_key

  @spec start_link(Arguments.t()) :: GenServer.on_start()
  def start_link(%Arguments{} = args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  @type command_response :: {:ok, %{String.t() => term()}} | {:error, atom() | String.t()}

  @spec load_file(pid(), url :: String.t()) :: command_response()
  def load_file(pid, url) when is_binary(url) do
    send_command(pid, ["loadfile", url])
  end

  @spec play(pid()) :: command_response()
  def play(pid) do
    set_property(pid, "pause", false)
  end

  @spec pause(pid()) :: command_response()
  def pause(pid) do
    set_property(pid, "pause", true)
  end

  @spec get_volume(pid :: pid()) :: command_response()
  def get_volume(pid) do
    get_property(pid, "volume")
  end

  @spec set_volume(pid :: pid(), level :: integer()) :: command_response()
  def set_volume(pid, level) when is_integer(level) do
    set_property(pid, "volume", level)
  end

  @spec seek(pid :: pid(), duration :: integer()) :: command_response()
  def seek(pid, duration) when is_integer(duration) do
    send_command(pid, ["seek", duration])
  end

  @spec clear_playlist(pid()) :: command_response()
  def clear_playlist(pid) do
    send_command(pid, ["playlist-clear"])
  end

  @spec get_property(pid :: pid(), property :: String.t()) :: command_response()
  def get_property(pid, property) do
    send_command(pid, ["get_property", property])
  end

  @spec set_property(pid :: pid(), property :: String.t(), value :: term()) :: command_response()
  def set_property(pid, property, value) do
    send_command(pid, ["set_property", property, value])
  end

  @spec observe_property(pid :: pid(), property :: String.t()) :: command_response()
  def observe_property(pid, property) do
    send_command(pid, ["observe_property", 1, property])
  end

  @spec send_command(pid :: pid(), payload :: [term()]) :: command_response()
  def send_command(pid, payload) do
    GenServer.call(pid, {@send_command_key, payload})
  end

  @impl GenServer
  def init(%Arguments{socket_location: socket_location}) do
    state = %State{socket_location: socket_location}
    {:ok, state, {:continue, @connect_to_socket_key}}
  end

  @impl GenServer
  def handle_continue(@connect_to_socket_key, %State{} = state) do
    my_pid = self()

    {:ok, socket} =
      Socket.start_link(%Socket.Arguments{
        socket_location: state.socket_location,
        handle_event: fn event -> send(my_pid, {@handle_event_key, event}) end
      })

    new_state = %State{state | socket: socket}
    {:noreply, new_state}
  end

  @impl GenServer
  def handle_info({@handle_event_key, event}, state) do
    IO.inspect(event)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({@send_command_key, payload}, _from, %State{} = state) do
    result = Socket.send(state.socket, %{command: payload})

    {:reply, result, state}
  end
end
