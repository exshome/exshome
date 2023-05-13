defmodule ExshomeTest.EventTest do
  use ExshomeTest.DataCase, async: true
  alias Exshome.Event
  alias ExshomePlayer.Events.{MpvEvent, PlayerFileEnd}
  alias ExshomePlayer.Services.PlayerState

  describe "valid event module" do
    test "broadcast/1 works well" do
      Event.broadcast(PlayerFileEnd)
    end
  end

  describe "valid event struct" do
    test "broadcast/1 works well" do
      Event.broadcast(%MpvEvent{})
    end
  end

  describe "invalid event module" do
    test "broadcast/1 raises" do
      assert_raise(RuntimeError, fn ->
        Event.broadcast(%PlayerState{})
      end)
    end
  end
end
