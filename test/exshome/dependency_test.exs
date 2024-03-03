defmodule ExshomeTest.DependencyTest do
  @moduledoc """
  Test edge cases for dependencies.
  """
  use ExshomeTest.DataCase, async: true
  alias Exshome.Dependency
  alias Exshome.Emitter
  alias ExshomeClock.Services.LocalTime

  describe "list subscriptions" do
    test "check number of subscriptions" do
      assert MapSet.size(Dependency.subscriptions()) == 0
      Dependency.get_and_subscribe(LocalTime)
      assert MapSet.size(Dependency.subscriptions()) == 1
      Emitter.unsubscribe(LocalTime)
      assert MapSet.size(Dependency.subscriptions()) == 0
    end
  end
end
