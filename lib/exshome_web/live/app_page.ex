defmodule ExshomeWeb.Live.AppPage do
  @moduledoc """
  Generic module for app pages.
  """
  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Emitter
  alias Exshome.Id
  alias ExshomeWeb.Live.AppPage
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Socket
  import Phoenix.Component

  @type stream_event() :: {Id.t(), Operation.t()}
  @type stream_data() :: {Id.t(), Operation.single_operation()}

  @callback dependencies() :: Keyword.t()
  @callback on_stream(stream_data(), Socket.t()) :: Socket.t()
  @optional_callbacks [on_stream: 2]

  use ExshomeWeb, :live_view

  @impl LiveView
  def mount(params, session, %Socket{view: view} = socket) do
    {:cont, socket} = LiveView.Lifecycle.mount(params, session, socket)

    if function_exported?(view, :mount, 3) do
      view.mount(params, session, socket)
    else
      {:ok, socket}
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
      |> put_dependencies(socket.view.dependencies())

    {:cont, socket}
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

  def on_handle_info({DataStream, stream_data}, %Socket{} = socket) do
    socket = handle_stream_operation(socket, stream_data)
    {:halt, socket}
  end

  def on_handle_info(_event, %Socket{} = socket), do: {:cont, socket}

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__page_config__(),
      dependencies: [type: :keyword_list]
    )
  end

  @spec put_dependencies(Socket.t(), Dependency.dependency_mapping()) :: Socket.t()
  def put_dependencies(%Socket{} = socket, mapping) do
    mapping = Enum.into(mapping, %{})

    deps =
      Dependency.change_mapping(
        socket.private[{__MODULE__, :deps}] || %{},
        mapping,
        socket.assigns[:deps] || %{}
      )

    %Socket{
      socket
      | private: Map.put(socket.private, {__MODULE__, :deps}, mapping)
    }
    |> assign(deps: deps)
    |> unsubscribe_deps_for_not_connected_socket()
  end

  @spec unsubscribe_deps_for_not_connected_socket(Socket.t()) :: Socket.t()
  defp unsubscribe_deps_for_not_connected_socket(%Socket{} = socket) do
    if not connected?(socket) do
      for dependency <- Dependency.subscriptions() do
        Emitter.unsubscribe(dependency)
      end
    end

    socket
  end

  defp get_dependencies(%Socket{private: private}), do: Map.fetch!(private, {__MODULE__, :deps})

  @spec handle_stream_operation(Socket.t(), stream_event()) :: Socket.t()
  defp handle_stream_operation(
         %Socket{} = socket,
         {stream, %Operation.Batch{operations: operations}}
       ) do
    for operation <- operations, reduce: socket do
      socket -> handle_stream_operation(socket, {stream, operation})
    end
  end

  defp handle_stream_operation(%Socket{} = socket, stream_data) do
    socket.view.on_stream(stream_data, socket)
  end

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.Live.AppPage
      alias Phoenix.LiveView
      alias Phoenix.LiveView.Socket

      @afer_compile {AppPage, :validate_module!}
      @behaviour AppPage

      @impl AppPage
      def dependencies, do: unquote(config[:dependencies] || [])

      use ExshomeWeb, :live_view
      on_mount(AppPage)

      def __page_config__, do: unquote(config)

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
