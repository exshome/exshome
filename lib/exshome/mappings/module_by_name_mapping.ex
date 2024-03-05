defmodule Exshome.Mappings.ModuleByNameMapping do
  @moduledoc """
  Allows to find modules by their name.
  """

  alias Exshome.Behaviours.CustomMappingBehaviour
  alias Exshome.Behaviours.NamedBehaviour

  @behaviour CustomMappingBehaviour

  @impl CustomMappingBehaviour
  def compute_custom_mapping(%{NamedBehaviour => modules}) do
    groups = Enum.group_by(modules, & &1.get_name())

    conflicts = for item = {_, [_, _ | _]} <- groups, into: %{}, do: item

    Enum.any?(conflicts) && raise("Duplicate names: #{inspect(conflicts)}")

    Map.new(groups, fn {k, [v]} -> {k, v} end)
  end
end
