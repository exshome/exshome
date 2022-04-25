defmodule ExshomeWebTest.Live.AppTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.App
  alias ExshomeWeb.Live.ClockApp

  describe "validate_module!/2" do
    test "works fine with valid module" do
      App.validate_module!(%Macro.Env{module: ClockApp}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise NimbleOptions.ValidationError, fn ->
        App.validate_module!(%Macro.Env{module: ClockApp.Index}, "some_bytecode")
      end
    end
  end
end
