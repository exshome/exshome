defmodule ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor do
  @moduledoc """
  Supervisor that starts all dynamic variables.
  """
  use Supervisor, shutdown: :infinity
  alias ExshomeAutomation.Variables.DynamicVariable
  alias ExshomeAutomation.Variables.DynamicVariable.Schema

  def start_link(opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: __MODULE__)
    Supervisor.start_link(__MODULE__, child_opts, supervisor_opts)
  end

  @impl Supervisor
  def init(child_opts) when is_map(child_opts) do
    custom_init_hook = child_opts[:custom_init_hook]
    custom_init_hook && custom_init_hook.()

    Schema.list()
    |> Enum.map(&child_spec_for_id(child_opts, &1.id))
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp child_spec_for_id(child_opts, id) do
    child_opts
    |> Map.merge(%{dependency: {DynamicVariable, id}, name: nil})
    |> DynamicVariable.child_spec()
  end

  @spec start_child_with_id(id :: String.t()) :: :ok
  def start_child_with_id(id) when is_binary(id) do
    spec = child_spec_for_id(%{}, id)
    {:ok, _} = Supervisor.start_child(__MODULE__, spec)
    :ok
  end

  @spec termintate_child_with_id(String.t()) :: :ok | {:error, :not_found}
  def termintate_child_with_id(id) do
    %{id: supervisor_id} = child_spec_for_id(%{}, id)
    Supervisor.terminate_child(__MODULE__, supervisor_id)
  end
end
