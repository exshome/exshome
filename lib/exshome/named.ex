defmodule Exshome.Named do
  @moduledoc """
  Module for common operations with named modules.
  """

  @callback name() :: String.t()

  defmacro __using__(name) when is_binary(name) do
    quote do
      import Exshome.Tag, only: [add_tag: 1]

      alias Exshome.Named
      add_tag({Named, unquote(name)})
      @behaviour Named

      @impl Named
      def name, do: unquote(name)
    end
  end
end
