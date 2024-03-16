defmodule ExshomeTest.Hooks.Config do
  @moduledoc """
  Overrides application configuration.
  """

  def default_timeout do
    if ExUnit.configuration()[:trace], do: :infinity, else: 5000
  end

  def root_folder do
    ExshomeTest.TestFileUtils.get_test_folder()
  end
end
