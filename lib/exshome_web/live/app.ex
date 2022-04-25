defmodule ExshomeWeb.Live.App do
  @moduledoc """
  Generic module for live applications.
  """
  alias Exshome.Tag

  @callback pages() :: list(atom())
  @callback view_module() :: atom()
  @callback preview() :: atom()
  @callback prefix() :: atom()

  def apps, do: Tag.tag_mapping() |> Map.fetch!(__MODULE__)

  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      pages: [type: {:list, :atom}, required: true],
      prefix: [type: :atom, required: true],
      preview: [type: :atom, required: true],
      view_module: [type: :atom, required: true]
    )
  end

  defmacro __using__(config) do
    quote do
      alias ExshomeWeb.Live.App
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(App)

      @behaviour App
      @after_compile {App, :validate_module!}

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
