defmodule Exshome.Tag do
  @moduledoc """
  A registry for tagged modules.
  """

  alias Exshome.Tag.Tagged

  @tag_mapping_key :tag_mapping
  @not_found :not_found

  defmacro add_tag(tag) do
    quote do
      unless Module.has_attribute?(__MODULE__, :tag) do
        Module.register_attribute(__MODULE__, :tag, persist: true, accumulate: true)

        defimpl Exshome.Tag.Tagged do
          def tags(_) do
            @protocol.tags(@for)
          end
        end

        @tag unquote(Exshome.Tag.Tagged)
      end

      @tag unquote(tag)
    end
  end

  defimpl Tagged, for: Atom do
    def tags(module) do
      :attributes
      |> module.__info__()
      |> Keyword.get_values(:tag)
      |> List.flatten()
    end
  end

  @spec tag_mapping() :: map()
  def tag_mapping do
    case :persistent_term.get({__MODULE__, @tag_mapping_key}, @not_found) do
      @not_found -> refresh_tag_mapping()
      mapping -> mapping
    end
  end

  @spec refresh_tag_mapping() :: map()
  def refresh_tag_mapping do
    modules = compute_tagged_modules()
    mapping = compute_tag_mapping(modules)
    :ok = :persistent_term.put({__MODULE__, @tag_mapping_key}, mapping)
    mapping
  end

  def compute_tagged_modules do
    available_modules = Protocol.extract_impls(Tagged, :code.get_path())

    for module <- available_modules,
        module.__info__(:attributes)
        |> Keyword.has_key?(:tag) do
      {module, Tagged.tags(module)}
    end
  end

  def compute_tag_mapping(params) do
    tag_data =
      for {module, tags} <- params,
          tag <- tags do
        case tag do
          atom when is_atom(atom) ->
            %{type: :simple, key: tag, value: module}

          {parent_key, child_key} when is_atom(child_key) ->
            %{type: :nested_atom_map, key: parent_key, child_key: child_key, value: module}

          {parent_key, child_key} when is_binary(child_key) ->
            %{type: :nested_binary_map, key: parent_key, child_key: child_key, value: module}
        end
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
