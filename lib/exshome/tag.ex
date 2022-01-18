defmodule Exshome.Tag do
  @moduledoc """
  A registry for tagged modules.
  """

  @tagged_modules_key :tagged_modules
  @tag_mapping_key :tag_mapping
  @not_found :not_found

  defprotocol Tagged do
    @spec tags(t()) :: [atom()]
    def tags(data)
  end

  defmacro add_tag(tag) do
    quote do
      unless Module.has_attribute?(__MODULE__, :tag) do
        Module.register_attribute(__MODULE__, :tag, persist: true, accumulate: true)

        defimpl Exshome.Tag.Tagged do
          def tags(_) do
            @protocol.tags(@for)
          end
        end
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

  @spec tagged_modules() :: [module()]
  def tagged_modules do
    case :persistent_term.get({__MODULE__, @tagged_modules_key}, @not_found) do
      @not_found -> refresh_tagged_modules()
      mapping -> mapping
    end
  end

  @spec refresh_tagged_modules() :: [module()]
  def refresh_tagged_modules do
    modules = compute_tagged_modules()
    :ok = :persistent_term.put({__MODULE__, @tagged_modules_key}, modules)
    modules
  end

  defp compute_tagged_modules do
    available_modules = Protocol.extract_impls(Tagged, :code.get_path())

    for module <- available_modules,
        module.__info__(:attributes)
        |> Keyword.has_key?(:tag) do
      module
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
    mapping = compute_tag_mapping()
    :ok = :persistent_term.put({__MODULE__, @tag_mapping_key}, mapping)
    mapping
  end

  defp compute_tag_mapping do
    modules =
      for module <- refresh_tagged_modules(),
          tag <- Tagged.tags(module) do
        case tag do
          {top_level_key, key} -> {top_level_key, {key, module}}
          key -> {key, module}
        end
      end

    modules
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {key, value} ->
      into = if Keyword.keyword?(value), do: %{}, else: MapSet.new()
      value = Enum.into(value, into)
      {key, value}
    end)
    |> Enum.into(%{})
  end
end
