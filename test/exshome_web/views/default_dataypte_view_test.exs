defmodule ExshomeWebTest.DefaultDatatypeViewTest do
  use ExshomeWeb.ConnCase, async: true

  import ExshomeTest.Fixtures

  alias Exshome.DataType
  alias ExshomeWeb.DataTypeView
  alias Phoenix.LiveView

  describe "Boolean" do
    test "render_value/1" do
      value = Enum.random([true, false])
      assert datatype_value(DataType.Boolean, value) == "#{value}"
    end

    test "render_input/1" do
      value = Enum.random([true, false])
      assert datatype_input(DataType.Boolean, value) =~ "checkbox"
    end
  end

  describe "String" do
    test "render_value/1" do
      value = "random_string#{unique_integer()}"
      assert datatype_value(DataType.String, value) == value
    end

    test "render_input/1" do
      value = "random_string#{unique_integer()}"
      assert datatype_input(DataType.String, value) =~ ~r/value="#{value}"/
    end
  end

  describe "Integer" do
    test "render_value/1" do
      value = unique_integer()
      assert datatype_value(DataType.Integer, value) == "#{value}"
    end

    test "render_input/1" do
      value = unique_integer()
      assert datatype_input(DataType.Integer, value) =~ ~r/value="#{value}"/
    end
  end

  defp datatype_value(datatype, value) do
    %{type: datatype, value: value}
    |> DataTypeView.datatype_value()
    |> rendered_to_string()
  end

  defp datatype_input(datatype, value, name \\ "name#{unique_integer()}") do
    %{__changed__: %{}}
    |> LiveView.assign(type: datatype, value: value, name: name)
    |> DataTypeView.datatype_input()
    |> rendered_to_string()
  end
end
