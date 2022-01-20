defmodule ExshomeWeb.Live.ServicePageLive do
  @moduledoc """
  Generic service page of the application.
  """

  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @callback base_prefix() :: atom()
  @callback dependencies() :: %{module() => atom()}
  @callback name() :: String.t()
  @callback view_module() :: module()

  def on_mount(callback_module, _params, _session, socket) do
    {:cont, put_callback_module(socket, callback_module)}
  end

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket), do: {:ok, socket}

  @impl Phoenix.LiveView
  def handle_params(
        _unsigned_params,
        _url,
        %Socket{assigns: %{live_action: live_action}} = socket
      ) do
    callback_module = get_callback_module(socket)

    socket =
      socket
      |> subscribe_to_dependencies(callback_module)
      |> put_template_name("#{live_action}.html")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_info({module, value}, %Socket{assigns: %{deps: deps}} = socket) do
    dependencies = get_callback_module(socket).dependencies()
    deps = Map.put(deps, Map.fetch!(dependencies, module), value)
    {:noreply, assign(socket, deps: deps)}
  end

  @impl Phoenix.LiveView
  def render(%{socket: socket} = assigns) do
    template_name = get_template_name(socket)
    get_callback_module(socket).view_module().render(template_name, assigns)
  end

  @spec put_callback_module(Socket.t(), module()) :: Socket.t()
  def put_callback_module(%Socket{private: private} = socket, callback_module) do
    private = Map.put(private, :callback_module, callback_module)
    %Socket{socket | private: private}
  end

  @spec get_callback_module(Socket.t()) :: module()
  defp get_callback_module(%Socket{} = socket), do: socket.private.callback_module

  @spec subscribe_to_dependencies(Socket.t(), module()) :: Socket.t()
  def subscribe_to_dependencies(%Socket{} = socket, callback_module) do
    deps =
      for {module, key} <- callback_module.dependencies(), into: %{} do
        {key, module.subscribe()}
      end

    assign(socket, deps: deps)
  end

  @spec put_template_name(socket :: Socket.t(), template_name :: String.t()) :: Socket.t()
  def put_template_name(%Socket{private: private} = socket, template_name) do
    private = Map.put(private, :template_name, template_name)
    %Socket{socket | private: private}
  end

  @spec get_template_name(Socket.t()) :: String.t()
  def get_template_name(%Socket{private: %{template_name: template_name}}), do: template_name

  @spec service_pages() :: MapSet.t(atom())
  def service_pages do
    Exshome.Tag.tag_mapping() |> Map.fetch!(__MODULE__)
  end

  @spec get_module_by_name(String.t()) :: module()
  def get_module_by_name(module_name) when is_binary(module_name) do
    Exshome.Tag.tag_mapping()
    |> Map.fetch!({__MODULE__, :module})
    |> Map.fetch!(module_name)
  end

  defmacro __using__(prefix) when is_atom(prefix) do
    quote do
      import Exshome.Tag, only: [add_tag: 1]
      alias ExshomeWeb.Live.ServicePageLive

      @name "#{unquote(prefix)}"
      add_tag({{ServicePageLive, :module}, @name})
      add_tag(ServicePageLive)
      @behaviour ServicePageLive

      @impl ServicePageLive
      def base_prefix, do: unquote(prefix)

      @impl ServicePageLive
      def name, do: @name

      def path(conn_or_endpoint, action, params \\ []) do
        apply(
          ExshomeWeb.Router.Helpers,
          :"#{@name}_path",
          [conn_or_endpoint, action, params]
        )
      end
    end
  end
end
