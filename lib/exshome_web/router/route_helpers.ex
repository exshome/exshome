defmodule ExshomeWeb.Router.RouteHelpers do
  @moduledoc """
  Helper functions for working with router.
  """
  alias ExshomeWeb.Live.ServicePageLive

  def put_live_service_callback_to_session(
        %Plug.Conn{
          private: %{phoenix_live_view: live_opts}
        } = conn,
        []
      ) do
    case live_opts do
      {ExshomeWeb.Live.ServicePageLive, router_opts, opts} ->
        base_brefix = Keyword.fetch!(router_opts, :as)

        callback_module_name = ServicePageLive.get_module_name_by_prefix(base_brefix)

        opts = put_in(opts.extra.session["callback_module_name"], callback_module_name)
        updated_live_opts = put_elem(live_opts, 2, opts)
        Plug.Conn.put_private(conn, :phoenix_live_view, updated_live_opts)

      _ ->
        conn
    end
  end

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
