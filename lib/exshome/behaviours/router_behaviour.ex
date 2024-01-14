defmodule Exshome.Behaviours.RouterBehaviour do
  @moduledoc """
  Behaviour to gather application Exshome routers.
  """

  @callback __router_config__() :: keyword()

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    NimbleOptions.validate!(
      module.__router_config__(),
      key: [type: :string, required: true],
      app: [type: :atom, required: true],
      main_path: [type: :string, required: true],
      navbar: [
        type: {
          :list,
          {
            :keyword_list,
            [
              path: [type: :string, required: true],
              name: [type: :string, required: true],
              icon: [type: :string, required: true],
              extra_views: [type: {:list, :atom}]
            ]
          }
        }
      ],
      preview: [type: :atom, required: true]
    )
  end

  defmacro __using__(opts) do
    quote do
      use Phoenix.Router, helpers: false
      import Phoenix.LiveView.Router

      alias Exshome.Behaviours.RouterBehaviour
      @behaviour RouterBehaviour

      @impl RouterBehaviour
      def __router_config__, do: unquote(opts)

      @after_compile {RouterBehaviour, :validate_module!}
    end
  end
end
