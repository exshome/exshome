defmodule Exshome.App do
  @moduledoc """
  Generic module for live applications.
  """

  @callback namespace() :: atom()
  @callback pages() :: list(atom())
  @callback preview() :: atom()
  @callback prefix() :: atom()
  @callback template_root() :: String.t()

  @apps Application.compile_env(:exshome, Exshome.Application, [])[:apps] || []
  def apps, do: @apps

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _bytecode) do
    NimbleOptions.validate!(
      module.__config__(),
      pages: [type: {:list, :atom}, required: true],
      prefix: [type: :atom, required: true],
      preview: [type: :atom, required: true]
    )
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.App
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
