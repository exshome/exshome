defmodule ExshomeWeb.Live.ServicePreview do
  @moduledoc """
  Live view to support services preview.
  """

  use ExshomeWeb, :live_view
  alias ExshomeWeb.Live.ServicePageLive
  alias Phoenix.LiveView.Socket

  @impl Phoenix.LiveView
  def mount(_params, %{"name" => name}, %Socket{} = socket) do
    callback_module = ServicePageLive.get_module_by_name(name)

    socket =
      socket
      |> ServicePageLive.put_callback_module(callback_module)
      |> ServicePageLive.subscribe_to_dependencies()
      |> ServicePageLive.put_template_name("preview.html")

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  defdelegate render(assigns), to: ServicePageLive

  @impl Phoenix.LiveView
  defdelegate handle_info(info, socket), to: ServicePageLive

  @spec preview_settings(module()) :: Keyword.t()
  def preview_settings(module) do
    [
      id: module.name(),
      session: %{"name" => module.name()},
      container: {:div, class: "w-full h-full"}
    ]
  end
end
