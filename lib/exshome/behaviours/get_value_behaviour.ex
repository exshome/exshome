defmodule Exshome.Behaviours.GetValueBehaviour do
  @moduledoc """
  Gets a value for specific dependency.
  """

  @callback get_value(module() | {module(), String.t()}) :: term()
end
