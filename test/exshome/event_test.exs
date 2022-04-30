defmodule ExshomeTest.EventTest do
  use Exshome.DataCase, async: true
  alias Exshome.Event
  alias ExshomePlayer.Events.MpvEvent
  alias ExshomePlayer.Services.{MpvSocket, PlayerState}

  describe "invalid event module" do
    test "subscribe/1 raises" do
      assert_raise(RuntimeError, fn ->
        Event.subscribe(:invalid_module)
      end)
    end

    test "unsubscribe/1 raises" do
      assert_raise(RuntimeError, fn ->
        Event.unsubscribe(:invalid_module)
      end)
    end

    test "broadcast/1 raises" do
      assert_raise(RuntimeError, fn ->
        Event.broadcast(%PlayerState{})
      end)
    end
  end

  describe "validate_module!/2" do
    test "works well with valid module" do
      assert :ok = Event.validate_module!(%Macro.Env{module: MpvEvent}, "some bytecode")
    end

    test "does not work with invalid module" do
      assert_raise(RuntimeError, fn ->
        Event.validate_module!(%Macro.Env{module: MpvSocket}, "some bytecode")
      end)
    end
  end
end
