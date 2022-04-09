defmodule ExshomeTest.Fixtures do
  @moduledoc """
  This module helps to setup tests.
  """

  @spec unique_integer() :: integer()
  def unique_integer do
    System.unique_integer([:positive, :monotonic])
  end
end
