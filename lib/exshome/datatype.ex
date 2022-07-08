defmodule Exshome.DataType do
  @moduledoc """
  Stores generic ways to work with custom datatypes.
  """

  @type t() :: atom()

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    NimbleOptions.validate!(
      module.__config__(),
      base_type: [
        type: :atom,
        required: true
      ],
      name: [
        type: :string,
        required: true
      ]
    )
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.DataType

      import Exshome.Tag, only: [add_tag: 1]

      use Exshome.Named, "datatype:#{unquote(config[:name])}"
      use Ecto.Type

      add_tag(DataType)

      def __config__, do: unquote(config)

      @after_compile {DataType, :validate_module!}

      @impl Ecto.Type
      def type, do: unquote(config[:base_type])

      @impl Ecto.Type
      def cast(data), do: Ecto.Type.cast(type(), data)

      @impl Ecto.Type
      def dump(data), do: Ecto.Type.dump(type(), data)

      @impl Ecto.Type
      def load(data), do: Ecto.Type.load(type(), data)

      defoverridable(Ecto.Type)
    end
  end
end
