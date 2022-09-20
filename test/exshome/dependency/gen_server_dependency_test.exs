defmodule ExshomeTest.Dependency.GenServerDependencyTest do
  @moduledoc """
  Test GenServerDependency API.
  """
  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency.GenServerDependency

  describe "validate_module!/2" do
    test "calls validate_config!/2" do
      GenServerDependency.validate_module!(
        %Macro.Env{
          module: ExshomeClock.Services.UtcTime
        },
        "some_bytecode"
      )
    end
  end

  describe "validate_dependency_config!/1" do
    test "works fine with correct data" do
      GenServerDependency.validate_dependency_config!(name: "some_name")
    end

    test "raises for incorrect data" do
      assert_raise(NimbleOptions.ValidationError, fn ->
        GenServerDependency.validate_dependency_config!([])
      end)
    end
  end
end
