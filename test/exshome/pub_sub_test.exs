defmodule ExshomeTest.PubSubTest do
  use ExUnit.Case, async: true
  alias Exshome.PubSub
  import ExshomeTest.Fixtures
  alias ExshomeTest.TestRegistry

  describe "with registry" do
    setup do
      TestRegistry.allow(self(), self())
      topic = "topic_#{unique_integer()}"
      PubSub.subscribe(topic)
      %{topic: topic}
    end

    test "topic name is tied to an owner process in tests", %{topic: topic} do
      assert PubSub.topic_name(topic) == ExshomeTest.Hooks.PubSub.topic_name(topic)
    end

    test "broadcast works fine for the same process", %{topic: topic} do
      data = random_data()
      PubSub.broadcast(topic, data)
      assert_received(^data)
    end

    test "unsubscribe works", %{topic: topic} do
      data = random_data()
      PubSub.unsubscribe(topic)
      PubSub.broadcast(topic, data)
      refute_received(^data)

      PubSub.subscribe(topic)
      new_data = random_data()
      PubSub.broadcast(topic, new_data)
      assert_received(^new_data)
    end

    test "broadcast from other process", %{topic: topic} do
      data = random_data()

      test_pid = self()

      {:ok, pid} =
        Task.start_link(fn ->
          TestRegistry.allow(test_pid, self())
          PubSub.broadcast(topic, data)
        end)

      ref = Process.monitor(pid)

      assert_receive {:DOWN, ^ref, :process, ^pid, _reason}
      assert_received(^data)
    end

    defp random_data, do: %{data: unique_integer()}
  end

  describe "without registry" do
    test "pubsub does not work in tests if there is no subscription" do
      topic = "topic_#{unique_integer()}"

      assert_raise(MatchError, fn ->
        PubSub.subscribe(topic)
      end)

      TestRegistry.allow(self(), self())
      PubSub.subscribe(topic)
    end
  end
end
