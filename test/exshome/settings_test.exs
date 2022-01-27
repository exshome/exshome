defmodule Exshome.SettingsTest do
  use Exshome.DataCase, async: true

  alias Exshome.Settings
  alias ExshomeTest.Fixtures

  describe "settings get_or_create/2" do
    test "creates new settings or returns existing ones" do
      settings_name = "settings_#{Fixtures.unique_integer()}"
      default_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      create_result = Settings.get_or_create(settings_name, default_data)

      assert %Settings{
               name: ^settings_name,
               data: ^default_data,
               version: 1
             } = create_result

      another_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      existing_result = Settings.get_or_create(settings_name, another_data)
      assert create_result == existing_result
    end
  end

  describe "settings update!/2" do
    setup do
      settings_name = "settings_#{Fixtures.unique_integer()}"
      default_data = %{"key_#{Fixtures.unique_integer()}" => "some_value"}
      settings = Settings.get_or_create(settings_name, default_data)
      %{settings: settings}
    end

    test "adds extra fields, keeps exsisting ones", %{settings: %Settings{name: name, data: data}} do
      extra_data = %{"key_#{Fixtures.unique_integer()}" => "extra value"}
      assert %Settings{data: new_data} = Settings.update!(name, extra_data)
      compare_data(data, new_data)
      compare_data(extra_data, new_data)
    end

    test "fails for unknown settings" do
      unknown_settings = "settings_#{Fixtures.unique_integer()}"

      assert_raise(Ecto.NoResultsError, fn ->
        Settings.update!(unknown_settings, %{})
      end)
    end

    test "updates the existing value", %{settings: %Settings{name: name, data: data}} do
      existing_key = data |> Map.keys() |> List.first()
      random_value = Fixtures.unique_integer()
      refute data[existing_key] == random_value

      assert %Settings{data: %{^existing_key => ^random_value}} =
               Settings.update!(name, %{existing_key => random_value})
    end

    defp compare_data(%{} = expected, %{} = existing) do
      data =
        for key <- Map.keys(expected), into: %{} do
          {key, existing[key] || :unknown_value}
        end

      assert expected == data
    end
  end
end
