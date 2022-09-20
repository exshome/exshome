defmodule ExshomeTest.EventTest do
  use ExshomeTest.DataCase, async: true
  alias Exshome.Event
  alias ExshomePlayer.Events.{MpvEvent, PlayerFileEnd}
  alias ExshomePlayer.Services.PlayerState

  describe "valid event module" do
    test "subscribe/1 works well" do
      Event.subscribe(PlayerFileEnd)
    end

    test "unsubscribe/1 works well" do
      Event.unsubscribe(PlayerFileEnd)
    end

    test "broadcast/1 works well" do
      Event.broadcast(PlayerFileEnd)
    end
  end

  describe "valid event struct" do
    test "subscribe/1 works well" do
      Event.subscribe(%MpvEvent{})
    end

    test "unsubscribe/1 works well" do
      Event.unsubscribe(%MpvEvent{})
    end

    test "broadcast/1 works well" do
      Event.broadcast(%MpvEvent{})
    end
  end

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
end
