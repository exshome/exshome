defmodule ExshomeTest.Dependency do
  @moduledoc """
  Test edge cases for dependencies.
  """
  use ExUnit.Case, async: true
  alias Exshome.Dependency

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
end
