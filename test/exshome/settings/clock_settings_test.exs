defmodule ExshomeTest.Settings.ClockSettingsTest do
  use Exshome.DataCase, async: true
  alias Exshome.Settings
  alias Exshome.Settings.ClockSettings

  test "we can not save settings with invalid timezone" do
    settings = Settings.get_settings(ClockSettings)

    assert {:error, changeset} =
             Settings.save_settings(%ClockSettings{settings | timezone: "nonexisting"})

    assert %{timezone: ["is invalid"]} = errors_on(changeset)
    default_timezone = ClockSettings.default_values().timezone
    assert %ClockSettings{timezone: ^default_timezone} = Settings.get_settings(ClockSettings)
  end

  test "reverts invalid timezone to a default value" do
    name = Settings.get_module_name(ClockSettings)

    assert %{timezone: "nonexisting"} =
             Settings.Schema.get_or_create(name, %{timezone: "nonexisting"})

    default_timezone = ClockSettings.default_values().timezone
    assert %ClockSettings{timezone: ^default_timezone} = Settings.get_settings(ClockSettings)
    assert %{"timezone" => ^default_timezone} = Settings.Schema.get_or_create(name, %{})
  end
end
