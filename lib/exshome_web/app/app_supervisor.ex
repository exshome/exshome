defmodule ExshomeWeb.App.AppSupervisor do
  @moduledoc """
  Supervisor that starts all available applications.
  """

  use Supervisor, shutdown: :infinity
  alias ExshomeWeb.App

  def start_link(opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: __MODULE__)
    Supervisor.start_link(__MODULE__, child_opts, supervisor_opts)
  end

  @impl Supervisor
  def init(child_opts) when is_map(child_opts) do
    {apps, child_opts} = Map.pop(child_opts, :apps, App.available_apps())

    available_apps = Enum.filter(apps, & &1.can_start?())
    :ok = Exshome.SystemRegistry.register!(App, :available_apps, available_apps)

    available_apps
    |> Enum.map(&{&1, child_opts})
    |> Supervisor.init(strategy: :one_for_one)
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(init: 1)

    def init(opts) do
      @hook_module.init(opts)
      result = super(opts)
      result
    end
  end
end
