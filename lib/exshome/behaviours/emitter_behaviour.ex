defmodule Exshome.Behaviours.EmitterBehaviour do
  @moduledoc """
  Allows to create implementations of specific emitter types.
  """

  @callback emitter_type() :: module()
end
