defmodule Exshome.Behaviours.EmitterBehaviour do
  @moduledoc """
  Allows to create implementations of specific emitter types.
  """

  @callback type() :: module()
  @callback app() :: module()
end
