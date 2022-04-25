defmodule ExshomeWeb.Live.App do
  @moduledoc """
  Generic module for live applications.
  """

  @callback pages() :: list(Atom.t())
  @callback view_module() :: Atom.t()
  @callback preview() :: Atom.t()
  @callback prefix() :: Atom.t()

  def validate_config!(%Macro.Env{module: module}, _bytecode) do
    module.__config__()
    |> NimbleOptions.validate!(
      pages: [type: {:list, :atom}],
      prefix: [type: :atom],
      preview: [type: :atom],
      view_module: [type: :atom]
    )
  end

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.Live.App
      @behaviour App
      @after_compile {App, :validate_config!}

      def __config__, do: unquote(config)

      @impl App
      def pages, do: Keyword.fetch!(__MODULE__.__config__(), :pages)

      @impl App
      def prefix, do: Keyword.fetch!(__MODULE__.__config__(), :prefix)

      @impl App
      def preview, do: Keyword.fetch!(__MODULE__.__config__(), :preview)

      @impl App
      def view_module, do: Keyword.fetch!(__MODULE__.__config__(), :view_module)

      def path(conn_or_endpoint, action, params \\ []) do
        apply(
          ExshomeWeb.Router.Helpers,
          :"#{prefix()}_path",
          [conn_or_endpoint, action, params]
        )
      end
    end
  end
end
