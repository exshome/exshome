defmodule Exshome.Behaviours.AppBehaviour do
  @moduledoc """
  Behaviour for exshome applications.
  """

  alias Exshome.Service

  @callback can_start?() :: bool()

  @spec start_app_link(module(), map()) :: Supervisor.on_start()
  def start_app_link(module, opts) when is_map(opts) do
    {supervisor_opts, child_opts} = Map.pop(opts, :supervisor_opts, name: module)
    Supervisor.start_link(module, child_opts, supervisor_opts)
  end

  @spec init_app(module(), map()) :: {:ok, tuple()}
  def init_app(module, child_opts) when is_map(child_opts) do
    module
    |> Service.app_modules()
    |> Enum.map(&{&1.get_parent_module(), child_opts})
    |> Supervisor.init(strategy: :one_for_one)
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.Behaviours.AppBehaviour

      @behaviour AppBehaviour

      def start_link(opts), do: AppBehaviour.start_app_link(__MODULE__, opts)

      use Supervisor, shutdown: :infinity

      @impl Supervisor
      def init(opts), do: AppBehaviour.init_app(__MODULE__, opts)
    end
  end
end
