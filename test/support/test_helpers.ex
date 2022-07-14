defmodule ExshomeTest.TestHelpers do
  @moduledoc """
  Helpers to work with tests.
  """

  defmacro assert_receive_dependency(message, timeout \\ nil) do
    quote do
      ExUnit.Assertions.assert_receive(
        {Exshome.Dependency, unquote(message)},
        unquote(timeout)
      )
    end
  end

  defmacro assert_receive_app_page_dependency(message, timeout \\ 5000) do
    quote do
      ExUnit.Assertions.assert_receive(
        {ExshomeTest.Hooks.AppPage, Exshome.Dependency, unquote(message)},
        unquote(timeout)
      )
    end
  end

  defmacro assert_receive_event(event, timeout \\ nil) do
    quote do
      ExUnit.Assertions.assert_receive(
        {Exshome.Event, unquote(event)},
        unquote(timeout)
      )
    end
  end

  defmacro refute_receive_dependency(message, timeout \\ nil) do
    quote do
      ExUnit.Assertions.refute_receive(
        {Exshome.Dependency, unquote(message)},
        unquote(timeout)
      )
    end
  end

  def flush_messages do
    receive do
      _ -> flush_messages()
    after
      0 -> nil
    end
  end
end
