defmodule Exshome.Tag.Mapping do
  @moduledoc """
  Computes the tag mapping.
  """

  @enforce_keys [:type, :key, :value]
  defstruct [:type, :key, :child_key, :value]

  @type t() :: %__MODULE__{
          type: :simple | :nested_atom_map | :nested_binary_map,
          key: any(),
          child_key: String.t() | atom(),
          value: module()
        }

  def compute_tag_mapping(params) do
    tag_data =
      for {module, tags} <- params,
          tag <- tags do
        to_tag_data(module, tag)
      end

    tag_data = Enum.group_by(tag_data, & &1.key)

    for {key, values} <- tag_data, into: %{} do
      nested_values =
        values
        |> validate_partial_mapping(key)
        |> values_to_mapping()

      {key, nested_values}
    end
  end

  defp to_tag_data(module, tag) when is_atom(tag) do
    %__MODULE__{type: :simple, key: tag, value: module}
  end

  defp to_tag_data(module, {parent_key, child_key}) when is_atom(child_key) do
    %__MODULE__{
      type: :nested_atom_map,
      key: parent_key,
      child_key: child_key,
      value: module
    }
  end

  defp to_tag_data(module, {parent_key, child_key}) when is_binary(child_key) do
    %__MODULE__{
      type: :nested_binary_map,
      key: parent_key,
      child_key: child_key,
      value: module
    }
  end

  def validate_partial_mapping([%__MODULE__{type: type} | _] = values, key) do
    case Enum.uniq_by(values, & &1.type) do
      [_single_type] ->
        :ok

      data ->
        modules = Enum.map(data, & &1.value)
        raise "#{key} has mixed types in modules: #{inspect(modules)}"
    end

    duplicate_values = duplicated_by(values, :value)

    unless duplicate_values == [] do
      raise "#{key} has duplicate values: #{inspect(duplicate_values)}"
    end

    unless type == :simple do
      duplicate_keys = duplicated_by(values, :child_key)

      unless duplicate_keys == [] do
        raise "#{key} has duplicate keys: #{inspect(duplicate_keys)}"
      end
    end

    values
  end

  defp duplicated_by(values, field) do
    values
    |> Enum.frequencies_by(fn value -> Map.from_struct(value)[field] end)
    |> Enum.filter(&(elem(&1, 1) > 1))
    |> Enum.map(&elem(&1, 0))
  end

  def values_to_mapping([%__MODULE__{type: :simple} | _] = values) do
    values |> Enum.map(& &1.value) |> MapSet.new()
  end

  def values_to_mapping([%__MODULE__{type: type} | _] = values)
      when type in [:nested_atom_map, :nested_binary_map] do
    values |> Enum.map(&{&1.child_key, &1.value}) |> Enum.into(%{})
  end
end
