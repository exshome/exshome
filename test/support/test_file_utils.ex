defmodule ExshomeTest.TestFileUtils do
  @moduledoc """
  File manipulation utils for tests.
  """

  @spec test_root_folder() :: String.t()
  def test_root_folder do
    Path.join([
      Application.get_env(:exshome, :root_folder),
      "ExshomeTest"
    ])
  end

  @spec generate_test_folder() :: String.t()
  def generate_test_folder do
    test_path =
      Path.join([
        test_root_folder(),
        "#{Ecto.UUID.generate()}"
      ])

    File.mkdir_p!(test_path)
    ExshomeTest.TestRegistry.put(__MODULE__, test_path)

    test_path
  end

  @spec get_test_folder() :: String.t()
  def get_test_folder do
    ExshomeTest.TestRegistry.get!(__MODULE__)
  end
end
