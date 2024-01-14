defmodule ExshomeWebTest.Live.AppPageTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.AppPage

  describe "validate_module!/2" do
    test "works fine with valid module" do
      AppPage.validate_module!(%Macro.Env{module: ExshomeClock.Live.Clock}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise UndefinedFunctionError, fn ->
        AppPage.validate_module!(%Macro.Env{module: ExshomeClock}, "some_bytecode")
      end
    end
  end
end
