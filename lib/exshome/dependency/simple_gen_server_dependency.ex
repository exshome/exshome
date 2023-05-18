defmodule Exshome.Dependency.SimpleGenServerDependency do
  @moduledoc """
  This module stores generic API for GenServer based dependencies.
  """
  alias Exshome.Dependency

  @spec modules(app :: atom()) :: MapSet.t(Dependency.dependency())
  def modules(app) when is_atom(app) do
    Map.get(
      Exshome.Tag.tag_mapping(),
      {__MODULE__, app},
      MapSet.new()
    )
  end

  defmacro __using__(config) do
    quote do
      use Exshome.Dependency.GenServerDependency, unquote(config)
      use Exshome.Named, "dependency:#{unquote(config[:name])}"

      @impl Exshome.Dependency
      def type, do: Exshome.Dependency
    end
  end
end
