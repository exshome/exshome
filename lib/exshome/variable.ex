defmodule Exshome.Variable do
  @moduledoc """
  Variable-related logic.
  """

  defmacro __using__(config) do
    quote do
      use Exshome.Dependency.GenServerDependency, unquote(config)
    end
  end
end
