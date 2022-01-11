defmodule ExshomeWeb.ServicePage do
  @moduledoc """
  Generic service page of the application.
  """
  defmacro __using__(dependencies: dependencies) do
    quote do
      @dependencies unquote(dependencies)
      use ExshomeWeb, :live_view
      alias Phoenix.LiveView.Socket

      @impl Phoenix.LiveView
      def mount(_params, _session, %Socket{} = socket) do
        deps =
          for {module, key} <- @dependencies, into: %{} do
            {key, module.subscribe()}
          end

        {:ok, assign(socket, deps: deps)}
      end

      @impl Phoenix.LiveView
      def handle_params(_unsigned_params, _url, %Socket{} = socket) do
        {:noreply, socket}
      end

      @impl Phoenix.LiveView
      def handle_info({module, value}, %Socket{assigns: %{deps: deps}} = socket) do
        deps = Map.put(deps, Map.fetch!(@dependencies, module), value)
        {:noreply, assign(socket, deps: deps)}
      end
    end
  end
end
