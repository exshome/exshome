defmodule ExshomePlayer.Services.MpvServer do
  @moduledoc """
  Starts MPV server.
  """

  alias Exshome.Dependency.NotReady

  use Exshome.Service.DependencyService, app: ExshomePlayer, name: "mpv_server"

  @player_folder "player"
  @music_folder Path.join(@player_folder, "music")

  def restart do
    Exshome.Service.call(__MODULE__, :restart)
  end

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    start_mpv_server(state)
  end

  @impl ServiceBehaviour
  def handle_call(:restart, _from, %ServiceState{} = state) do
    {:reply, :exec.kill(state.data.server_pid, 9), state}
  end

  @impl ServiceBehaviour
  def handle_info(
        {:EXIT, server_pid, _reason},
        %ServiceState{data: %{server_pid: server_pid}} = state
      ) do
    state =
      state
      |> update_value(fn _ -> NotReady end)
      |> start_mpv_server()

    {:noreply, state}
  end

  @spec start_mpv_server(ServiceState.t()) :: ServiceState.t()
  defp start_mpv_server(%ServiceState{} = state) do
    case find_mpv_executable() do
      {:ok, program} ->
        {:ok, pid, _ospid} =
          program
          |> mpv_server_command()
          |> :exec.run_link([
            {:group, 0},
            :kill_group,
            :stdout,
            :stderr
          ])

        state
        |> update_data(fn _ -> %{server_pid: pid} end)
        |> update_value(fn _ -> :started end)

      {:error, :not_found} ->
        update_value(state, fn _ -> NotReady end)
    end
  end

  def socket_path do
    Exshome.FileUtils.get_of_create_folder!(@player_folder)
    |> Path.join("mpv_socket")
  end

  def music_folder do
    Exshome.FileUtils.get_of_create_folder!(@music_folder)
  end

  @spec find_mpv_executable() :: {:ok, charlist()} | {:error, :not_found}
  def find_mpv_executable do
    case System.find_executable("mpv") do
      nil -> {:error, :not_found}
      path -> {:ok, String.to_charlist(path)}
    end
  end

  defp mpv_server_command(program) when is_list(program) do
    [
      program,
      ~c"--no-video",
      ~c"--idle",
      ~c"--no-cache",
      ~c"--no-terminal",
      ~c"--input-ipc-server=#{socket_path()}"
    ]
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(mpv_server_command: 1)
    defdelegate mpv_server_command(program), to: @hook_module

    defoverridable(find_mpv_executable: 0)
    defdelegate find_mpv_executable(), to: @hook_module
  end
end
