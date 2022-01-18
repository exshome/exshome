defmodule Exshome.Tag do
  @moduledoc """
  A registry for tagged modules.
  """

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
    available_modules =
      if Protocol.consolidated?(Tagged) do
        {:consolidated, modules} = Tagged.__protocol__(:impls)
        modules
      else
        otp_prefix = :code.lib_dir()

        consolidation_paths =
          :code.get_path()
          |> Enum.filter(&(not :lists.prefix(otp_prefix, &1)))

        Protocol.extract_impls(Tagged, consolidation_paths)
      end

    for module <- available_modules,
        module.__info__(:attributes)
        |> Keyword.has_key?(:tag) do
      module
    end
  end

  @spec tag_mapping() :: map()
  def tag_mapping do
    modules =
      for module <- tagged_modules(),
          tag <- Tagged.tags(module) do
        case tag do
          {top_level_key, key} -> {top_level_key, {key, module}}
          key -> {key, module}
        end
      end

    modules
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Enum.map(fn {key, value} ->
      if Keyword.keyword?(value) do
        {key, Enum.into(value, %{})}
      else
        {key, MapSet.new(value)}
      end
    end)
    |> Enum.into(%{})
  end
end
