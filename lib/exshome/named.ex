defmodule Exshome.Named do
  @moduledoc """
  Module for common operations with named modules.
  """

  @callback name() :: String.t()

  @spec get_module_by_name(String.t()) :: {:ok, module()} | {:error, :not_found}
  def get_module_by_name(name) when is_binary(name) do
    module =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> Map.get(name)

    if module do
      {:ok, module}
    else
      {:error, :not_found}
    end
  end

  defmacro __using__(name) do
    quote do
      import Exshome.Tag, only: [add_tag: 1, add_tag: 2]

      alias Exshome.Named
      add_tag(Named, key: unquote(name))
      @behaviour Named

      @impl Named
      def name, do: unquote(name)
    end
  end
end
