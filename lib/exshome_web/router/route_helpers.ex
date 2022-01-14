defmodule ExshomeWeb.Router.RouteHelpers do
  @moduledoc """
  Helper functions for working with router.
  """

  defmacro service_routing(module) do
    quote bind_quoted: [module: module] do
      alias ExshomeWeb.Live.ServicePageLive
      alias Phoenix.LiveView.Router

      Router.live_session module, on_mount: {ServicePageLive, module} do
        Router.live(
          "/#{Atom.to_string(module.base_prefix())}",
          ServicePageLive,
          :index,
          as: module.base_prefix()
        )
      end
    end
  end
end
