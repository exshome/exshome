defmodule Exshome.DataType do
  @moduledoc """
  Stores generic ways to work with custom datatypes.
  """
  alias Exshome.DataType.Unknown

  @type t() :: atom() | Unknown
  @type parse_result() :: {:ok, any()} | {:error, String.t()}

  @callback validate(value :: any(), validation :: atom(), opts :: any()) :: parse_result()

  @optional_callbacks [validate: 3]

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
      ],
      validations: [
        type: {:list, :atom}
      ]
    )
  end

  @spec parse(t(), value :: any(), validations :: %{atom() => any()}) :: parse_result()
  def parse(module, value, validations \\ %{}) do
    raise_if_not_datatype!(module)

    case Ecto.Type.cast(module, value) do
      {:ok, value} ->
        validate(module, value, validations)

      _ ->
        {:error, "Invalid value #{inspect(value)} for #{name(module)}"}
    end
  end

  @spec validate(t(), value :: any(), %{atom() => any()}) :: parse_result()
  defp validate(module, value, validations) do
    available_validations = MapSet.new(module.__config__[:validations] || [])

    {validations, unknown_validations} =
      Enum.split_with(validations, fn {key, _opts} -> key in available_validations end)

    case unknown_validations do
      [] ->
        reduce_validations(module, {:ok, value}, validations)

      _ ->
        {:error, "Unknown validations #{inspect(unknown_validations)} for #{name(module)}"}
    end
  end

  @spec reduce_validations(t(), parse_result(), Keyword.t()) :: parse_result()
  defp reduce_validations(_module, result, []), do: result

  defp reduce_validations(_module, {:error, _reason} = result, _), do: result

  defp reduce_validations(module, {:ok, value}, [{validation, opts} | validations]) do
    reduce_validations(
      module,
      module.validate(value, validation, opts),
      validations
    )
  end

  @spec icon(t()) :: String.t()
  def icon(Unknown), do: "⚠️"

  def icon(module) do
    raise_if_not_datatype!(module)
    module.__config__()[:icon]
  end

  @spec name(t()) :: String.t()
  def name(Unknown), do: "unknown"

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

      @behaviour DataType

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
