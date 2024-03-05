defmodule Exshome.Mappings.DatatypeComponentsMapping do
  @moduledoc """
  Allows to find compoents by their datatype.
  """

  alias Exshome.Behaviours.CustomMappingBehaviour
  alias Exshome.Behaviours.DatatypeComponentBehaviour

  @behaviour CustomMappingBehaviour

  @impl CustomMappingBehaviour
  def compute_custom_mapping(%{DatatypeComponentBehaviour => components}) do
    items =
      for component <- components,
          dataype <- component.datatypes(),
          do: {dataype, component}

    groups = Enum.group_by(items, &elem(&1, 0), &elem(&1, 1))

    conflicts = for item = {_, [_, _ | _]} <- groups, into: %{}, do: item

    Enum.any?(conflicts) && raise("Conflicts: #{inspect(conflicts)}")

    Map.new(groups, fn {k, [v]} -> {k, v} end)
  end
end
