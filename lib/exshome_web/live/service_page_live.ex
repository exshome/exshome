defmodule ExshomeWeb.Live.ServicePageLive do
  @moduledoc """
  Generic service page of the application.
  """

  use ExshomeWeb, :live_view
  alias Exshome.Dependency
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket

  @callback base_prefix() :: atom()
  @callback actions() :: %{atom() => %{module() => atom()}}
  @callback view_module() :: module()
  @callback handle_event(event :: binary, LiveView.unsigned_params(), socket :: Socket.t()) ::
              {:noreply, Socket.t()} | {:reply, map, Socket.t()}
  @optional_callbacks handle_event: 3

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket), do: {:ok, socket}

  @impl Phoenix.LiveView
  def handle_params(
        _unsigned_params,
        url,
        %Socket{assigns: %{live_action: live_action}} = socket
      ) do
    %URI{path: path} = URI.parse(url)
    [prefix | _] = String.split(path, "/", trim: true)
    callback_module = prefix |> String.to_existing_atom() |> get_module_by_prefix()

    socket =
      socket
      |> put_callback_module(callback_module)
      |> subscribe_to_dependencies()
      |> put_template_name("#{live_action}.html")

    {:noreply, socket}
  end

  @impl Phoenix.LiveView
  def handle_event(event, params, %Socket{} = socket) do
    get_callback_module(socket).handle_event(event, params, socket)
  end

  @impl Phoenix.LiveView
  def handle_info({Dependency, {module, value}}, %Socket{assigns: %{deps: deps}} = socket) do
    dependencies = get_dependencies(socket)
    deps = Map.put(deps, Map.fetch!(dependencies, module), value)
    {:noreply, assign(socket, deps: deps)}
  end

  @impl Phoenix.LiveView
  def render(%{socket: socket, deps: deps} = assigns) do
    template_name = get_template_name(socket)

    missing_deps =
      deps
      |> Enum.filter(fn {_key, value} -> value == Dependency.NotReady end)
      |> Enum.map(fn {key, _value} -> key end)

    if Enum.any?(missing_deps) do
      ~L"Missing dependencies: <%= inspect(missing_deps) %>"
    else
      get_callback_module(socket).view_module().render(template_name, assigns)
    end
  end

  @spec put_callback_module(Socket.t(), module()) :: Socket.t()
  def put_callback_module(%Socket{private: private} = socket, callback_module) do
    private = Map.put(private, :callback_module, callback_module)
    %Socket{socket | private: private}
  end

  @spec get_callback_module(Socket.t()) :: module()
  defp get_callback_module(%Socket{} = socket), do: socket.private.callback_module

  @spec subscribe_to_dependencies(Socket.t()) :: Socket.t()
  def subscribe_to_dependencies(%Socket{} = socket) do
    deps =
      for {dependency, key} <- get_dependencies(socket), into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    assign(socket, deps: deps)
  end

  @spec get_dependencies(Socket.t()) :: map()
  defp get_dependencies(%Socket{} = socket) do
    get_callback_module(socket).actions
    |> Map.fetch!(socket.assigns.live_action || :preview)
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
    Exshome.Named.get_module_by_type_and_name(__MODULE__, module_name)
  end

  def get_module_by_prefix(prefix) do
    Exshome.Tag.tag_mapping()
    |> Map.fetch!({__MODULE__, :prefix})
    |> Map.fetch!(prefix)
  end

  @spec actions_with_pages(module()) :: [atom()]
  def actions_with_pages(module) do
    module.actions()
    |> Map.keys()
    |> Enum.filter(&(&1 != :preview))
    |> Enum.sort()
  end

  defmacro __using__(settings) do
    prefix = settings[:prefix]
    view_module = settings[:view_module]
    actions = settings[:actions]

    validate_settings!(prefix, view_module, actions)

    quote do
      import Exshome.Tag, only: [add_tag: 1]
      alias ExshomeWeb.Live.ServicePageLive
      alias Phoenix.LiveView.Socket

      @prefix unquote(prefix)
      use Exshome.Named, "service_page_live_#{@prefix}"
      add_tag(ServicePageLive)
      add_tag({{ServicePageLive, :prefix}, @prefix})
      @behaviour ServicePageLive
      @actions unquote(actions)
               |> Enum.map(fn {action, deps} ->
                 {action, Enum.into(deps, %{})}
               end)
               |> Enum.into(%{})

      @impl ServicePageLive
      def base_prefix, do: @prefix

      def path(conn_or_endpoint, action, params \\ []) do
        apply(
          ExshomeWeb.Router.Helpers,
          :"#{@prefix}_path",
          [conn_or_endpoint, action, params]
        )
      end

      @impl ServicePageLive
      def actions, do: @actions

      @impl ServicePageLive
      def view_module, do: unquote(view_module)
    end
  end

  defp validate_settings!(prefix, view_module, actions) do
    if !is_atom(prefix) do
      raise "Prefix should be an atom, but got #{inspect(prefix)}."
    end

    view_module = Macro.expand(view_module, __ENV__)

    if !is_atom(view_module) do
      raise "View module should be a module: #{inspect(view_module)}"
    end

    available_actions = actions |> Keyword.keys() |> MapSet.new()
    required_actions = MapSet.new([:index, :preview])
    missing_actions = MapSet.difference(required_actions, available_actions)

    if MapSet.size(missing_actions) > 0 do
      raise "Some required actions are missing: #{inspect(missing_actions)}, please add them."
    end

    for {_action, dependencies} <- actions do
      validate_action_settings!(dependencies)
    end
  end

  defp validate_action_settings!(dependencies) do
    dependencies =
      Enum.map(
        dependencies,
        fn {key, value} -> {Macro.expand(key, __ENV__), value} end
      )

    dependency_keys = Enum.map(dependencies, fn {_, key} -> key end)

    invalid_dependency_keys = Enum.filter(dependency_keys, &(!is_atom(&1)))

    if !Enum.empty?(invalid_dependency_keys) do
      raise "invalid dependency keys: #{inspect(invalid_dependency_keys)}, they should be atoms."
    end

    duplicated_dependency_keys =
      dependency_keys
      |> Enum.frequencies()
      |> Enum.filter(fn {_key, count} -> count > 1 end)
      |> Enum.map(fn {key, _count} -> key end)

    if !Enum.empty?(duplicated_dependency_keys) do
      raise "duplicate dependency keys: #{inspect(duplicated_dependency_keys)}"
    end

    duplicated_dependencies =
      dependencies
      |> Enum.map(fn {key, _} -> key end)
      |> Enum.frequencies()
      |> Enum.filter(fn {_key, count} -> count > 1 end)
      |> Enum.map(fn {key, _count} -> key end)

    if !Enum.empty?(duplicated_dependencies) do
      raise "duplicate dependencies: #{inspect(duplicated_dependencies)}"
    end
  end
end
