defmodule ExshomeWeb.Live.ServicePageLive do
  @moduledoc """
  Generic service page of the application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @callback base_url() :: String.t()
  @callback dependencies() :: %{module() => atom()}
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  defmacro service_routing(module) do
    quote bind_quoted: [module: module] do
      live_session module, on_mount: {ExshomeWeb.Live.ServicePageLive, module} do
        live module.base_url(), Live.ServicePageLive, :index
      end
    end
  end

  def on_mount(callback_module, _params, _session, socket) do
    socket =
      socket
      |> put_callback_module(callback_module)
      |> subscribe_to_dependencies(callback_module)

    {:cont, socket}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket), do: {:ok, socket}

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _url, %Socket{} = socket), do: {:noreply, socket}

  @impl Phoenix.LiveView
  def handle_info({module, value}, %Socket{assigns: %{deps: deps}} = socket) do
    dependencies = get_callback_module(socket).dependencies()
    deps = Map.put(deps, Map.fetch!(dependencies, module), value)
    {:noreply, assign(socket, deps: deps)}
  end

  @impl Phoenix.LiveView
  def render(%{socket: socket} = assigns) do
    get_callback_module(socket).render(assigns)
  end

  @spec put_callback_module(Socket.t(), module()) :: Socket.t()
  defp put_callback_module(%Socket{private: private} = socket, callback_module) do
    private = Map.put(private, :callback_module, callback_module)
    %Socket{socket | private: private}
  end

  @spec get_callback_module(Socket.t()) :: module()
  defp get_callback_module(%Socket{} = socket), do: socket.private.callback_module

  @spec subscribe_to_dependencies(Socket.t(), module()) :: Socket.t()
  defp subscribe_to_dependencies(%Socket{} = socket, callback_module) do
    deps =
      for {module, key} <- callback_module.dependencies(), into: %{} do
        {key, module.subscribe()}
      end

    assign(socket, deps: deps)
  end
end
