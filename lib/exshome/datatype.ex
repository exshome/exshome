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
      icon: [
        type: :string,
        required: true
      ],
      name: [
        type: :string,
        required: true
      ]
    )
  end

  @spec parse!(t(), value :: any()) :: any()
  def parse!(module, value) do
    {:ok, value} = try_parse_value(module, value)
    value
  end

  @spec try_parse_value(t(), value :: any()) :: {:ok, term()} | {:error, Keyword.t()} | :error
  def try_parse_value(module, value) do
    raise_if_not_datatype!(module)
    Ecto.Type.cast(module, value)
  end

  @spec icon(t()) :: String.t()
  def icon(module) do
    raise_if_not_datatype!(module)
    module.__config__()[:icon]
  end

  @spec name(t()) :: String.t()
  def name(module) do
    raise_if_not_datatype!(module)
    module.__config__()[:name]
  end

  @spec available_types() :: MapSet.t()
  def available_types do
    Map.fetch!(
      Exshome.Tag.tag_mapping(),
      __MODULE__
    )
  end

  defp raise_if_not_datatype!(module) when is_atom(module) do
    module_is_datatype =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    if !module_is_datatype do
      raise "#{inspect(module)} is not a DataType!"
    end
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
