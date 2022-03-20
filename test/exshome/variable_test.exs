defmodule ExshomeTest.VariableTest do
  @moduledoc """
  Test Variable API.
  """
  use ExUnit.Case, async: true
  alias Exshome.Variable

  describe "validate_config/1" do
    test "works fine with correct data" do
      Variable.validate_config(
        name: "some_name",
        datatype: Exshome.DataType.String
      )
    end

    test "raises for incorrect data" do
      assert_raise(NimbleOptions.ValidationError, fn ->
        Variable.validate_config([])
      end)
    end
  end
end
