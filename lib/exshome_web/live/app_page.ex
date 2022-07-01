defmodule ExshomeWeb.Live.AppPage do
  @moduledoc """
  Generic module for app pages.
  """
  alias Exshome.Dependency
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  import Phoenix.LiveView.Helpers

  @callback action() :: atom()
  @callback app_module() :: atom()
  @callback view_module() :: atom()
  @callback icon() :: String.t()
  @callback path() :: String.t()
  @callback dependencies() :: Keyword.t()

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

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      dependencies: [type: :keyword_list],
      icon: [type: :string]
    )
  end

  defp get_dependencies(%Socket{view: view}), do: view.dependencies()

  defp view_module(%Socket{view: view}) do
    view.view_module()
  end

  defp template_name(%Socket{view: view}), do: view.path()

  defmacro __using__(config) do
    quote do
      @action __MODULE__
              |> Module.split()
              |> List.last()
              |> Macro.underscore()
              |> String.to_atom()

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
      def view_module, do: @view_module

      @impl AppPage
      def path, do: "#{@action}.html"

      @impl AppPage
      def icon, do: unquote(config[:icon] || "")

      @impl AppPage
      def dependencies, do: unquote(config[:dependencies])

      use ExshomeWeb, :live_view
      on_mount(AppPage)

      def __config__, do: unquote(config)

      @impl LiveView
      defdelegate render(assigns), to: AppPage
    end
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(handle_info: 2)

    def handle_info(event, %Socket{} = socket) do
      original_result = super(event, socket)
      @hook_module.handle_info(event, socket, original_result)
    end
  end
end
