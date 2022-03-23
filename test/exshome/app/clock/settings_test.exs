defmodule ExshomeTest.App.Clock.SettingsTest do
  use Exshome.DataCase, async: true
  alias Exshome.App.Clock
  alias Exshome.Settings

  test "we can not save settings with invalid timezone" do
    settings = Settings.get_settings(Clock.Settings)

    assert {:error, changeset} =
             Settings.save_settings(%Clock.Settings{settings | timezone: "nonexisting"})

    assert %{timezone: ["is invalid"]} = errors_on(changeset)
    default_timezone = Settings.default_values(Clock.Settings).timezone
    assert %Clock.Settings{timezone: ^default_timezone} = Settings.get_settings(Clock.Settings)
  end

  test "reverts invalid timezone to a default value" do
    name = Settings.get_module_name(Clock.Settings)

    assert %{timezone: "nonexisting"} =
             Settings.Schema.get_or_create(name, %{timezone: "nonexisting"})

    default_timezone = Settings.default_values(Clock.Settings).timezone
    assert %Clock.Settings{timezone: ^default_timezone} = Settings.get_settings(Clock.Settings)
    assert %{"timezone" => ^default_timezone} = Settings.Schema.get_or_create(name, %{})
  end
end
