defmodule ExshomeWebTest.Live.AppTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.App

  describe "validate_module!/2" do
    test "works fine with valid module" do
      App.validate_module!(%Macro.Env{module: ExshomeClock}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise NimbleOptions.ValidationError, fn ->
        App.validate_module!(%Macro.Env{module: ExshomeClock.Web.Live.Index}, "some_bytecode")
      end
    end
  end
end
