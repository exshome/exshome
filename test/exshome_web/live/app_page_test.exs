defmodule ExshomeWebTest.Live.AppPageTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.AppPage
  alias ExshomeWeb.Live.ClockApp

  describe "validate_module!/2" do
    test "works fine with valid module" do
      AppPage.validate_module!(%Macro.Env{module: ClockApp.Index}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise NimbleOptions.ValidationError, fn ->
        AppPage.validate_module!(%Macro.Env{module: ClockApp}, "some_bytecode")
      end
    end
  end
end
