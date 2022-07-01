defmodule ExshomeTest.VariableTest do
  use ExUnit.Case, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Variable
  alias ExshomePlayer.Variables.Path

  describe "set_value!/2" do
    test "raises for invalid dependency" do
      assert_raise(RuntimeError, ~r/.*not a Variable.*/, fn ->
        Variable.set_value!(:invalid_dependency, :test)
      end)
    end

    test "raises for readonly dependency" do
      assert_raise(RuntimeError, ~r/.*readonly.*/, fn ->
        Variable.set_value!(Path, "some_path#{unique_integer()}")
      end)
    end
  end

  describe "validate_module!/2" do
    test "works fine with valid module" do
      Variable.validate_module!(%Macro.Env{module: Path}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise UndefinedFunctionError, fn ->
        Variable.validate_module!(
          %Macro.Env{module: __MODULE__},
          "some_bytecode"
        )
      end
    end
  end
end
