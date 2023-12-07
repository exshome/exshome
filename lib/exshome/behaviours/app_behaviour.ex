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

      @after_compile {AppBehaviour, :validate_module!}
      @behaviour AppBehaviour

      @impl AppBehaviour
      def __app_config__, do: unquote(config)

      use Supervisor, shutdown: :infinity

      def start_link(opts), do: AppBehaviour.start_app_link(__MODULE__, opts)

      def pages, do: unquote(config[:pages])

      def prefix, do: unquote(config[:prefix])

      def preview, do: unquote(config[:preview])

      def path(conn_or_endpoint, action, params \\ []) do
        ExshomeWeb.App.path(__MODULE__, conn_or_endpoint, action, params)
      end

      def details_path(conn_or_endpoint, action, id, params \\ []) do
        ExshomeWeb.App.details_path(__MODULE__, conn_or_endpoint, action, id, params)
      end

      @impl Supervisor
      def init(opts), do: AppBehaviour.init_app(__MODULE__, opts)
    end
  end
end
