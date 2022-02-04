defmodule ExshomeWeb.Live.SettingsComponent do
  @moduledoc """
  A component to render form for settings.
  """

  use ExshomeWeb, :live_component
  alias Exshome.Settings
  alias Exshome.Settings.ClockSettings

  @impl Phoenix.LiveComponent
  def update(%{settings: settings}, socket) do
    socket = assign_new(socket, :changeset, fn -> Settings.changeset(settings) end)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"clock_settings" => clock_settings}, socket) do
    result =
      ClockSettings
      |> Settings.changeset(clock_settings)
      |> Ecto.Changeset.apply_action(:validate)

    changeset =
      case result do
        {:ok, settings} ->
          Settings.save_settings(settings)
          Settings.changeset(settings)

        {:error, invalid_changeset} ->
          invalid_changeset
      end

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("validate", %{"clock_settings" => clock_settings}, socket) do
    changeset = Settings.changeset(ClockSettings, clock_settings)
    {:noreply, assign(socket, changeset: changeset)}
  end
end
