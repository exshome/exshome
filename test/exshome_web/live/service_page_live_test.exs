defmodule ExshomeWebTest.Live.ServicePageLiveTest do
  use ExUnit.Case, async: true
  alias ExshomeWeb.Live.ServicePageLive
  import ExshomeTest.MacroHelpers, only: [compile_with_settings: 2]

  describe "actions_with_pages/1" do
    test "does not have :preview" do
      for module <- ServicePageLive.service_pages() do
        assert :preview not in ServicePageLive.actions_with_pages(module)
      end
    end
  end

  describe "__using__/1" do
    test "valid settings, empty dependencies" do
      compile_with_settings(
        ServicePageLive,
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
        ServicePageLive,
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
        compile_with_settings(ServicePageLive, prefix: "invalid_prefix")
      end
    end

    test "invalid view module" do
      assert_raise RuntimeError, ~r/"invalid_view_module"/, fn ->
        compile_with_settings(
          ServicePageLive,
          prefix: :valid_prefix,
          view_module: "invalid_view_module"
        )
      end
    end

    test "missing required actions" do
      assert_raise RuntimeError, ~r/:index, :preview/, fn ->
        compile_with_settings(
          ServicePageLive,
          prefix: :valid_prefix,
          view_module: ExshomeWeb.ClockView,
          actions: []
        )
      end
    end

    test "invalid dependency key" do
      assert_raise RuntimeError, ~r/"invalid_dependency_key"/, fn ->
        compile_with_settings(
          ServicePageLive,
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
          ServicePageLive,
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
          ServicePageLive,
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
  end
end
