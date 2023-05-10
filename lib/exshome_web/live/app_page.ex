defmodule ExshomeWeb.Live.AppPage do
  @moduledoc """
  Generic module for app pages.
  """
  alias Exshome.Dependency
  alias Exshome.Event
  alias Exshome.Subscribable.NotReady
  alias ExshomeWeb.Live.AppPage
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  import Phoenix.Component

  @callback action() :: String.t()
  @callback app_module() :: atom()
  @callback icon() :: String.t()
  @callback dependencies() :: Keyword.t()
  @callback on_app_event(Event.event_message(), Socket.t()) :: Socket.t()
  @callback render_assigns(map()) :: LiveView.Rendered.t()
  @optional_callbacks [on_app_event: 2, render_assigns: 1]

  use ExshomeWeb, :live_view

  @impl LiveView
  def mount(params, session, socket) do
    view = find_view!(params)

    %{lifecycle: lifecycle} = view.__live__()

    socket =
      socket
      |> Map.put(:view, view)
      |> Map.update!(:private, &Map.put(&1, :lifecycle, lifecycle))
      |> assign(:__route__, params)

    {:cont, socket} = LiveView.Lifecycle.mount(params, session, socket)

    if function_exported?(view, :mount, 3) do
      view.mount(params, session, socket)
    else
      {:ok, socket}
    end
  end

  defp find_view!(%{"action" => action, "app" => app_name} = params) do
    app =
      Enum.find(
        ExshomeWeb.App.apps(),
        fn app -> app.prefix() == app_name end
      ) || raise "Unknown app"

    {page, children} =
      Enum.find(
        app.pages(),
        fn {page, _} -> page.action() == action end
      ) || raise "Unknown page"

    child_page_id = params["id"]

    if child_page_id do
      {_, child_page} =
        Enum.find(
          children,
          fn {route, _} -> String.match?(child_page_id, Regex.compile!(route)) end
        ) || raise "Unknown child page"

      child_page
    else
      page
    end
  end

  def on_mount(_, _params, _session, %Socket{} = socket) do
    socket =
      LiveView.attach_hook(
        socket,
        :dependency_hook,
        :handle_info,
        &__MODULE__.on_handle_info/2
      )

    {:cont, put_dependencies(socket, socket.view.dependencies())}
  end

  def on_handle_info({Dependency, {module, value}}, %Socket{} = socket) do
    key = get_dependencies(socket)[module]

    if key do
      socket = update(socket, :deps, &Map.put(&1, key, value))

      {:halt, socket}
    else
      {:cont, socket}
    end
  end

  def on_handle_info({Event, event_message}, %Socket{} = socket) do
    socket = socket.view.on_app_event(event_message, socket)
    {:halt, socket}
  end

  def on_handle_info(_event, %Socket{} = socket), do: {:cont, socket}

  @impl LiveView
  def render(%{deps: deps} = assigns) do
    missing_deps =
      deps
      |> Enum.filter(fn {_key, value} -> value == NotReady end)
      |> Enum.map(fn {key, _value} -> key end)

    assigns
    |> assign(:__missing_deps__, missing_deps)
    |> do_render()
  end

  defp do_render(%{socket: %Socket{view: view}, __missing_deps__: []} = assigns) do
    view.render_assigns(assigns)
  end

  defp do_render(assigns) do
    ~H"Missing dependencies: <%= inspect(@__missing_deps__) %>"
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      dependencies: [type: :keyword_list],
      icon: [type: :string]
    )
  end

  @spec put_dependencies(Socket.t(), Dependency.dependency_mapping()) :: Socket.t()
  def put_dependencies(%Socket{} = socket, mapping) do
    mapping = Enum.into(mapping, %{})

    deps =
      Dependency.change_mapping(
        socket.private[__MODULE__] || %{},
        mapping,
        socket.assigns[:deps] || %{}
      )

    %Socket{
      socket
      | private: Map.put(socket.private, __MODULE__, mapping)
    }
    |> assign(deps: deps)
  end

  defp get_dependencies(%Socket{private: private}), do: Map.fetch!(private, __MODULE__)

  defmacro __using__(config) do
    quote do
      @action __MODULE__
              |> Module.split()
              |> List.last()
              |> Macro.underscore()

      @action_atom String.to_atom(@action)

      @view_module __MODULE__
                   |> Module.split()
                   |> Enum.slice(0..0)
                   |> List.insert_at(-1, ["Web", "View"])
                   |> List.flatten()
                   |> Module.safe_concat()

      @app_module __MODULE__
                  |> Module.split()
                  |> Enum.slice(0..0)
                  |> Module.safe_concat()

      alias ExshomeWeb.Live.AppPage
      alias Phoenix.LiveView
      alias Phoenix.LiveView.Socket

      @afer_compile {AppPage, :validate_module!}
      @behaviour AppPage

      @impl AppPage
      def app_module, do: @app_module

      @impl AppPage
      def action, do: @action

      @impl AppPage
      defdelegate render_assigns(assigns), to: @view_module, as: @action_atom

      @impl AppPage
      def icon, do: unquote(config[:icon] || "")

      @impl AppPage
      def dependencies, do: unquote(config[:dependencies])

      use ExshomeWeb, :live_view
      on_mount(AppPage)

      def __config__, do: unquote(config)

      @impl LiveView
      defdelegate render(assigns), to: AppPage

      defdelegate put_dependencies(socket, mapping), to: AppPage
    end
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(on_handle_info: 2)

    def on_handle_info(event, %Socket{} = socket) do
      original_result = super(event, socket)
      @hook_module.on_handle_info(event, socket, original_result)
    end
  end
end
