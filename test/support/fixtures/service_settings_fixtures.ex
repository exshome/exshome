defmodule Exshome.ServiceSettingsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Exshome.ServiceSettings` context.
  """

  @doc """
  Generate a settings.
  """
  def settings_fixture(attrs \\ %{}) do
    {:ok, settings} =
      attrs
      |> Enum.into(%{
        settings: %{}
      })
      |> Exshome.ServiceSettings.create_settings()

    settings
  end
end
