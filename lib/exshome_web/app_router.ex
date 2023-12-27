defmodule ExshomeWeb.AppRouter do
  @moduledoc """
  Simple router for nested applications.
  """

  alias Exshome.Mappings.RouterByPrefixMapping

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(%Plug.Conn{params: %{"app" => app}} = conn, opts) do
    case Map.get(router_mapping(), app) do
      nil ->
        raise Phoenix.Router.NoRouteError, conn: conn, router: __MODULE__

      router ->
        router.call(conn, opts)
    end
  end

  def __routes__ do
    router_mapping()
    |> Map.values()
    |> Enum.map(&Phoenix.Router.routes/1)
    |> List.flatten()
  end

  def __helpers__, do: nil

  defp router_mapping, do: Exshome.BehaviourMapping.custom_mapping!(RouterByPrefixMapping)
end
