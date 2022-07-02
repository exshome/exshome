defmodule ExshomeTest.TestRegistry do
  @moduledoc """
  Registry for async tests.
  """
  alias Exshome.SystemRegistry

  @spec started?() :: boolean()
  def started?, do: !!Process.whereis(SystemRegistry)

  @spec allow(parent :: pid(), allow :: pid()) :: :ok
  def allow(parent, allow) when is_pid(parent) and is_pid(allow) do
    :ok = SystemRegistry.put!({__MODULE__, :parent, allow}, parent)
  end

  @spec put(key :: any(), value :: any()) :: :ok
  def put(key, value) do
    parent = get_parent()
    :ok = SystemRegistry.put!({__MODULE__, :value, parent, key}, value)
  end

  @spec get!(key :: any()) :: any()
  def get!(key) do
    case get(key) do
      {:ok, value} -> value
      {:error, error} -> raise error
    end
  end

  def get(key) do
    SystemRegistry.get({__MODULE__, :value, get_parent(), key})
  end

  @spec start_dependency(module :: module(), opts :: map()) :: :ok
  def start_dependency(module, opts \\ %{}) do
    opts = prepare_child_opts(opts)
    pid = ExUnit.Callbacks.start_supervised!({module, opts})
    put({:dependency, module}, pid)
  end

  @spec stop_dependency(module :: module()) :: :ok
  def stop_dependency(module) do
    :ok = ExUnit.Callbacks.stop_supervised!(module)
  end

  def prepare_child_opts(opts) do
    current_pid = self()

    opts
    |> Map.put(
      :custom_init_hook,
      fn -> allow(current_pid, self()) end
    )
    |> Map.put_new(:name, nil)
  end

  @spec get_parent() :: pid()
  def get_parent do
    get_parent(self())
  end

  @spec get_parent(pid()) :: pid()
  def get_parent(pid), do: SystemRegistry.get!({__MODULE__, :parent, pid})
end
