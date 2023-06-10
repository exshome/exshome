defmodule ExshomeTest.DependencyTest do
  @moduledoc """
  Test edge cases for dependencies.
  """
  use ExshomeTest.DataCase, async: true
  alias Exshome.Dependency
  alias ExshomeClock.Services.LocalTime

  describe "invalid dependency" do
    test "get_value/1 raises" do
      assert_raise(RuntimeError, fn ->
        Dependency.get_value(:invalid_dependency)
      end)
    end

    test "subscribe/1 raises" do
      assert_raise(RuntimeError, fn ->
        Dependency.subscribe(:invalid_dependency)
      end)
    end

    test "unsubscribe/1 raises" do
      assert_raise(RuntimeError, fn ->
        Dependency.unsubscribe(:invalid_dependency)
      end)
    end

    test "broadcast_value/2 raises" do
      assert_raise(RuntimeError, fn ->
        Dependency.broadcast_value(:invalid_dependency, :some_value)
      end)
    end
  end

  describe "list subscriptions" do
    test "check number of subscriptions" do
      assert MapSet.size(Dependency.subscriptions()) == 0
      Dependency.subscribe(LocalTime)
      assert MapSet.size(Dependency.subscriptions()) == 1
      Dependency.unsubscribe(LocalTime)
      assert MapSet.size(Dependency.subscriptions()) == 0
    end
  end
end
