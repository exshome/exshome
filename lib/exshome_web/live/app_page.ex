defmodule ExshomeWeb.Live.AppPage do
  @moduledoc """
  Generic module for app pages.
  """
  alias Exshome.Dependency
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  import Phoenix.LiveView.Helpers

  @callback action() :: Atom.t()
  @callback app_module() :: Atom.t()
  @callback icon() :: String.t()
  @callback path() :: String.t()

  def on_mount(_, _params, _session, %Socket{} = socket) do
    socket =
      LiveView.attach_hook(
        socket,
        :dependency_hook,
        :handle_info,
        &__MODULE__.handle_info/2
      )

    deps =
      for {dependency, key} <- get_dependencies(socket), into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    {:cont, LiveView.assign(socket, deps: deps)}
  end

  def handle_info({Dependency, {module, value}}, %Socket{} = socket) do
    key = get_dependencies(socket)[module]

    if key do
      socket = LiveView.update(socket, :deps, &Map.put(&1, key, value))
      {:halt, socket}
    else
      {:cont, socket}
    end
  end

  def handle_info(_event, %Socket{} = socket), do: {:cont, socket}

  def render(%{socket: %Socket{} = socket, deps: deps} = assigns) do
    missing_deps =
      deps
      |> Enum.filter(fn {_key, value} -> value == Dependency.NotReady end)
      |> Enum.map(fn {key, _value} -> key end)

    if Enum.any?(missing_deps) do
      ~H"Missing dependencies: <%= inspect(missing_deps) %>"
    else
      template = template_name(socket)
      view_module(socket).render(template, assigns)
    end
  end

  def validate_config!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      dependencies: [type: :keyword_list],
      icon: [type: :string]
    )
  end

  defp get_dependencies(%Socket{view: view}) do
    Keyword.fetch!(view.__config__(), :dependencies)
  end

  defp view_module(%Socket{view: view}) do
    view.app_module().view_module()
  end

  defp template_name(%Socket{view: view}), do: view.path()

  defmacro __using__(config) do
    quote do
      @action __MODULE__
              |> Module.split()
              |> List.last()
              |> Macro.underscore()
              |> String.to_atom()

      @app_module __MODULE__
                  |> Module.split()
                  |> Enum.slice(0..-2)
                  |> Module.safe_concat()

      alias ExshomeWeb.Live.AppPage

      @afer_compile {AppPage, :validate_config!}
      @behaviour AppPage

      @impl AppPage
      def action, do: @action

      @impl AppPage
      def app_module, do: @app_module

      @impl AppPage
      def path, do: "#{@action}.html"

      @impl AppPage
      def icon, do: unquote(config[:icon] || "")

      use ExshomeWeb, :live_view
      on_mount(AppPage)

      def __config__, do: unquote(config)

      @impl Phoenix.LiveView
      defdelegate render(assigns), to: AppPage
    end
  end
end
