defmodule Exshome.Behaviours.AppBehaviour do
  @moduledoc """
  Behaviour for exshome applications.
  """

  alias Exshome.Dependency.GenServerDependency

  @callback __app_config__() :: keyword()
  @callback can_start?() :: bool()

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

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__app_config__(),
      pages: [
        type: {
          :list,
          {:tuple,
           [
             :atom,
             {
               :list,
               {:tuple, [:string, :atom]}
             }
           ]}
        },
        required: true
      ],
      prefix: [type: :string, required: true],
      preview: [type: :atom, required: true],
      template_root: [type: :string, required: true]
    )
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.Behaviours.AppBehaviour
      alias ExshomeWeb.Router.Helpers, as: Routes

      @after_compile {AppBehaviour, :validate_module!}
      @behaviour AppBehaviour

      @impl AppBehaviour
      def __app_config__, do: unquote(config)

      def start_link(opts), do: AppBehaviour.start_app_link(__MODULE__, opts)

      def pages, do: unquote(config[:pages])

      def prefix, do: unquote(config[:prefix])

      def preview, do: unquote(config[:preview])

      use Supervisor, shutdown: :infinity

      @impl Supervisor
      def init(opts), do: AppBehaviour.init_app(__MODULE__, opts)

      @spec path(struct(), String.t(), Keyword.t()) :: String.t()
      def path(conn_or_endpoint, action, params \\ []) do
        Routes.router_path(
          conn_or_endpoint,
          :index,
          unquote(config[:prefix]),
          action,
          params
        )
      end

      @spec details_path(struct(), String.t(), String.t(), Keyword.t()) :: String.t()
      def details_path(conn_or_endpoint, action, id, params \\ []) do
        Routes.router_path(
          conn_or_endpoint,
          :details,
          unquote(config[:prefix]),
          action,
          id,
          params
        )
      end
    end
  end
end
