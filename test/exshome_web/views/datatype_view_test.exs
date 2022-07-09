defmodule ExshomeWebTest.DatatypeViewTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.DataType
  alias ExshomeWeb.DataTypeView

  test "Every DataType has own renderer" do
    renderers =
      DataTypeView.available_renderers()
      |> Map.keys()
      |> MapSet.new()

    missing_renderers =
      MapSet.difference(
        DataType.available_types(),
        renderers
      )

    assert Enum.empty?(missing_renderers)
  end
end
