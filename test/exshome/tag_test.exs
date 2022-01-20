defmodule ExshomeTest.TagTest do
  use ExUnit.Case, async: true
  alias Exshome.Tag

  describe "Check tag logic" do
    test "check tag_mapping after refresh" do
      assert Tag.refresh_tag_mapping() == Tag.tag_mapping()
    end
  end

  test "compute_tag_mapping" do
    result =
      Tag.compute_tag_mapping(
        module1: [:tag1, tag2: :tag2_value1],
        module2: [:tag1, :tag3, tag2: :tag2_value2]
      )

    assert result == %{
             tag1: MapSet.new([:module1, :module2]),
             tag2: %{tag2_value1: :module1, tag2_value2: :module2},
             tag3: MapSet.new([:module2])
           }
  end

  test "tag_mapping with nested string keys" do
    result =
      Tag.compute_tag_mapping(
        module1: [tag: "tag1"],
        module2: [tag: "tag2"]
      )

    assert result == %{tag: %{"tag1" => :module1, "tag2" => :module2}}
  end

  test "tag_mapping with nested atom keys" do
    result =
      Tag.compute_tag_mapping(
        module1: [tag: :tag1],
        module2: [tag: :tag2]
      )

    assert result == %{tag: %{tag1: :module1, tag2: :module2}}
  end

  test "tag_mapping with duplicate values" do
    assert_raise(RuntimeError, ~r/.*duplicate values.*/, fn ->
      Tag.compute_tag_mapping(
        module1: [tag: :tag],
        module1: [tag: :tag]
      )
    end)
  end

  test "tag_mapping with same key" do
    assert_raise(RuntimeError, ~r/.*duplicate keys.*/, fn ->
      Tag.compute_tag_mapping(
        module1: [tag: :tag],
        module2: [tag: :tag]
      )
    end)
  end

  test "tag_mapping with mixed types" do
    assert_raise(RuntimeError, ~r/.*mixed types.*/, fn ->
      Tag.compute_tag_mapping(
        module1: [tag: :tag],
        module2: [:tag]
      )
    end)
  end
end
