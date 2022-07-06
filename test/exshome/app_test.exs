defmodule ExshomeTest.AppTest do
  use ExUnit.Case, async: true
  alias Exshome.App

  describe "validate_module!/2" do
    test "works fine with valid module" do
      App.validate_module!(%Macro.Env{module: ExshomeClock}, "some_bytecode")
    end

    test "raises for invalid module" do
      assert_raise NimbleOptions.ValidationError, fn ->
        App.validate_module!(%Macro.Env{module: ExshomeClock.Web.Live.Clock}, "some_bytecode")
      end
    end
  end
end
