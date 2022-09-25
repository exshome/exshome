defmodule ExshomeWeb.Live.SettingsComponent do
  @moduledoc """
  A component to render form for settings.
  """

  use ExshomeWeb, :live_component
  alias Exshome.Settings

  @impl Phoenix.LiveComponent
  def update(%{settings: %module{} = settings}, socket) do
    socket =
      socket
      |> assign_new(:changeset, fn -> Settings.changeset(settings) end)
      |> assign_new(:module, fn -> module end)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def handle_event("save", %{"settings" => settings}, socket) do
    result =
      socket.assigns.module
      |> Settings.changeset(settings)
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

  def handle_event("validate", %{"settings" => settings}, socket) do
    changeset = Settings.changeset(socket.assigns.module, settings)
    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div class="flex flex-grow h-full items-center justify-center w-full md:w-3/4 lg:w-1/2 mx-auto">
      <.live_form
        changeset={@changeset}
        phx-target={@myself}
        as={:settings}
        fields={@module.fields()}
      />
    </div>
    """
  end
end
