defmodule Exshome.Mappings.RouterByPrefixMapping do
  @moduledoc """
  Computes router by prefix mapping.
  """

  alias Exshome.Behaviours.{CustomMappingBehaviour, RouterBehaviour}
  @behaviour CustomMappingBehaviour

  @impl CustomMappingBehaviour
  def compute_custom_mapping(%{RouterBehaviour => routers}) do
    for router <- routers, into: %{} do
      {router.__router_config__()[:key], router}
    end
  end
end
