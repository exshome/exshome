defmodule ExshomeWeb.DataTypeView do
  @moduledoc """
  Renders datatypes.
  """

  use ExshomeWeb, :view
  alias Exshome.DataType

  @spec available_renderers() :: %{DataType.t() => module()}
  def available_renderers, do: Map.fetch!(Exshome.Tag.tag_mapping(), __MODULE__)

  @spec register_renderer(DataType.t()) :: any()
  defmacro register_renderer(datatype) do
    quote do
      import Exshome.Tag, only: [add_tag: 2]
      add_tag(unquote(__MODULE__), key: unquote(datatype))
    end
  end
end
