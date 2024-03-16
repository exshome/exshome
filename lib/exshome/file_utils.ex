defmodule Exshome.FileUtils do
  @moduledoc """
  Module responsible for working with file utilities.
  """

  @doc """
  Returns the folder for data.
  Creates parent folders.
  Raises if folder name is incorrect.
  """
  @spec get_of_create_folder!(folder :: String.t()) :: String.t()
  def get_of_create_folder!(folder) when is_binary(folder) do
    root = Exshome.Config.root_folder()
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
end
