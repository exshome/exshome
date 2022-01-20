defmodule ExshomeWeb.Live.ServicePreview do
  @moduledoc """
  Live view to support services preview.
  """

  use ExshomeWeb, :live_view
  alias ExshomeWeb.Live.ServicePageLive
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    callback_module = ServicePageLive.get_module_by_name(socket.id)

    socket =
      socket
      |> ServicePageLive.put_callback_module(callback_module)
      |> ServicePageLive.subscribe_to_dependencies(callback_module)
      |> ServicePageLive.put_template_name("preview.html")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  defdelegate render(assigns), to: ServicePageLive

  @impl Phoenix.LiveView
  defdelegate handle_info(info, socket), to: ServicePageLive
end
