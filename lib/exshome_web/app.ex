defmodule ExshomeWeb.App do
  @moduledoc """
  Generic module for live applications.
  """

  alias Exshome.SystemRegistry
  alias ExshomeWeb.Router.Helpers, as: Routes

  @apps Application.compile_env(:exshome, Exshome.Application, [])[:apps] || []
  def available_apps, do: @apps

  def apps do
    case SystemRegistry.get_by_id(__MODULE__, :available_apps) do
      {:ok, started_apps} -> started_apps
      _ -> []
    end
  end

  @spec path(module(), struct(), atom(), Keyword.t()) :: String.t()
  def path(module, conn_or_endpoint, action, params \\ []) do
    {_page, _children} = find_routing(module, action)

    Routes.router_path(
      conn_or_endpoint,
      :index,
      module.prefix(),
      action,
      params
    )
  end

  def details_path(module, conn_or_endpoint, action, id, params \\ []) do
    {_page, children} = find_routing(module, action)

    if children == [] do
      raise "Page with action #{action} does not have child pages"
    end

    Routes.router_path(
      conn_or_endpoint,
      :details,
      module.prefix(),
      action,
      id,
      params
    )
  end

  defp find_routing(module, action) do
    Enum.find(module.pages(), fn {page, _} -> page.action() == action end)
  end
end
