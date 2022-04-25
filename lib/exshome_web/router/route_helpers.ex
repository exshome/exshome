defmodule ExshomeWeb.Router.RouteHelpers do
  @moduledoc """
  Helper functions for working with router.
  """

  defmacro app_routing(module) do
    quote bind_quoted: [module: module] do
      alias Phoenix.LiveView.Router

      for page <- module.pages() do
        path = Path.join("/#{module.prefix()}", page.path())
        Router.live(path, page, page.action(), as: module.prefix())
      end
    end
  end
end
