defmodule Exshome.Datatype do
  @moduledoc """
  Stores generic ways to work with custom datatypes.
  """
  alias Exshome.BehaviourMapping
  alias Exshome.Behaviours.DatatypeBehaviour
  alias Exshome.Datatype.Unknown
  alias Exshome.Mappings.DatatypeByNameMapping

  @type t() :: atom() | Unknown
  @type parse_result() :: {:ok, any()} | {:error, String.t()}

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
    available_validations = MapSet.new(module.__datatype_config__()[:validations] || [])

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
    module.__datatype_config__()[:icon]
  end

  @spec name(t()) :: String.t()
  def name(Unknown), do: "unknown"

  def name(module) do
    raise_if_not_datatype!(module)
    module.__datatype_config__()[:name]
  end

  @spec(to_string(t(), any()) :: {:ok, String.t()}, {:error, String.t()})
  def to_string(module, value) do
    raise_if_not_datatype!(module)
    module.to_string(value)
  end

  @spec available_types() :: MapSet.t(module())
  def available_types do
    BehaviourMapping.behaviour_mapping!(DatatypeBehaviour)
  end

  @spec get_by_name(String.t()) :: t()
  def get_by_name(name) when is_binary(name) do
    DatatypeByNameMapping
    |> BehaviourMapping.custom_mapping!()
    |> Map.fetch(name)
    |> case do
      {:ok, module} ->
        if module_is_datatype?(module), do: module, else: Unknown

      _ ->
        Unknown
    end
  end

  defp raise_if_not_datatype!(module) when is_atom(module) do
    unless module_is_datatype?(module) do
      raise "#{inspect(module)} is not a DataType!"
    end
  end

  defp module_is_datatype?(module) do
    DatatypeBehaviour
    |> BehaviourMapping.behaviour_mapping!()
    |> MapSet.member?(module)
  end
end
