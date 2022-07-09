defmodule ExshomeWeb.DefaultDatatypeView do
  @moduledoc """
  Renders default datatypes.
  """
  alias Exshome.DataType
  import ExshomeWeb.DataTypeView, only: [register_renderer: 1]

  register_renderer(DataType.Boolean)
  register_renderer(DataType.Integer)
  register_renderer(DataType.String)
end
