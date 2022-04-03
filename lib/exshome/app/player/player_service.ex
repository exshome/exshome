defmodule Exshome.App.Player.PlayerService do
  @moduledoc """
  Player service.
  Launches a player, together with a client.
  """
  alias Exshome.App.Player

  defmodule Opts do
    @moduledoc """
    Player options.
    """

    defstruct [:server_pid, :client_pid]

    @type t() :: %__MODULE__{
            server_pid: pid(),
            client_pid: pid()
          }
  end

  defmodule ServiceState do
    @moduledoc """
    PlayerService state.
    """

    defstruct [:data, :client_pid]

    @type t() :: %__MODULE__{
            data: Player.MpvClient.PlayerState.t(),
            client_pid: pid()
          }
  end

  use Exshome.Service, name: "player_service"

  @impl Service
  def parse_opts(opts) do
    %Opts{
      server_pid: opts[:server_pid],
      client_pid: opts[:client_pid]
    }
  end

  @impl Service
  def handle_info({:player_state, data}, %State{} = state) do
    player_state = %ServiceState{
      data: data,
      client_pid: state.opts.client_pid
    }

    {:noreply, update_value(state, player_state)}
  end

  @impl Service
  def on_init(state) do
    state
    |> start_server()
    |> start_client()
  end

  defp start_server(%{opts: %Opts{server_pid: server_pid}} = state) do
    if server_pid != nil && Process.alive?(server_pid) do
      state
    else
      server_pid = start_mpv_server()
      put_in(state.opts.server_pid, server_pid)
    end
  end

  @spec start_mpv_server() :: pid()
  defp start_mpv_server do
    {:ok, pid, _ospid} =
      :exec.run_link(
        [
          System.find_executable("mpv") |> String.to_charlist(),
          '--no-video',
          '--idle',
          '--input-ipc-server=#{ipc_socket_location()}'
        ],
        [
          {:group, 0},
          :kill_group,
          :stdout,
          :stderr
        ]
      )

    pid
  end

  defp start_client(%{opts: %Opts{client_pid: client_pid}} = state) do
    if client_pid != nil && Process.alive?(client_pid) do
      state
    else
      client_pid = start_mpv_client()
      put_in(state.opts.client_pid, client_pid)
    end
  end

  @spec start_mpv_client() :: pid()
  defp start_mpv_client do
    player_pid = self()

    {:ok, pid} =
      Player.MpvClient.start_link(%Player.MpvClient.Arguments{
        socket_args: %Player.MpvSocket.Arguments{
          socket_location: ipc_socket_location()
        },
        player_state_change_fn: &send(player_pid, {:player_state, &1}),
        unknown_event_handler: &send(player_pid, {:unknown_event, &1})
      })

    pid
  end

  defp ipc_socket_location do
    Exshome.FileUtils.get_of_create_folder!("player")
    |> Path.join("mpv_socket")
  end
end
