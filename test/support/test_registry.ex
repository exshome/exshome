defmodule ExshomeTest.TestRegistry do
  @moduledoc """
  Registry for async tests.
  """

  @spec child_spec(opts :: any()) :: Supervisor.child_spec()
  def child_spec(_opts) do
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

  @spec start_service(module :: module(), opts :: map()) :: :ok
  def start_service(module, opts \\ %{}) do
    current_pid = self()

    opts =
      opts
      |> Map.put(
        :custom_init_hook,
        fn -> allow(current_pid, self()) end
      )
      |> Map.put_new(:name, nil)

    pid = ExUnit.Callbacks.start_supervised!({module, opts})
    put({:service, module}, pid)
  end

  @spec get(key :: any()) :: any()
  def get(key) do
    lookup({:value, get_parent(), key})
  end

  @spec get_parent() :: pid()
  def get_parent do
    get_parent(self())
  end

  @spec get_parent(pid()) :: pid()
  def get_parent(pid) do
    lookup({:parent, pid})
  end

  @spec get_service(module()) :: pid()
  def get_service(module) do
    get({:service, module})
  end

  defp lookup(key) do
    case Registry.lookup(__MODULE__, key) do
      [{_, value}] -> value
      _ -> raise "Unable to find a value for a key #{inspect(key)}"
    end
  end
end
