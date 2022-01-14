defmodule ExshomeWeb.Live.ServicePageLive do
  @moduledoc """
  Generic service page of the application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @callback base_prefix() :: atom()
  @callback dependencies() :: %{module() => atom()}
  @callback render(map()) :: Phoenix.LiveView.Rendered.t()

  def on_mount(callback_module, _params, _session, socket) do
    {:cont, put_callback_module(socket, callback_module)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket), do: {:ok, socket}

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _url, %Socket{} = socket) do
    callback_module = get_callback_module(socket)
    {:noreply, subscribe_to_dependencies(socket, callback_module)}
  end

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

  defmacro __using__(prefix) when is_atom(prefix) do
    quote do
      alias ExshomeWeb.Live.ServicePageLive
      @behaviour ServicePageLive

      @impl ServicePageLive
      def base_prefix, do: unquote(prefix)

      def path(conn_or_endpoint, action, params \\ []) do
        apply(
          ExshomeWeb.Router.Helpers,
          :"#{unquote(prefix)}_path",
          [conn_or_endpoint, action, params]
        )
      end
    end
  end
end
