defmodule ExshomeWeb.App do
  @moduledoc """
  Generic module for live applications.
  """

  alias Exshome.Dependency.GenServerDependency
  alias ExshomeWeb.Router.Helpers, as: Routes

  @callback can_start?() :: boolean()
  @callback namespace() :: atom()
  @callback pages() :: list(atom())
  @callback preview() :: atom()
  @callback prefix() :: atom()
  @callback template_root() :: String.t()

  @spec start_app_link(module(), map()) :: Supervisor.on_start()
  def start_app_link(module, opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: module)
    Supervisor.start_link(module, child_opts, supervisor_opts)
  end

  @spec init_app(module(), map()) :: {:ok, tuple()}
  def init_app(module, child_opts) when is_map(child_opts) do
    module
    |> GenServerDependency.modules()
    |> MapSet.to_list()
    |> Enum.map(&{&1.get_child_module(), child_opts})
    |> Supervisor.init(strategy: :one_for_one)
  end

  @apps Application.compile_env(:exshome, Exshome.Application, [])[:apps] || []
  def available_apps, do: @apps

  def apps do
    case Exshome.SystemRegistry.get_by_id(__MODULE__, :available_apps) do
      {:ok, started_apps} -> started_apps
      _ -> []
    end
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      pages: [type: {:list, :atom}, required: true],
      prefix: [type: :atom, required: true],
      preview: [type: :atom, required: true]
    )
  end

  @spec path(module(), struct(), atom(), Keyword.t()) :: String.t()
  def path(module, conn_or_endpoint, action, params \\ []) do
    page = Enum.find(module.pages(), fn page -> page.action() == action end)

    Routes.router_path(
      conn_or_endpoint,
      :index,
      module.prefix(),
      page.action(),
      params
    )
  end

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.App
      import Exshome.Tag, only: [add_tag: 1]

      @behaviour App
      @after_compile {App, :validate_module!}

      def __config__, do: unquote(config)

      @namespace __MODULE__
                 |> Atom.to_string()
                 |> String.split()
                 |> List.insert_at(-1, "Web")
                 |> Enum.join(".")
                 |> String.to_atom()

      @impl App
      def can_start?, do: true

      @impl App
      def namespace, do: @namespace

      @impl App
      def pages, do: Keyword.fetch!(__MODULE__.__config__(), :pages)

      @impl App
      def prefix, do: Keyword.fetch!(__MODULE__.__config__(), :prefix)

      @impl App
      def preview, do: Keyword.fetch!(__MODULE__.__config__(), :preview)

      @template_root Path.join([
                       __ENV__.file |> Path.dirname() |> Path.relative_to(File.cwd!()),
                       Path.basename(__ENV__.file, ".ex"),
                       "web",
                       "templates"
                     ])

      @impl App
      def template_root, do: @template_root

      defoverridable(can_start?: 0)

      def path(conn_or_endpoint, action, params \\ []) do
        App.path(__MODULE__, conn_or_endpoint, action, params)
      end

      use Supervisor, shutdown: :infinity

      def start_link(opts), do: App.start_app_link(__MODULE__, opts)

      @impl Supervisor
      def init(opts), do: App.init_app(__MODULE__, opts)
    end
  end
end
