defmodule ExshomeTest.DatatypeTest do
  @moduledoc """
  Test edge cases for datatypes.
  """
  use ExUnit.Case, async: true

  alias Exshome.DataType

  describe "validate_module!/2" do
    test "calls validate_config!/2" do
      DataType.validate_module!(
        %Macro.Env{
          module: DataType.String
        },
        "some_bytecode"
      )
    end
  end
end
