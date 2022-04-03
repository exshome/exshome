defmodule ExshomeTest.Hooks.FileUtils do
  @moduledoc """
  Custom hooks for file utils.
  """

  def root_folder do
    ExshomeTest.TestFileUtils.get_test_folder()
  end
end
