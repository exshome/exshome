defmodule ExshomeWebTest.DatatypeComponentTest do
  use ExshomeWebTest.ConnCase, async: true
  alias Exshome.Datatype
  alias ExshomeWeb.DatatypeComponent

  test "Every DataType has own renderer" do
    renderers =
      DatatypeComponent.available_renderers()
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
