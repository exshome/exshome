defmodule Exshome.Behaviours.DatatypeComponentBehaviour do
  @moduledoc """
  Allows to render datatype components.
  """

  alias Phoenix.LiveView.Rendered

  @callback datatypes() :: MapSet.t(module())
  @callback render_value(assigns :: map()) :: Rendered.t()
  @callback render_input(assigns :: map()) :: Rendered.t()
end
