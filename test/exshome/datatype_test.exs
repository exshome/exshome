defmodule ExshomeTest.DatatypeTest do
  @moduledoc """
  Test edge cases for datatypes.
  """
  use ExUnit.Case, async: true

  alias Exshome.Datatype

  describe "validate_module!/2" do
    test "calls validate_config!/2" do
      Datatype.validate_module!(
        %Macro.Env{
          module: Datatype.String
        },
        "some_bytecode"
      )
    end
  end

  describe "parse/2" do
    test "raises if not a valid datatype" do
      assert_raise RuntimeError, ~r/.*:unknown_type*./, fn ->
        Datatype.parse(:unknown_type, 1)
      end
    end

    test "does not allow unknown validations" do
      {:error, reason} = Datatype.parse(Datatype.Integer, 1, unknown_validation: 1)
      assert reason =~ "unknown_validation"
    end
  end
end
