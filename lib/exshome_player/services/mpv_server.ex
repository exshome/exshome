defmodule ExshomePlayer.Services.MpvServer do
  @moduledoc """
  Starts MPV server.
  """
  use Exshome.Dependency.GenServerDependency, name: "mpv_server"

  @player_folder "player"
  @music_folder Path.join(@player_folder, "music")

  def restart do
    call(:restart)
  end

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    start_mpv_server(state)
  end

  @impl GenServerDependency
  def handle_call(:restart, _from, %DependencyState{} = state) do
    {:reply, :exec.kill(state.data.server_pid, 9), state}
  end

  @impl GenServerDependency
  def handle_info(
        {:EXIT, server_pid, _reason},
        %DependencyState{data: %{server_pid: server_pid}} = state
      ) do
    state =
      state
      |> update_value(Dependency.NotReady)
      |> start_mpv_server()

    {:noreply, state}
  end

  @spec start_mpv_server(DependencyState.t()) :: DependencyState.t()
  defp start_mpv_server(%DependencyState{} = state) do
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
        |> update_value(:started)

      {:error, :not_found} ->
        update_value(state, Dependency.NotReady)
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
  defp find_mpv_executable do
    case System.find_executable("mpv") do
      nil -> {:error, :not_found}
      path -> {:ok, String.to_charlist(path)}
    end
  end

  defp mpv_server_command(program) when is_list(program) do
    [
      program,
      '--no-video',
      '--idle',
      '--no-cache',
      '--no-terminal',
      '--input-ipc-server=#{socket_path()}'
    ]
  end

  @hook_module Application.compile_env(:exshome, :mpv_server_hook_module)
  if @hook_module do
    defoverridable(mpv_server_command: 1)
    defdelegate mpv_server_command(program), to: @hook_module

    defoverridable(find_mpv_executable: 0)
    defdelegate find_mpv_executable(), to: @hook_module
  end
end
