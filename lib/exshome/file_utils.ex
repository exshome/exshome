defmodule Exshome.FileUtils do
  @moduledoc """
  Module responsible for working with file utilities.
  """

  @doc """
  Root data folder.
  It stores all user data.
  """
  @spec root_folder() :: String.t()
  def root_folder do
    Application.get_env(:exshome, :root_folder)
  end

  @doc """
  Returns the folder for data.
  Creates parent folders.
  Raises if folder name is incorrect.
  """
  @spec get_of_create_folder!(folder :: String.t()) :: String.t()
  def get_of_create_folder!(folder) when is_binary(folder) do
    root = root_folder()
    expected_folder = Path.join(root, folder)
    expanded_folder = Path.expand(expected_folder)
    out_of_root = Path.relative_to(root, expanded_folder) != root

    if out_of_root do
      raise "Folder #{folder} is out or root"
    end

    if !File.dir?(expected_folder) do
      :ok = File.mkdir_p!(expected_folder)
    end

    expected_folder
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(root_folder: 0)
    defdelegate root_folder, to: @hook_module
  end
end
