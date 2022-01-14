defmodule ExshomeWeb.Router.RouteHelpers do
  @moduledoc """
  Helper functions for working with router.
  """

  defmacro service_routing(module) do
    quote bind_quoted: [module: module] do
      live_session module, on_mount: {ExshomeWeb.Live.ServicePageLive, module} do
        live module.base_url(), ExshomeWeb.Live.ServicePageLive, :index
      end
    end
  end
end
