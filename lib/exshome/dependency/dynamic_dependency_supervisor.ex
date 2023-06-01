defmodule Exshome.Dependency.DynamicDependencySupervisor do
  @moduledoc """
  Generic supervisor for dynamic dependencies.
  """
  @callback list() :: [any()]
  @callback child_module() :: module()

  def start_link(module, opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: module)
    Supervisor.start_link(module, child_opts, supervisor_opts)
  end

  def init(module, child_opts) when is_map(child_opts) do
    custom_init_hook = child_opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()

    module.list()
    |> Enum.map(&child_spec_for_id(child_opts, module, &1.id))
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp child_spec_for_id(child_opts, module, id) do
    child_module = module.child_module()

    child_opts
    |> Map.merge(%{dependency: {child_module, id}, name: nil})
    |> child_module.child_spec()
  end

  @spec start_child_with_id(module(), id :: String.t()) :: :ok
  def start_child_with_id(module, id) when is_binary(id) do
    spec = child_spec_for_id(%{}, module, id)

    {:ok, _} =
      module
      |> supervisor_pid()
      |> Supervisor.start_child(spec)

    :ok
  end

  @spec terminate_child_with_id(module(), String.t()) :: :ok | {:error, :not_found}
  def terminate_child_with_id(module, id) when is_binary(id) do
    %{id: child_id} = child_spec_for_id(%{}, module, id)
    pid = supervisor_pid(module)

    :ok = Supervisor.terminate_child(pid, child_id)
    :ok = Supervisor.delete_child(pid, child_id)
  end

  defp supervisor_pid(module), do: module

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(supervisor_pid: 1, child_spec_for_id: 3)
    defdelegate supervisor_pid(module), to: @hook_module

    def child_spec_for_id(child_opts, module, id) do
      child_opts
      |> @hook_module.child_spec_for_id(module, id)
      |> super(module, id)
    end
  end

  defmacro __using__(_) do
    quote do
      use Supervisor, shutdown: :infinity
      alias Exshome.Dependency.DynamicDependencySupervisor

      @behaviour DynamicDependencySupervisor

      def start_link(opts), do: DynamicDependencySupervisor.start_link(__MODULE__, opts)

      @impl Supervisor
      def init(child_opts), do: DynamicDependencySupervisor.init(__MODULE__, child_opts)

      def start_child_with_id(id),
        do: DynamicDependencySupervisor.start_child_with_id(__MODULE__, id)

      def terminate_child_with_id(id),
        do: DynamicDependencySupervisor.terminate_child_with_id(__MODULE__, id)
    end
  end
end
