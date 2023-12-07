defmodule ExshomeTest.Behaviours.AppBehaviourTest do
  use ExUnit.Case, async: true
  alias Exshome.Behaviours.AppBehaviour

  describe "validate_module!/2" do
    test "works fine with valid module" do
      AppBehaviour.validate_module!(%Macro.Env{module: ExshomeClock}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise UndefinedFunctionError, fn ->
        AppBehaviour.validate_module!(
          %Macro.Env{module: ExshomeClock.Web.Live.Clock},
          "some_bytecode"
        )
      end
    end
  end
end
