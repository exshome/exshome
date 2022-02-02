defmodule Exshome.Named do
  @moduledoc """
  Module for common operations with named modules.
  """

  @callback name() :: String.t()

  @spec get_module_by_type_and_name(module(), String.t()) :: module()
  def get_module_by_type_and_name(type, name) do
    module = get_module_by_name(name)

    module_type_matches =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(type)
      |> MapSet.member?(module)

    if module_type_matches do
      module
    else
      raise "#{inspect(module)} is not #{inspect(type)}"
    end
  end

  @spec get_module_by_name(String.t()) :: module()
  def get_module_by_name(name) when is_binary(name) do
    Exshome.Tag.tag_mapping()
    |> Map.fetch!(__MODULE__)
    |> Map.fetch!(name)
  end

  defmacro __using__(name) do
    quote do
      import Exshome.Tag, only: [add_tag: 1]

      alias Exshome.Named
      add_tag({Named, unquote(name)})
      @behaviour Named

      @impl Named
      def name, do: unquote(name)
    end
  end
end
