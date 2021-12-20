defmodule Exshome.Mpv.Client do
  use GenServer
  require Logger
  alias Exshome.Mpv.Socket

  defmodule PlayerState do
    @moduledoc """
    A structure for storing a playback state for the MPV client.
    """
    @keys [
      :pause,
      :volume,
      :duration,
      :time_pos,
      :metadata
    ]

    defstruct @keys

    @type t() :: %__MODULE__{
            pause: boolean() | nil,
            volume: float() | nil,
            duration: float() | nil,
            time_pos: float() | nil,
            metadata: map() | nil
          }

    def property_mapping do
      for key <- @keys, into: %{} do
        property_key = key |> Atom.to_string() |> String.replace(~r/_/, "-")
        {property_key, key}
      end
    end
  end

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
    defstruct [:socket, :socket_location, :player_state]

    @type t() :: %__MODULE__{
            socket: pid() | nil,
            socket_location: String.t() | nil,
            player_state: PlayerState.t() | nil
          }
  end

  @connect_to_socket_key :connect_to_socket
  @handle_event_key :handle_event
  @send_command_key :send_command

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

  @spec set_volume(pid :: pid(), level :: integer()) :: command_response()
  def set_volume(pid, level) when is_integer(level) do
    set_property(pid, "volume", level)
  end

  @spec seek(pid :: pid(), duration :: integer()) :: command_response()
  def seek(pid, duration) when is_integer(duration) do
    send_command(pid, ["seek", duration, "absolute"])
  end

  @spec clear_playlist(pid()) :: command_response()
  def clear_playlist(pid) do
    send_command(pid, ["playlist-clear"])
  end

  @spec set_property(pid :: pid(), property :: String.t(), value :: term()) :: command_response()
  def set_property(pid, property, value) do
    send_command(pid, ["set_property", property, value])
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
    new_state = handle_event(event, state)
    {:noreply, new_state}
  end

  @spec handle_event(event :: Socket.event_t(), state :: State.t()) :: State.t()
  def handle_event(:connected, state) do
    subscribe_to_player_state(state)
    %State{state | player_state: %PlayerState{}}
  end

  def handle_event(%{"event" => "property-change", "name" => name} = event, %State{} = state) do
    new_player_state =
      Map.put(
        state.player_state,
        PlayerState.property_mapping()[name],
        event["data"]
      )

    %State{
      state
      | player_state: new_player_state
    }
  end

  def handle_event(event, state) do
    Logger.info(event)
    state
  end

  @spec subscribe_to_player_state(State.t()) :: term()
  def subscribe_to_player_state(%State{} = state) do
    PlayerState.property_mapping()
    |> Map.keys()
    |> Enum.each(&observe_property(&1, state))
  end

  @impl GenServer
  def handle_call({@send_command_key, payload}, _from, %State{} = state) do
    result = socket_command(payload, state)

    {:reply, result, state}
  end

  defp observe_property(property, state) do
    %{} = socket_command(["observe_property", 1, property], state)
  end

  defp socket_command(payload, %State{} = state) do
    Socket.request!(state.socket, %{command: payload})
  end
end
