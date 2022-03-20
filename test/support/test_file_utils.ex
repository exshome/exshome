defmodule ExshomeTest.TestFileUtils do
  @moduledoc """
  File manipulation utils for tests.
  """

  @spec generate_test_folder(Access.t()) :: String.t()
  def generate_test_folder(tags) do
    parent_folder_name = sanitize_filder_name(tags[:module])
    test_folder_name = sanitize_filder_name(tags[:test])

    test_path =
      Path.join([
        System.tmp_dir!(),
        "ExshomeTest",
        parent_folder_name,
        test_folder_name,
        "#{Ecto.UUID.generate()}"
      ])

    File.mkdir_p!(test_path)
    ExshomeTest.TestRegistry.put(__MODULE__, test_path)
    ExUnit.Callbacks.on_exit(fn -> File.rm_rf!(test_folder_name) end)
    test_path
  end

  @spec get_test_folder() :: String.t()
  def get_test_folder do
    ExshomeTest.TestRegistry.get!(__MODULE__)
  end

  defp sanitize_filder_name(name) when is_atom(name) do
    Regex.replace(~r/\W+/, Atom.to_string(name), "_")
  end
end
