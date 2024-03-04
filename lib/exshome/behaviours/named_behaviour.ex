defmodule Exshome.Behaviours.NamedBehaviour do
  @moduledoc """
  Behaviour for named items.
  """

  @callback get_name() :: String.t()
end
