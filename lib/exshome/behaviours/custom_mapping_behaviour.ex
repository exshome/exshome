defmodule Exshome.Behaviours.CustomMappingBehaviour do
  @moduledoc """
  Allows to implement custom mappings from behaviour mapping.
  """

  @callback compute_custom_mapping(%{module() => MapSet.t(module())}) :: term()
end
