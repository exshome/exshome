defmodule ExshomeWebTest.Live.ServicePageLiveTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.ServicePageLive

  describe "__using__/1" do
    require ServicePageLive

    test "valid settings, empty dependencies" do
      compile_with_settings(
        prefix: :some_prefix,
        view_module: ExshomeWeb.ClockView,
        actions: [
          index: [],
          preview: []
        ]
      )
    end

    test "valid settings with dependencies" do
      compile_with_settings(
        prefix: :some_prefix,
        view_module: ExshomeWeb.ClockView,
        actions: [
          index: [
            {DependencyA, :key_a},
            {DependencyB, :key_b}
          ],
          preview: []
        ]
      )
    end

    test "invalid prefix" do
      assert_raise RuntimeError, ~r/"invalid_prefix"/, fn ->
        compile_with_settings(prefix: "invalid_prefix")
      end
    end

    test "invalid view module" do
      assert_raise RuntimeError, ~r/"invalid_view_module"/, fn ->
        compile_with_settings(
          prefix: :valid_prefix,
          view_module: "invalid_view_module"
        )
      end
    end

    test "missing required actions" do
      assert_raise RuntimeError, ~r/:index, :preview/, fn ->
        compile_with_settings(
          prefix: :valid_prefix,
          view_module: ExshomeWeb.ClockView,
          actions: []
        )
      end
    end

    test "invalid dependency key" do
      assert_raise RuntimeError, ~r/"invalid_dependency_key"/, fn ->
        compile_with_settings(
          prefix: :valid_prefix,
          view_module: ExshomeWeb.ClockView,
          actions: [
            index: [
              {ExshomeWeb.Dependency, "invalid_dependency_key"}
            ],
            preview: []
          ]
        )
      end
    end

    test "duplicate dependency keys" do
      assert_raise RuntimeError, ~r/:duplicate_dependency_key/, fn ->
        compile_with_settings(
          prefix: :valid_prefix,
          view_module: ExshomeWeb.ClockView,
          actions: [
            index: [
              {DependencyA, :duplicate_dependency_key},
              {DependencyB, :duplicate_dependency_key}
            ],
            preview: []
          ]
        )
      end
    end

    test "duplicate dependencies" do
      assert_raise RuntimeError, ~r/DuplicateDependency/, fn ->
        compile_with_settings(
          prefix: :valid_prefix,
          view_module: ExshomeWeb.ClockView,
          actions: [
            index: [
              {DuplicateDependency, :key_a},
              {DuplicateDependency, :key_b}
            ],
            preview: []
          ]
        )
      end
    end

    defp compile_with_settings(settings) do
      quote do
        ServicePageLive.__using__(unquote(settings))
      end
      |> Macro.expand(__ENV__)
      |> Macro.to_string()
    end
  end
end
