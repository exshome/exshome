defmodule Exshome.ServiceSettingsTest do
  use Exshome.DataCase, async: true

  alias Exshome.ServiceSettings

  describe "service_settings" do
    alias Exshome.ServiceSettings.Settings

    import Exshome.ServiceSettingsFixtures

    @invalid_attrs %{settings: nil}

    test "list_service_settings/0 returns all service_settings" do
      settings = settings_fixture()
      assert ServiceSettings.list_service_settings() == [settings]
    end

    test "get_settings!/1 returns the settings with given id" do
      settings = settings_fixture()
      assert ServiceSettings.get_settings!(settings.id) == settings
    end

    test "create_settings/1 with valid data creates a settings" do
      valid_attrs = %{settings: %{}}

      assert {:ok, %Settings{} = settings} = ServiceSettings.create_settings(valid_attrs)
      assert settings.settings == %{}
    end

    test "create_settings/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ServiceSettings.create_settings(@invalid_attrs)
    end

    test "update_settings/2 with valid data updates the settings" do
      settings = settings_fixture()
      update_attrs = %{settings: %{}}

      assert {:ok, %Settings{} = settings} =
               ServiceSettings.update_settings(settings, update_attrs)

      assert settings.settings == %{}
    end

    test "update_settings/2 with invalid data returns error changeset" do
      settings = settings_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ServiceSettings.update_settings(settings, @invalid_attrs)

      assert settings == ServiceSettings.get_settings!(settings.id)
    end

    test "delete_settings/1 deletes the settings" do
      settings = settings_fixture()
      assert {:ok, %Settings{}} = ServiceSettings.delete_settings(settings)
      assert_raise Ecto.NoResultsError, fn -> ServiceSettings.get_settings!(settings.id) end
    end

    test "change_settings/1 returns a settings changeset" do
      settings = settings_fixture()
      assert %Ecto.Changeset{} = ServiceSettings.change_settings(settings)
    end
  end
end
