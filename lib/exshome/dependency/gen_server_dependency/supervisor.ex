defmodule Exshome.Dependency.GenServerDependency.Supervisor do
  @moduledoc """
  Supervisor that starts all GenServerDependencies
  """

  use Supervisor, shutdown: :infinity
  alias Exshome.Dependency.GenServerDependency

  def start_link(opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: __MODULE__)
    Supervisor.start_link(__MODULE__, child_opts, supervisor_opts)
  end

  @impl Supervisor
  def init(child_opts) when is_map(child_opts) do
    {apps, child_opts} = Map.pop(child_opts, :apps, ExshomeWeb.App.apps())

    apps
    |> Enum.map(&GenServerDependency.modules/1)
    |> Enum.map(&MapSet.to_list/1)
    |> List.flatten()
    |> Enum.map(&{&1.get_child_module(), child_opts})
    |> Supervisor.init(strategy: :one_for_one)
  end
end
