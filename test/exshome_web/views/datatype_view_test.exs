defmodule ExshomeWebTest.DatatypeViewTest do
  use ExshomeWeb.ConnCase, async: true
  alias Exshome.Datatype
  alias ExshomeWeb.DatatypeView

  test "Every DataType has own renderer" do
    renderers =
      DatatypeView.available_renderers()
      |> Map.keys()
      |> MapSet.new()

    missing_renderers =
      MapSet.difference(
        Datatype.available_types(),
        renderers
      )

    assert Enum.empty?(missing_renderers)
  end
end
