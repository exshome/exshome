defmodule Exshome.Tag do
  @moduledoc """
  A registry for tagged modules.
  """

  alias Exshome.Tag.{Mapping, Tagged}

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
    mapping = Mapping.compute_tag_mapping(modules)
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
end
