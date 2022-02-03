defmodule ExshomeWeb.Router.RouteHelpers do
  @moduledoc """
  Helper functions for working with router.
  """
  defmacro service_routing(module) do
    quote bind_quoted: [module: module] do
      alias ExshomeWeb.Live.ServicePageLive
      alias Phoenix.LiveView.Router

      for action <- ServicePageLive.actions_with_pages(module) do
        Router.live(
          "/#{Atom.to_string(module.base_prefix())}/#{Atom.to_string(action)}.html",
          ServicePageLive,
          action,
          as: module.base_prefix()
        )
      end
    end
  end
end
