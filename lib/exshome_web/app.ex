defmodule ExshomeWeb.App do
  @moduledoc """
  Generic module for live applications.
  """

  alias Exshome.BehaviourMapping
  alias Exshome.SystemRegistry

  @apps Application.compile_env(:exshome, Exshome.Application, [])[:apps] || []
  def available_apps, do: @apps

  def apps do
    case SystemRegistry.get_by_id(__MODULE__, :available_apps) do
      {:ok, started_apps} -> started_apps
      _ -> []
    end
  end

  def router_config_by_app(app) do
    app_modules =
      Exshome.Mappings.ModuleByAppMapping
      |> BehaviourMapping.custom_mapping!()
      |> Map.fetch!(app)

    routers =
      Exshome.Behaviours.RouterBehaviour
      |> BehaviourMapping.behaviour_implementations()

    [router] =
      MapSet.intersection(app_modules, routers)
      |> MapSet.to_list()

    router.__router_config__()
  end
end
