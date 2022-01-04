defmodule ExshomeTest.TestRegistry do
  @moduledoc """
  Registry for async tests.
  """

  @spec child_spec() :: Supervisor.child_spec()
  def child_spec do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  @spec allow(parent :: pid(), allow :: pid()) :: :ok
  def allow(parent, allow) when is_pid(parent) and is_pid(allow) do
    {:ok, _} = Registry.register(__MODULE__, {:parent, allow}, parent)
    :ok
  end

  @spec put(key :: any(), value :: any()) :: :ok
  def put(key, value) do
    parent = get_parent()
    {:ok, _} = Registry.register(__MODULE__, {:value, parent, key}, value)
    :ok
  end

  @spec get(key :: any()) :: any()
  def get(key) do
    lookup({:value, get_parent(), key})
  end

  @spec get_parent() :: pid()
  def get_parent do
    lookup({:parent, self()})
  end

  defp lookup(key) do
    case Registry.lookup(__MODULE__, key) do
      [{_, value}] -> value
      _ -> raise "Unable to find a value for a key #{inspect(key)}"
    end
  end
end
