defmodule Exshome.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children =
      [
        # Start the Ecto repository
        Exshome.Repo,
        # Start the Telemetry supervisor
        ExshomeWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: Exshome.PubSub},
        # Start the Endpoint (http/https)
        ExshomeWeb.Endpoint
        # Start a worker by calling: Exshome.Worker.start_link(arg)
        # {Exshome.Worker, arg}
      ] ++
        Application.get_env(:exshome, :application_children, [
          {Exshome.Dependency.GenServerDependency.DependencySupervisor, %{}}
        ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exshome.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    ExshomeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  @impl Application
  def stop(state) do
    on_stop = Application.get_env(:exshome, :on_stop, fn _ -> :ok end)
    on_stop.(state)
  end
end
