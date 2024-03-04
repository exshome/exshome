defmodule Exshome.Named do
  @moduledoc """
  Module for common operations with named modules.
  """

  @spec get_module_by_name(String.t()) :: {:ok, module()} | {:error, :not_found}
  def get_module_by_name(name) when is_binary(name) do
    module =
      Exshome.BehaviourMapping.custom_mapping()
      |> Map.fetch!(Exshome.Mappings.ModuleByName)
      |> Map.get(name)

    if module do
      {:ok, module}
    else
      {:error, :not_found}
    end
  end
end
