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

    validate_tag_data(tag_data)

    for {key, [%{type: type} | _] = values} <- tag_data, into: %{} do
      nested_values =
        case type do
          :simple -> values |> Enum.map(& &1.value) |> MapSet.new()
          _ -> values |> Enum.map(&{&1.child_key, &1.value}) |> Enum.into(%{})
        end

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

  defp validate_tag_data(tag_data) do
    for {key, values} <- tag_data do
      case Enum.uniq_by(values, & &1.type) do
        [_single_type] ->
          :ok

        data ->
          modules = Enum.map(data, & &1.value)
          raise "#{key} has mixed types in modules: #{inspect(modules)}"
      end

      duplicate_values =
        values
        |> Enum.frequencies_by(& &1.value)
        |> Enum.filter(&(elem(&1, 1) > 1))
        |> Enum.map(&elem(&1, 0))

      unless duplicate_values == [] do
        raise "#{key} has duplicate values: #{inspect(duplicate_values)}"
      end

      [%{type: type} | _] = values

      unless type == :simple do
        duplicate_keys =
          values
          |> Enum.frequencies_by(& &1.child_key)
          |> Enum.filter(&(elem(&1, 1) > 1))
          |> Enum.map(&elem(&1, 0))

        unless duplicate_keys == [] do
          raise "#{key} has duplicate keys: #{inspect(duplicate_keys)}"
        end
      end
    end
  end
end
