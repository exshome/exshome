defmodule ExshomeTest.SettingsTest do
  use Exshome.DataCase, async: true
  import ExshomeTest.MacroHelpers, only: [compile_with_settings: 2]

  alias Exshome.Settings

  describe "work with settings modules" do
    test "we can save default settings for each module" do
      for module <- Settings.available_modules() do
        assert %{__struct__: ^module} =
                 module |> Settings.get_settings() |> Settings.save_settings()
      end
    end

    test "default settings are valid" do
      for module <- Settings.available_modules() do
        assert {:ok, %{__struct__: ^module}} =
                 module
                 |> struct(module.default_values())
                 |> Settings.valid_changes?()
      end
    end

    test "unable to work with invalid settings module" do
      assert_raise RuntimeError, fn ->
        Settings.get_settings(:unknown_module)
      end
    end
  end

  describe "__using__/1" do
    test "macro works well" do
      result =
        compile_with_settings(
          Settings,
          name: "some name",
          fields: [[name: :data, db_type: :string, type: String]]
        )

      assert result
    end
  end
end
