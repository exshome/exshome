defmodule ExshomeTest.VariableTest do
  use Exshome.DataCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Variable
  alias ExshomePlayer.Variables.Duration
  alias ExshomeTest.TestRegistry

  describe "set_value/2" do
    test "raises for invalid dependency" do
      assert_raise(RuntimeError, ~r/.*not a Variable.*/, fn ->
        Variable.set_value(:invalid_dependency, :test)
      end)
    end

    test "raises for not started variable" do
      assert_raise(MatchError, ~r/.*Unable to find.*/, fn ->
        Variable.set_value(Duration, "some_path#{unique_integer()}")
      end)
    end

    test "raises for readonly dependency" do
      TestRegistry.start_dependency(Duration)

      {:error, reason} = Variable.set_value(Duration, "some_path#{unique_integer()}")
      assert reason =~ ~r/.*readonly.*/
    end
  end

  describe "validate_module!/2" do
    test "works fine with valid module" do
      Variable.validate_module!(%Macro.Env{module: Duration}, "some_bytecode")
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
