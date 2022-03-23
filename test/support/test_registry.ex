defmodule ExshomeTest.TestRegistry do
  @moduledoc """
  Registry for async tests.
  """
  alias Exshome.Dependency

  @spec child_spec(opts :: any()) :: Supervisor.child_spec()
  def child_spec(_opts) do
    Registry.child_spec(keys: :unique, name: __MODULE__)
  end

  @spec started?() :: boolean()
  def started?, do: !!Process.whereis(__MODULE__)

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

  @spec get!(key :: any()) :: any()
  def get!(key) do
    case get(key) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  def get(key) do
    lookup({:value, get_parent(), key})
  end

  @spec start_dependency(module :: module(), opts :: map()) :: :ok
  def start_dependency(module, opts \\ %{}) do
    current_pid = self()

    opts =
      opts
      |> Map.put(
        :custom_init_hook,
        fn -> allow(current_pid, self()) end
      )
      |> Map.put_new(:name, nil)

    pid = ExUnit.Callbacks.start_supervised!({module, opts})
    put({:dependency, module}, pid)
  end

  @spec broadcast_dependency(module :: module(), value :: any()) :: :ok
  def broadcast_dependency(module, value) do
    Dependency.subscribe(module)
    Dependency.broadcast_value(module, value)

    receive do
      {^module, ^value} -> :ok
    end
  end

  @spec get_dependency_pid(module()) :: pid() | nil
  def get_dependency_pid(module) do
    case get({:dependency, module}) do
      {:ok, value} -> value
      _ -> nil
    end
  end

  @spec get_parent() :: pid()
  def get_parent do
    get_parent(self())
  end

  @spec get_parent(pid()) :: pid()
  def get_parent(pid) do
    {:ok, parent} = lookup({:parent, pid})
    parent
  end

  defp lookup(key) do
    case Registry.lookup(__MODULE__, key) do
      [{_, value}] -> {:ok, value}
      _ -> {:error, "Unable to find a value for a key #{inspect(key)}"}
    end
  end
end
