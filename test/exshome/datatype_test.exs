defmodule ExshomeTest.DatatypeTest do
  @moduledoc """
  Test edge cases for datatypes.
  """
  use ExUnit.Case, async: true

  alias Exshome.Behaviours.DatatypeBehaviour
  alias Exshome.Datatype

  describe "validate_module!/2" do
    test "calls validate_config!/2" do
      DatatypeBehaviour.validate_module!(
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

  describe "to_string/2" do
    test "returns error for unknown value" do
      for type <- Datatype.available_types() do
        assert {:error, error_message} = Datatype.to_string(type, Datatype.Unknown)
        assert is_binary(error_message)
      end
    end

    test "returns valid string for default value" do
      for type <- Datatype.available_types() do
        default_value = type.__datatype_config__()[:default]

        {:ok, value} = Datatype.to_string(type, default_value)
        assert is_binary(value)
      end
    end
  end
end
