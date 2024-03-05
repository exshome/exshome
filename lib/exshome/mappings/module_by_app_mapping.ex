defmodule Exshome.Mappings.ModuleByAppMapping do
  @moduledoc """
  Computes mapping for modules by apps.
  """
  alias Exshome.Behaviours.BelongsToAppBehaviour
  alias Exshome.Behaviours.CustomMappingBehaviour

  @behaviour CustomMappingBehaviour
  def compute_custom_mapping(%{BelongsToAppBehaviour => modules}) do
    modules
    |> Enum.group_by(& &1.app())
    |> Map.new(fn {k, v} -> {k, MapSet.new(v)} end)
  end
end
