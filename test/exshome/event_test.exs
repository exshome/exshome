defmodule ExshomeTest.EventTest do
  use Exshome.DataCase, async: true
  alias Exshome.App.Player.MpvSocket
  alias Exshome.Event

  describe "invalid event module" do
    test "subscribe/2 raises" do
      assert_raise(RuntimeError, fn ->
        Event.subscribe(:invalid_module, "some_topic")
      end)
    end

    test "unsubscribe/2 raises" do
      assert_raise(RuntimeError, fn ->
        Event.unsubscribe(:invalid_module, "some_topic")
      end)
    end

    test "broadcast_event/3 raises" do
      assert_raise(RuntimeError, fn ->
        Event.broadcast_event(:invalid_module, "some_topic", "event")
      end)
    end
  end

  describe "invalid topic" do
    test "subscribe/2 raises" do
      assert_raise(RuntimeError, fn ->
        Event.subscribe(MpvSocket, "wrong_topic")
      end)
    end

    test "unsubscribe/2 raises" do
      assert_raise(RuntimeError, fn ->
        Event.unsubscribe(MpvSocket, "wrong_topic")
      end)
    end

    test "broadcast_event/3 raises" do
      assert_raise(RuntimeError, fn ->
        Event.broadcast_event(MpvSocket, "wrong_topic", "event")
      end)
    end
  end

  describe "validate_module!/2" do
    test "works well" do
      assert :ok = Event.validate_module!(%Macro.Env{module: MpvSocket}, "some bytecode")
    end
  end

  describe "validate_topics!/3" do
    test "works well" do
      Event.validate_topics!(["some_topic"])
    end

    test "raises on empty topics" do
      assert_raise RuntimeError, ~r"empty", fn ->
        Event.validate_topics!([])
      end
    end

    test "raises on wrong type" do
      assert_raise RuntimeError, ~r"wrong_type", fn ->
        Event.validate_topics!([:wrong_type])
      end
    end

    test "raises on duplicate topics" do
      assert_raise RuntimeError, ~r"duplicate_topic", fn ->
        Event.validate_topics!(["duplicate_topic", "duplicate_topic"])
      end
    end
  end
end
