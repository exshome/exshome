defmodule ExshomeTest.Variable.GenServerVariableTest do
  use ExshomeTest.DataCase, async: true

  import ExshomeTest.Fixtures
  alias Exshome.Variable
  alias Exshome.Variable.GenServerVariable
  alias ExshomePlayer.Variables.Duration
  alias ExshomeTest.TestRegistry

  describe "set_value/2" do
    test "raises for invalid dependency" do
      assert_raise(MatchError, ~r/.*:invalid_dependency*/, fn ->
        Variable.set_value(:invalid_dependency, :test)
      end)
    end

    test "raises for not started variable" do
      assert_raise(MatchError, ~r/.*Unable to find.*/, fn ->
        Variable.set_value(Duration, "some_path#{unique_integer()}")
      end)
    end

    test "produces error for readonly dependency" do
      TestRegistry.start_dependency(Duration)

      {:error, reason} = Variable.set_value(Duration, "some_path#{unique_integer()}")
      assert reason =~ ~r/.*readonly.*/
    end
  end

  describe "validate_module!/2" do
    test "works fine with valid module" do
      GenServerVariable.validate_module!(%Macro.Env{module: Duration}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise UndefinedFunctionError, fn ->
        GenServerVariable.validate_module!(
          %Macro.Env{module: __MODULE__},
          "some_bytecode"
        )
      end
    end
  end
end
