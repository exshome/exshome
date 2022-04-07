defmodule Exshome.App.Player.MpvServer do
  @moduledoc """
  Starts MPV server.
  """
  use Exshome.Dependency.GenServerDependency, name: "mpv_server"

  def on_init(%DependencyState{} = state) do
    server_pid = start_mpv_server()
    update_value(state, %{server_pid: server_pid})
  end

  @impl GenServerDependency
  def handle_info(
        {:EXIT, server_pid, _reason},
        %DependencyState{value: %{server_pid: server_pid}} = state
      ) do
    state =
      update_value(
        state,
        %{server_pid: start_mpv_server()}
      )

    {:noreply, state}
  end

  @spec start_mpv_server() :: pid()
  defp start_mpv_server do
    {:ok, pid, _ospid} =
      :exec.run_link(
        mpv_server_command(),
        [
          {:group, 0},
          :kill_group,
          :stdout,
          :stderr
        ]
      )

    pid
  end

  def socket_path do
    Exshome.FileUtils.get_of_create_folder!("player")
    |> Path.join("mpv_socket")
  end

  defp mpv_server_command do
    [
      System.find_executable("mpv") |> String.to_charlist(),
      '--no-video',
      '--idle',
      '--input-ipc-server=#{socket_path()}'
    ]
  end

  @hook_module Application.compile_env(:exshome, :mpv_server_hook_module)
  if @hook_module do
    defoverridable(mpv_server_command: 0)
    defdelegate mpv_server_command(), to: @hook_module
  end
end
