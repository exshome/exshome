defmodule Exshome.Mappings.DatatypeByNameMapping do
  @moduledoc """
  Computes datatype by name mapping.
  """

  alias Exshome.Behaviours.{CustomMappingBehaviour, DatatypeBehaviour}
  @behaviour CustomMappingBehaviour

  @impl CustomMappingBehaviour
  def compute_custom_mapping(%{DatatypeBehaviour => datatypes}) do
    for datatype <- datatypes, into: %{} do
      {datatype.__datatype_config__()[:name], datatype}
    end
  end
end
