defmodule ExshomeTest.Dependency.LifecycleTest do
  use ExUnit.Case, async: true
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  import ExshomeTest.MacroHelpers, only: [compile_with_settings: 2]

  describe "__using__/1" do
    test "works fine" do
      compile_with_settings(Lifecycle, key: :some_key)
    end

    test "raises on invalid key" do
      assert_raise RuntimeError, ~r/:name/, fn ->
        compile_with_settings(Lifecycle, key: :name)
      end
    end
  end
end
