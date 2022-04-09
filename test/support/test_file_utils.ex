defmodule ExshomeTest.TestFileUtils do
  @moduledoc """
  File manipulation utils for tests.
  """

  @spec generate_test_folder(Access.t()) :: String.t()
  def generate_test_folder(tags) do
    intermediate_paths =
      if tags[:mpv_test_folder] do
        ["mpv_test_folder"]
      else
        parent_folder_name = sanitize_folder_name(tags[:module])
        test_folder_name = sanitize_folder_name(tags[:test])
        [parent_folder_name, test_folder_name]
      end

    test_path =
      Path.join(
        [System.tmp_dir!(), "ExshomeTest"] ++ intermediate_paths ++ ["#{Ecto.UUID.generate()}"]
      )

    File.mkdir_p!(test_path)
    ExshomeTest.TestRegistry.put(__MODULE__, test_path)

    ExUnit.Callbacks.on_exit(fn ->
      if File.exists?(test_path) do
        File.rm_rf!(test_path)
      end
    end)

    test_path
  end

  @spec get_test_folder() :: String.t()
  def get_test_folder do
    ExshomeTest.TestRegistry.get!(__MODULE__)
  end

  defp sanitize_folder_name(name) when is_atom(name) do
    Regex.replace(~r/\W+/, Atom.to_string(name), "_")
  end
end
