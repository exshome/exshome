defmodule ExshomeTest.TestRegistry do
  @moduledoc """
  Registry for async tests.
  """
  alias Exshome.Emitter
  alias Exshome.Service.ServiceStateEvent
  alias Exshome.SystemRegistry
  alias ExshomeTest.Hooks.DynamicDependencySupervisor

  import ExUnit.Assertions

  @spec started?() :: boolean()
  def started?, do: !!Process.whereis(SystemRegistry)

  @spec allow(parent :: pid(), allow :: pid()) :: :ok
  def allow(parent, allow) when is_pid(parent) and is_pid(allow) do
    key = {__MODULE__, :parent, allow}

    case SystemRegistry.get(key) do
      {:ok, ^parent} -> :ok
      {:ok, _} -> raise "Process #{inspect(self())} already has a parent"
      {:error, "Unable to find a value" <> _} -> SystemRegistry.put!(key, parent)
    end
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

  @spec start_dynamic_supervisor(module) :: pid()
  def start_dynamic_supervisor(module) do
    :ok = Emitter.subscribe(ServiceStateEvent)

    pid =
      %{}
      |> prepare_child_opts()
      |> Map.put(:supervisor_opts, name: nil)
      |> module.child_spec()
      |> ExUnit.Callbacks.start_supervised!()

    for {_id, child_pid, :worker, _args} <- Supervisor.which_children(pid) do
      assert_receive({
        Exshome.Event,
        {ServiceStateEvent, %ServiceStateEvent{pid: ^child_pid}}
      })
    end

    :ok = DynamicDependencySupervisor.put_supervisor_pid(module, pid)

    pid
  end

  @spec start_service(module :: module(), opts :: map()) :: :ok
  def start_service(module, opts \\ %{}) do
    :ok = Emitter.subscribe(ServiceStateEvent)
    pid = ExUnit.Callbacks.start_supervised!({module, opts})

    assert_receive(
      {Exshome.Event,
       {
         ServiceStateEvent,
         %ServiceStateEvent{id: ^module, state: :ready, pid: ^pid}
       }}
    )

    put({:service, module}, pid)
  end

  @spec stop_service(module :: module()) :: :ok
  def stop_service(module) do
    :ok = ExUnit.Callbacks.stop_supervised!(module)
  end

  @spec start_agent!((-> any())) :: pid()
  def start_agent!(start_fn) do
    current_pid = get_parent()

    agent_fn = fn ->
      allow(current_pid, self())
      start_fn.()
    end

    ExUnit.Callbacks.start_supervised!({Agent, agent_fn})
  end

  @spec stop_agent!(pid()) :: :ok
  def stop_agent!(_pid) do
    :ok = ExUnit.Callbacks.stop_supervised!(Agent)
  end

  def prepare_child_opts(opts) do
    current_pid = get_parent()

    opts
    |> Map.put(
      :custom_init_hook,
      fn -> allow(current_pid, self()) end
    )
    |> Map.put_new(:name, nil)
  end

  def notify_ready do
    parent_pid = get_parent()
    send(parent_pid, {__MODULE__, :ready, self()})
  end

  @spec get_parent() :: pid()
  def get_parent do
    get_parent(self())
  end

  @spec get_parent(pid()) :: pid()
  def get_parent(pid), do: SystemRegistry.get!({__MODULE__, :parent, pid})
end
