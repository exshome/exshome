defmodule ExshomeWeb.App do
  @moduledoc """
  Generic module for live applications.
  """

  alias Exshome.SystemRegistry

  @apps Application.compile_env(:exshome, Exshome.Application, [])[:apps] || []
  def available_apps, do: @apps

  def apps do
    case SystemRegistry.get_by_id(__MODULE__, :available_apps) do
      {:ok, started_apps} -> started_apps
      _ -> []
    end
  end
end
