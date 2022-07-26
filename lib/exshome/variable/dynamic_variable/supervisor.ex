defmodule Exshome.Variable.DynamicVariable.Supervisor do
  @moduledoc """
  Supervisor that starts all dynamic variables.
  """
  use Supervisor, shutdown: :infinity
  alias Exshome.Variable.DynamicVariable
  alias Exshome.Variable.DynamicVariable.Schema

  def start_link(opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: __MODULE__)
    Supervisor.start_link(__MODULE__, child_opts, supervisor_opts)
  end

  @impl Supervisor
  def init(child_opts) when is_map(child_opts) do
    Schema.list()
    |> Enum.map(
      &DynamicVariable.child_spec(%{
        dependency: {DynamicVariable, &1.id},
        name: nil
      })
    )
    |> Supervisor.init(strategy: :one_for_one)
  end
end
